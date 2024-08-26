#!/bin/bash

# Start building the nginx.conf file
cat > /etc/nginx/nginx.conf <<EOL
worker_processes 1;
events {
    worker_connections 1024;
}
http {
EOL

# Loop over all environment variables starting with 'LISTEN_'
for var in $(printenv | grep -Eo '^LISTEN_[0-9]+' | sort -u); do
    port="${var#LISTEN_}"
    upstreams=$(printenv "$var")

    # Parse and create upstream and server blocks for each port
    IFS=',' read -ra UPSTREAMS <<< "$upstreams"
    for upstream in "${UPSTREAMS[@]}"; do
        IFS=':' read upstream_host upstream_port <<< "$upstream"
        echo "    upstream upstream_${port}_${upstream_host}_${upstream_port} { server ${upstream_host}:${upstream_port}; }" >> /etc/nginx/nginx.conf
    done

    # Add a server block for this port
    cat >> /etc/nginx/nginx.conf <<EOL
    server {
        listen ${port};
        location / {
            proxy_pass http://upstream_${port}_${upstream_host}_${upstream_port};
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
EOL
done

# Close the http block
echo "}" >> /etc/nginx/nginx.conf

# Start nginx
nginx -g 'daemon off;'
