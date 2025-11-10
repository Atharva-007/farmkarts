@echo off
echo.
echo ========================================
echo  🌾 FarmKart Marketplace Setup 🚀
echo ========================================
echo.

echo 📋 Checking prerequisites...
echo.

:: Check if Node.js is installed
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Node.js is not installed. Please install Node.js first.
    pause
    exit /b 1
) else (
    echo ✅ Node.js is installed
)

:: Check if Flutter is installed  
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter is not installed. Please install Flutter first.
    pause
    exit /b 1
) else (
    echo ✅ Flutter is installed
)

echo.
echo 🔧 Installing backend dependencies...
cd farmkart-backend
call npm install
if errorlevel 1 (
    echo ❌ Failed to install backend dependencies
    pause
    exit /b 1
)
echo ✅ Backend dependencies installed

echo.
echo 📱 Installing Flutter dependencies...
cd ..
call flutter pub get
if errorlevel 1 (
    echo ❌ Failed to install Flutter dependencies  
    pause
    exit /b 1
)
echo ✅ Flutter dependencies installed

echo.
echo 🚀 Starting backend server...
cd farmkart-backend
start "FarmKart Backend" cmd /k "npm start"

echo.
echo ⏳ Waiting for backend to start...
timeout /t 5 /nobreak >nul

echo.
echo 🏥 Testing backend health...
curl -s http://localhost:3000/api/health >nul
if errorlevel 1 (
    echo ❌ Backend server is not responding
    echo 💡 Check if port 3000 is available
    pause
    exit /b 1
) else (
    echo ✅ Backend server is running at http://localhost:3000
)

echo.
echo ========================================
echo  🎉 Setup Complete! 
echo ========================================
echo.
echo ✅ Backend Server: http://localhost:3000
echo ✅ API Health: http://localhost:3000/api/health
echo ✅ Flutter App: Ready to run
echo.
echo 🚀 Next Steps:
echo   1. Run 'flutter run' to start the app
echo   2. Configure Firebase (google-services.json)
echo   3. Add payment gateway keys in .env
echo   4. Start building your marketplace!
echo.
echo 📚 Documentation:
echo   - QUICK_START_GUIDE.md
echo   - MARKETPLACE_IMPLEMENTATION_COMPLETE.md
echo.
pause