#!/bin/bash

# Setup script for Prisma AIRS Red Teaming + Runtime Security test environment

cd "$(dirname "$0")"

echo "============================================================"
echo "🔧 Prisma AIRS Red Teaming Test Setup"
echo "============================================================"
echo ""

# Check Python version
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1-2)
echo "✅ Found Python $PYTHON_VERSION"

# Create virtual environment
if [ ! -d ".venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv .venv
else
    echo "✅ Virtual environment already exists"
fi

# Activate virtual environment
source .venv/bin/activate

# Upgrade pip
echo "📦 Upgrading pip..."
pip install --upgrade pip > /dev/null 2>&1

# Install dependencies
echo "📦 Installing dependencies..."
pip install -r requirements.txt

echo ""
echo "============================================================"
echo "✅ Setup Complete!"
echo "============================================================"
echo ""
echo "Next steps:"
echo ""
echo "1. Set your credentials:"
echo "   export PANW_AI_SEC_API_KEY='your-api-key-here'"
echo "   export PRISMA_AIRS_PROFILE='your-profile-name'"
echo ""
echo "   Or copy .env.example to .env and fill in your credentials"
echo ""
echo "2. Start the test application:"
echo "   ./start_test_app.sh"
echo ""
echo "3. In another terminal, start ngrok:"
echo "   ngrok http 5000"
echo ""
echo "4. Add the ngrok URL as a Red Teaming target in SCM"
echo ""
echo "See README.md for detailed instructions"
echo "============================================================"
