#!/bin/bash

# Start Runtime Security test app
# This script starts the test application that integrates with Prisma AIRS Runtime Security

cd "$(dirname "$0")"

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "❌ Virtual environment not found. Please run setup.sh first."
    exit 1
fi

# Activate virtual environment
source .venv/bin/activate

# Check for required environment variables
if [ -z "$PANW_AI_SEC_API_KEY" ]; then
    echo "❌ ERROR: PANW_AI_SEC_API_KEY not set"
    echo ""
    echo "Please set your credentials:"
    echo "  export PANW_AI_SEC_API_KEY='your-api-key-here'"
    echo "  export PRISMA_AIRS_PROFILE='your-profile-name'"
    echo ""
    echo "Or create a .env file (see .env.example)"
    exit 1
fi

# Default profile if not set
export PRISMA_AIRS_PROFILE="${PRISMA_AIRS_PROFILE:-ai-sec-security}"

echo "============================================================"
echo "🔒 Starting Runtime Security Test App"
echo "============================================================"
echo "Security Profile: $PRISMA_AIRS_PROFILE"
echo "API Key: ${PANW_AI_SEC_API_KEY:0:10}..."
echo "============================================================"
echo ""
echo "Next steps:"
echo "1. In another terminal, run: ngrok http 5000"
echo "2. Copy the ngrok HTTPS URL"
echo "3. Add as Red Teaming target in SCM"
echo "============================================================"
echo ""

# Start the application
python runtime_test_app.py
