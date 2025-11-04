#!/bin/bash
# Quick start script for Docker-based red teaming setup

set -e

echo "🐳 Prisma AIRS Red Teaming - Docker Quick Start"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

echo "✅ Docker is running"

# Check if .env file exists
if [ ! -f .env ]; then
    echo ""
    echo "⚠️  No .env file found. Creating from template..."
    cp .env.example .env
    echo ""
    echo "📝 Please edit .env file with your actual credentials:"
    echo "   - PANW_AI_SEC_API_KEY"
    echo "   - NGROK_AUTHTOKEN"
    echo "   - OPENAI_API_KEY (optional)"
    echo ""
    echo "Then run this script again."
    exit 0
fi

echo "✅ .env file found"

# Check if required variables are set
source .env

if [ -z "$PANW_AI_SEC_API_KEY" ] || [ "$PANW_AI_SEC_API_KEY" = "your-api-key-here" ]; then
    echo "❌ PANW_AI_SEC_API_KEY not configured in .env"
    exit 1
fi

if [ -z "$NGROK_AUTHTOKEN" ] || [ "$NGROK_AUTHTOKEN" = "your-ngrok-authtoken-here" ]; then
    echo "❌ NGROK_AUTHTOKEN not configured in .env"
    exit 1
fi

echo "✅ Environment variables configured"
echo ""

# Check if container is already running
if docker-compose ps | grep -q "Up"; then
    echo "⚠️  Container is already running."
    echo ""
    read -p "Do you want to restart it? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔄 Restarting container..."
        docker-compose restart
    fi
else
    echo "🚀 Starting container..."
    echo ""
    docker-compose up --build
fi
