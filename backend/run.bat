@echo off
REM ============================================================================
REM GoTrip Smart Travel Planning Backend - Startup Script (Windows)
REM ============================================================================

echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                                                                ║
echo ║         GoTrip - Smart Travel Planning Backend                ║
echo ║                                                                ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ ERROR: Python is not installed or not in PATH
    echo Please install Python 3.8+ from https://www.python.org/
    pause
    exit /b 1
)

REM Check if virtual environment exists
if not exist "venv" (
    echo 📦 Creating virtual environment...
    python -m venv venv
    if errorlevel 1 (
        echo ❌ ERROR: Failed to create virtual environment
        pause
        exit /b 1
    )
    echo ✅ Virtual environment created
)

REM Activate virtual environment
echo 🔧 Activating virtual environment...
call venv\Scripts\activate.bat
if errorlevel 1 (
    echo ❌ ERROR: Failed to activate virtual environment
    pause
    exit /b 1
)
echo ✅ Virtual environment activated

REM Check if dependencies are installed
pip show fastapi >nul 2>&1
if errorlevel 1 (
    echo 📚 Installing dependencies...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo ❌ ERROR: Failed to install dependencies
        pause
        exit /b 1
    )
    echo ✅ Dependencies installed
) else (
    echo ✅ Dependencies already installed
)

REM Start the server
echo.
echo 🚀 Starting GoTrip Backend Server...
echo.
echo ════════════════════════════════════════════════════════════════
echo  Server will be available at: http://localhost:8000
echo  
echo  📖 API Documentation: http://localhost:8000/docs
echo  📘 ReDoc: http://localhost:8000/redoc
echo  ℹ️  API Info: http://localhost:8000/info
echo  
echo  Press Ctrl+C to stop the server
echo ════════════════════════════════════════════════════════════════
echo.

python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

pause
