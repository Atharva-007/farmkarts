@echo off
echo ===============================================
echo FarmKart AI Setup Script
echo ===============================================

:: Check prerequisites
echo Checking prerequisites...
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH!
    echo Please install Python 3.8+ and try again.
    pause
    exit /b 1
)

node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js is not installed or not in PATH!
    echo Please install Node.js 16+ and try again.
    pause
    exit /b 1
)

echo Python and Node.js found!

:: Setup Python environment
echo.
echo Setting up Python environment...
cd ai_service

echo Installing Python dependencies...
pip install -r requirements.txt
if errorlevel 1 (
    echo ERROR: Failed to install Python dependencies!
    pause
    exit /b 1
)

cd ..

:: Setup Node.js environment
echo.
echo Setting up Node.js environment...
cd node_proxy

echo Installing Node.js dependencies...
npm install
if errorlevel 1 (
    echo ERROR: Failed to install Node.js dependencies!
    pause
    exit /b 1
)

cd ..

:: Build initial index
echo.
echo Building initial knowledge base index...
python build_index.py
if errorlevel 1 (
    echo WARNING: Failed to build index. You can build it later manually.
)

:: Create secrets directory
echo.
echo Creating secrets directory...
if not exist "secrets" mkdir secrets

echo.
echo ===============================================
echo Setup completed successfully!
echo.
echo Next steps:
echo 1. Copy your Firebase service account JSON to secrets/firebase-admin.json
echo 2. Review and update .env file with your configuration
echo 3. Run start_services.bat to start the services
echo.
echo Files created:
echo - AI Service ready at ai_service/
echo - Node Proxy ready at node_proxy/
echo - Configuration at .env
echo - Secrets directory at secrets/
echo.
echo Press any key to continue...
echo ===============================================
pause