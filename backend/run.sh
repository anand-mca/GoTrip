#!/bin/bash
# ============================================================================
# GoTrip Smart Travel Planning Backend - Startup Script (Mac/Linux)
# ============================================================================

clear

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║         GoTrip - Smart Travel Planning Backend                ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ ERROR: Python 3 is not installed"
    echo "Please install Python 3.8+ from https://www.python.org/"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
    if [ $? -ne 0 ]; then
        echo "❌ ERROR: Failed to create virtual environment"
        exit 1
    fi
    echo "✅ Virtual environment created"
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to activate virtual environment"
    exit 1
fi
echo "✅ Virtual environment activated"

# Check if dependencies are installed
pip show fastapi &> /dev/null
if [ $? -ne 0 ]; then
    echo "📚 Installing dependencies..."
    pip install -r requirements.txt
    if [ $? -ne 0 ]; then
        echo "❌ ERROR: Failed to install dependencies"
        exit 1
    fi
    echo "✅ Dependencies installed"
else
    echo "✅ Dependencies already installed"
fi

# Start the server
echo ""
echo "🚀 Starting GoTrip Backend Server..."
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Server will be available at: http://localhost:8000"
echo "  "
echo "  📖 API Documentation: http://localhost:8000/docs"
echo "  📘 ReDoc: http://localhost:8000/redoc"
echo "  ℹ️  API Info: http://localhost:8000/info"
echo "  "
echo "  Press Ctrl+C to stop the server"
echo "════════════════════════════════════════════════════════════════"
echo ""

python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
