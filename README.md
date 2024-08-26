# dynamic-ngnix

Dynamic ngnix reverse proxy, requires zero explicit configuration.

# How to use?

```
environment:
    - LISTEN_9000_UPSTREAMS=server1:9000,server2:9000,server3:9000,server4:9000
    - LISTEN_9001_UPSTREAMS=server1:9001,server2:9001,server3:9001,server4:9001
```

# Docker Compose

```
version: '3.8'

services:
  # Internal load balancing using a simple nginx service
  nginx:
    image: devstroop/dynamic-nginx:latest
    # Example proxy configuration
    environment:
      - LISTEN_9000_UPSTREAMS=server1:9000,server2:9000,server3:9000,server4:9000
      - LISTEN_9001_UPSTREAMS=server1:9001,server2:9001,server3:9001,server4:9001
```
