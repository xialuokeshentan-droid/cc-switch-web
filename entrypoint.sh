#!/bin/bash

# Create config directory
mkdir -p /home/ccswitch/.cc-switch

# Set password from environment variable or use default
if [ -n "$WEB_PASSWORD" ]; then
    echo "$WEB_PASSWORD" > /home/ccswitch/.cc-switch/web_password
    chmod 600 /home/ccswitch/.cc-switch/web_password
    echo "Password set from environment variable"
fi

# Start server in background
cc-switch-server &
SERVER_PID=$!

# Wait for server to start
sleep 5

# Update DeepSeek provider with API key from environment variable
if [ -n "$DEEPSEEK_API_KEY" ]; then
    echo "Updating DeepSeek provider with API key from environment..."
    
    # Get CSRF token
    CSRF_TOKEN=$(curl -s -u "admin:${WEB_PASSWORD:-qwertyuiop}" "http://localhost:3000/api/system/csrf-token" | grep -o '"csrfToken":"[^"]*"' | cut -d'"' -f4)
    
    # Update DeepSeek provider
    curl -s -X PUT "http://localhost:3000/api/providers/claude/deepseek" \
      -u "admin:${WEB_PASSWORD:-qwertyuiop}" \
      -H "Content-Type: application/json" \
      -H "X-CSRF-Token: $CSRF_TOKEN" \
      -d "{
        \"id\": \"deepseek\",
        \"name\": \"DeepSeek\",
        \"settingsConfig\": {
          \"auth\": {
            \"apiKey\": \"$DEEPSEEK_API_KEY\",
            \"baseUrl\": \"https://api.deepseek.com\"
          },
          \"config\": \"\"
        },
        \"notes\": \"DeepSeek API provider from environment\"
      }"
    
    echo ""
    echo "DeepSeek provider updated with API key from environment"
fi

# Wait for server process
wait $SERVER_PID
