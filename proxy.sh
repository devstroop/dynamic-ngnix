#!/bin/bash

# Read the PROXY environment variable
PROXY=${PROXY:?Need to set PROXY environment variable. Format: PROXY=upstream_host1:upstream_port1:listen_port1,upstream_host2:upstream_port2:listen_port2}

# Start building the nginx.conf file
cat > /etc/nginx/nginx.conf <<EOL
worker_processes 1;
events {
    worker_connections 1024;
}
http {
EOL

# Parse the PROXY variable and create server and upstream blocks
IFS=',' read -ra PROXY_PAIRS <<< "$PROXY"
for pair in "${PROXY_PAIRS[@]}"; do
    IFS=':-' read upstream_host upstream_port listen_port <<< "$pair"
    
    # Create upstream block
    upstream_name="upstream_${upstream_port}"
    echo "    upstream $upstream_name { server $upstream_host:$upstream_port; }" >> /etc/nginx/nginx.conf
    
    # Create server block
    cat >> /etc/nginx/nginx.conf <<EOL
    server {
        listen $listen_port;
        location / {
            proxy_pass http://$upstream_name;
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
nginx -g 'daemon
