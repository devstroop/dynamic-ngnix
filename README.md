# dynamic-ngnix

Dynamic ngnix reverse proxy, requires zero explicit configuration.

# How to use?

```
    # Example proxy configuration
    environment: |
      - listen: 9000
        upstream: server1:9000
      - listen: 9000
        upstream: server2:9000
      - listen: 9000
        upstream: server3:9000
      - listen: 9000
        upstream: server4:9000
```

# Docker Compose

```
---
version: '3.8'

services:
  nginx:
    image: devstroop/dynamic-nginx:latest
    # Example proxy configuration
    environment: |
      - listen: 9000
        upstream: server1:9000
      - listen: 9000
        upstream: server2:9000
      - listen: 9000
        upstream: server3:9000
      - listen: 9000
        upstream: server4:9000
  
---
```
