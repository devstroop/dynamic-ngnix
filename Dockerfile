# Start with the official Nginx image
FROM nginx:latest

# Install necessary tools for the script
RUN apt-get update && apt-get install -y bash awk

# Copy the bash script into the container
COPY proxy.sh /usr/local/bin/proxy.sh

# Make the script executable
RUN chmod +x /usr/local/bin/proxy.sh

# Set the entrypoint to run the script and then start Nginx
ENTRYPOINT ["/bin/bash", "-c", "/usr/local/bin/proxy.sh && nginx -g 'daemon off;'"]