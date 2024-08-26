#!/bin/bash

# Read the PROXY environment variable
PROXY=${PROXY:?Need to set PROXY environment variable. Format: PROXY=- listen: port1 upstream: host1:port1, ...}

# Start building the nginx.conf file
cat > /etc/nginx/nginx.conf <<EOL
worker_processes 1;
events {
    worker_connections 1024;
}
http {
EOL

# Parse the PROXY variable and create server and upstream blocks
echo "$PROXY" | awk '
/^- listen:/ { listen_port = $2 }
/^  upstream:/ { upstream_host_port = substr($0, index($0, ":") + 1) }
END {
    split(upstream_host_port, arr, ":")
    upstream_host = arr[1]
    upstream_port = arr[2]

    print "    upstream upstream_" upstream_port " { server " upstream_host ":" upstream_port "; }" >> "/etc/nginx/nginx.conf"
    print "    server { listen " listen_port "; location / { proxy_pass http://upstream_" upstream_port "; proxy_set_header Host \$host; proxy_set_header X-Real-IP \$remote_addr; proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for; proxy_set_header X-Forwarded-Proto \$scheme; } }" >> "/etc/nginx/nginx.conf"
}
'

# Close the http block
echo "}" >> /etc/nginx/nginx.conf

# Start nginx
nginx -g 'daemon off;'
