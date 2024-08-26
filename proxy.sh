#!/bin/bash

# Start building the nginx.conf file
cat > /etc/nginx/nginx.conf <<EOL
worker_processes 1;
events {
    worker_connections 1024;
}
http {
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
EOL

# Print environment variables for debugging
echo "Available environment variables:"
printenv

# Loop over all environment variables starting with 'LISTEN_'
for var in $(printenv | grep -Eo '^LISTEN_[0-9]+(_WSS)?'); do
    # Extract port number and suffix
    if [[ "$var" =~ LISTEN_([0-9]+)(_[A-Z]+)? ]]; then
        port="${BASH_REMATCH[1]}"
        suffix="${BASH_REMATCH[2]}"
    else
        echo "Unable to extract port from ${var}, skipping..."
        continue
    fi

    upstreams=$(printenv "$var")

    # Debugging output
    echo "Processing port: ${port}"
    echo "Upstreams: ${upstreams}"

    # Determine if WebSocket configuration should be added
    if [[ "$suffix" == "_WSS" ]]; then
        echo "WebSocket configuration detected for port ${port}"
        ws_config="
            # To support websockets
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection \"upgrade\";
        "
        # Set upstream_block_name to a dummy value to avoid using it in WebSocket configurations
        upstream_block_name=""
    else
        # Handle non-WebSocket ports
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
    fi

    # Add a server block for this port
    cat >> /etc/nginx/nginx.conf <<EOL
    server {
        listen ${port};
        location / {
            ${upstream_block_name:+proxy_pass http://${upstream_block_name};}
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;

            $ws_config
        }

        # Ensure root directive is correctly configured if needed
        # root /etc/nginx/html;
    }
EOL
done

# Close the http block
echo "}" >> /etc/nginx/nginx.conf

# Print the generated configuration for debugging
echo "Generated nginx.conf:"
cat /etc/nginx/nginx.conf

# Test Nginx configuration
nginx -t

# Start nginx
nginx -g 'daemon off;'
