# dynamic-nginx

Dynamic Nginx reverse proxy, requires zero explicit configuration.

## How to use?

Define the upstreams using environment variables in the following format:

```yaml
environment:
    - LISTEN_9000=server1:9000,server2:9000,server3:9000,server4:9000
    - LISTEN_9001=server1:9001,server2:9001,server3:9001,server4:9001
    # Add more LISTEN_<port> variables as needed
```

# Docker Compose

```yaml
version: '3.8'

services:
  # Internal load balancing using a simple nginx service
  nginx:
    image: devstroop/dynamic-nginx:latest
    restart: unless-stopped
    environment:
      - LISTEN_9000=server1:9000,server2:9000,server3:9000,server4:9000
      - LISTEN_9001=server1:9001,server2:9001,server3:9001,server4:9001
      # Add more LISTEN_<port> variables as needed
```
