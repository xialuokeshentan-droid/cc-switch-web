#!/bin/bash
set -e

mkdir -p /home/ccswitch/.cc-switch

# Password
WEB_PASSWORD="${WEB_PASSWORD:-qwertyuiop}"
echo "$WEB_PASSWORD" > /home/ccswitch/.cc-switch/web_password
chmod 600 /home/ccswitch/.cc-switch/web_password

# Start server
cc-switch-server &
SERVER_PID=$!

# Wait for server to be ready (max 60s)
echo "Waiting for server to start..."
for i in $(seq 1 30); do
    if curl -s -u "admin:$WEB_PASSWORD" "http://localhost:3000/api/system/csrf-token" > /dev/null 2>&1; then
        echo "Server is ready after ${i}s"
        break
    fi
    sleep 2
done

# Configure DeepSeek provider from DEEPSEEK_API_KEY env
if [ -n "$DEEPSEEK_API_KEY" ]; then
    echo "Configuring DeepSeek provider from DEEPSEEK_API_KEY..."
    
    CSRF_TOKEN=$(curl -s -u "admin:$WEB_PASSWORD" "http://localhost:3000/api/system/csrf-token" | grep -o '"csrfToken":"[^"]*"' | cut -d'"' -f4)
    echo "CSRF Token: $CSRF_TOKEN"
    
    # Delete old provider first (ignore error if not exists)
    curl -s -X DELETE "http://localhost:3000/api/providers/claude/deepseek" \
      -u "admin:$WEB_PASSWORD" \
      -H "X-CSRF-Token: $CSRF_TOKEN" > /dev/null 2>&1 || true
    
    # Add provider with real API key
    echo "Adding DeepSeek provider..."
    ADD_RESULT=$(curl -s -X POST "http://localhost:3000/api/providers/claude" \
      -u "admin:$WEB_PASSWORD" \
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
        }
      }")
    echo "Add result: $ADD_RESULT"
    
    # Switch to DeepSeek
    echo "Switching to DeepSeek..."
    SWITCH_RESULT=$(curl -s -X POST "http://localhost:3000/api/providers/claude/deepseek/switch" \
      -u "admin:$WEB_PASSWORD" \
      -H "Content-Type: application/json" \
      -H "X-CSRF-Token: $CSRF_TOKEN")
    echo "Switch result: $SWITCH_RESULT"
else
    echo "WARNING: DEEPSEEK_API_KEY not set, skipping provider configuration"
fi

echo "Server startup complete, process PID: $SERVER_PID"
wait $SERVER_PID
