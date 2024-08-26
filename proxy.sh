#!/bin/bash

# Read the LISTEN and UPSTREAM environment variables
LISTEN_9000_UPSTREAMS=${LISTEN_9000_UPSTREAMS:?Need to set LISTEN_9000_UPSTREAMS environment variable. Format: upstream_host1:upstream_port1,upstream_host2:upstream_port2,...}
LISTEN_9001_UPSTREAMS=${LISTEN_9001_UPSTREAMS:?Need to set LISTEN_9001_UPSTREAMS environment variable. Format: upstream_host1:upstream_port1,upstream_host2:upstream_port2,...}

# Start building the nginx.conf file
cat > /etc/nginx/nginx.conf <<EOL
worker_processes 1;
events {
    worker_connections 1024;
}
http {
EOL

# Parse and create upstream and server blocks for port 9000
IFS=',' read -ra UPSTREAMS_9000 <<< "$LISTEN_9000_UPSTREAMS"
for upstream in "${UPSTREAMS_9000[@]}"; do
    IFS=':' read upstream_host upstream_port <<< "$upstream"
    echo "    upstream upstream_${upstream_port} { server ${upstream_host}:${upstream_port}; }" >> /etc/nginx/nginx.conf
    cat >> /etc/nginx/nginx.conf <<EOL
    server {
        listen 9000;
        location / {
            proxy_pass http://upstream_${upstream_port};
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
EOL
done

# Parse and create upstream and server blocks for port 9001
IFS=',' read -ra UPSTREAMS_9001 <<< "$LISTEN_9001_UPSTREAMS"
for upstream in "${UPSTREAMS_9001[@]}"; do
    IFS=':' read upstream_host upstream_port <<< "$upstream"
    echo "    upstream upstream_${upstream_port} { server ${upstream_host}:${upstream_port}; }" >> /etc/nginx/nginx.conf
    cat >> /etc/nginx/nginx.conf <<EOL
    server {
        listen 9001;
        location / {
            proxy_pass http://upstream_${upstream_port};
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
