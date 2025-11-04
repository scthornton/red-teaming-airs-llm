#!/bin/bash
set -e

echo "========================================"
echo "Prisma AIRS Docker (No ngrok)"
echo "========================================"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found"
    echo ""
    echo "Create .env file with:"
    echo "  cp .env.example .env"
    echo ""
    echo "Then edit .env with your credentials:"
    echo "  - PANW_AI_SEC_API_KEY"
    echo "  - PRISMA_AIRS_PROFILE"
    echo ""
    exit 1
fi

# Load environment variables
source .env

# Check required variables
if [ -z "$PANW_AI_SEC_API_KEY" ]; then
    echo "❌ Error: PANW_AI_SEC_API_KEY not set in .env"
    exit 1
fi

if [ -z "$PRISMA_AIRS_PROFILE" ]; then
    echo "❌ Error: PRISMA_AIRS_PROFILE not set in .env"
    exit 1
fi

echo "✅ Configuration loaded"
echo "   Profile: $PRISMA_AIRS_PROFILE"
echo "   API Key: ${PANW_AI_SEC_API_KEY:0:10}..."
echo ""

# Stop any existing containers
echo "🛑 Stopping existing containers..."
docker-compose -f docker-compose.simple.yml down 2>/dev/null || true
echo ""

# Build and start
echo "🔨 Building Docker image..."
docker-compose -f docker-compose.simple.yml build
echo ""

echo "🚀 Starting container..."
docker-compose -f docker-compose.simple.yml up -d
echo ""

# Wait for health check
echo "⏳ Waiting for app to be ready..."
sleep 3

# Check health
if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "✅ App is running!"
    echo ""
    echo "========================================"
    echo "📋 App Details"
    echo "========================================"
    echo ""
    echo "Local URL:  http://localhost:5000"
    echo "Health:     http://localhost:5000/health"
    echo ""
    echo "⚠️  Note: This is only accessible locally"
    echo ""
    echo "For Red Teaming access, you need ONE of:"
    echo "  1. Use ngrok: docker-compose up (with original setup)"
    echo "  2. Deploy to GCP VM: See GCP_VM_DEPLOYMENT.md"
    echo "  3. Deploy to Cloud Run: See CLOUDRUN_QUICKSTART.md"
    echo ""
    echo "========================================"
    echo "📊 Monitor Logs"
    echo "========================================"
    echo ""
    echo "docker-compose -f docker-compose.simple.yml logs -f"
    echo ""
else
    echo "❌ Health check failed"
    echo ""
    echo "Check logs with:"
    echo "  docker-compose -f docker-compose.simple.yml logs"
    exit 1
fi
