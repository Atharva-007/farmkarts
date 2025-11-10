@echo off
echo ===============================================
echo FarmKart AI Services Startup Script
echo ===============================================

:: Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH!
    echo Please install Python 3.8+ and try again.
    pause
    exit /b 1
)

:: Check if Node.js is installed
node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js is not installed or not in PATH!
    echo Please install Node.js 16+ and try again.
    pause
    exit /b 1
)

:: Load environment variables
if exist .env (
    echo Loading environment variables from .env...
    for /f "usebackq tokens=1,2 delims==" %%a in (`.env`) do (
        set "%%a=%%b"
    )
) else (
    echo WARNING: .env file not found. Using default values.
)

echo.
echo Starting FarmKart AI Services...
echo.

:: Start AI Service in background
echo Starting AI Service (Python FastAPI)...
cd ai_service
start "FarmKart AI Service" cmd /k "python -m uvicorn app:app --host 0.0.0.0 --port 8000 --reload"
cd ..

:: Wait a bit for AI service to start
timeout /t 5 /nobreak >nul

:: Start Node Proxy
echo Starting Node Proxy Service...
cd node_proxy
start "FarmKart Node Proxy" cmd /k "node aiproxy.js"
cd ..

echo.
echo ===============================================
echo Services started successfully!
echo.
echo AI Service:    http://localhost:8000
echo Node Proxy:    http://localhost:3000
echo Health Check:  http://localhost:3000/health
echo.
echo Press any key to continue...
echo ===============================================
pause