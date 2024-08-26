#!/bin/bash

# Start building the nginx.conf file
cat > /etc/nginx/nginx.conf <<EOL
worker_processes 1;
events {
    worker_connections 1024;
}
http {
EOL

# Initialize an array to store upstream names
declare -A upstream_names

# Loop over all environment variables starting with 'LISTEN_'
for var in $(printenv | grep -Eo '^LISTEN_[0-9]+' | sort -u); do
    port="${var#LISTEN_}"
    upstreams=$(printenv "$var")

    if [ -z "$upstreams" ]; then
        echo "No upstreams defined for port ${port}, skipping..."
        continue
    fi

    # Parse and create upstream and server blocks for each port
    IFS=',' read -ra UPSTREAMS <<< "$upstreams"
    upstream_block_name="upstream_${port}"

    # Define upstream block
    echo "    upstream ${upstream_block_name} {" >> /etc/nginx/nginx.conf
    for upstream in "${UPSTREAMS[@]}"; do
        IFS=':' read -r upstream_host upstream_port <<< "$upstream"
        if [[ -z "$upstream_host" || -z "$upstream_port" ]]; then
            echo "Invalid upstream format: ${upstream}, skipping..."
            continue
        fi
        echo "        server ${upstream_host}:${upstream_port};" >> /etc/nginx/nginx.conf
    done
    echo "    }" >> /etc/nginx/nginx.conf

    # Add a server block for this port
    cat >> /etc/nginx/nginx.conf <<EOL
    server {
        listen ${port};
        location / {
            proxy_pass http://${upstream_block_name};
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            
            # To support websockets
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
EOL
done

# Close the http block
echo "}" >> /etc/nginx/nginx.conf

# Start nginx
nginx -g 'daemon off;'
