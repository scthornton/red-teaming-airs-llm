#!/bin/bash
set -e

echo "============================================================"
echo "🐳 Starting Prisma AIRS Red Teaming Test Environment"
echo "============================================================"

# Check required environment variables
if [ -z "$NGROK_AUTHTOKEN" ]; then
    echo "❌ ERROR: NGROK_AUTHTOKEN not set"
    echo "   Get your token from: https://dashboard.ngrok.com/get-started/your-authtoken"
    exit 1
fi

if [ -z "$PANW_AI_SEC_API_KEY" ]; then
    echo "❌ ERROR: PANW_AI_SEC_API_KEY not set"
    echo "   Get your API key from Strata Cloud Manager"
    exit 1
fi

# Configure ngrok
echo "🔧 Configuring ngrok..."
ngrok config add-authtoken $NGROK_AUTHTOKEN

# Start Flask app in background
echo "🚀 Starting Flask application..."
python runtime_test_app_direct_api.py &
APP_PID=$!

# Wait for Flask to be ready
echo "⏳ Waiting for Flask to start..."
for i in {1..30}; do
    if curl -s http://localhost:5000/health > /dev/null 2>&1; then
        echo "✅ Flask app is healthy"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Flask failed to start within 30 seconds"
        kill $APP_PID 2>/dev/null || true
        exit 1
    fi
    sleep 1
done

# Start ngrok (this stays in foreground)
echo "🌐 Starting ngrok tunnel..."
echo ""
echo "📋 Access ngrok web interface at: http://localhost:4040"
echo "📋 Your public URL will appear below..."
echo ""
exec ngrok http 5000 --log=stdout
