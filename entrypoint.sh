#!/bin/bash

# Create config directory
mkdir -p /home/ccswitch/.cc-switch

# Set password from environment variable or use default
if [ -n "$WEB_PASSWORD" ]; then
    echo "$WEB_PASSWORD" > /home/ccswitch/.cc-switch/web_password
    chmod 600 /home/ccswitch/.cc-switch/web_password
    echo "Password set from environment variable"
fi

# Start server
exec cc-switch-server
