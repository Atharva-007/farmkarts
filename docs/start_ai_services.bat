@echo off
echo ========================================
echo Starting FarmKart AI Services
echo ========================================

echo.
echo Step 1: Checking Ollama service...
curl -s http://localhost:11434 >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Ollama is running on http://localhost:11434
) else (
    echo ⚠️  Ollama is not running. Please start Ollama first with 'ollama start'
    pause
    exit /b 1
)

echo.
echo Step 2: Deploying Firebase security rules...
call firebase deploy --only firestore:rules
if %errorlevel% neq 0 (
    echo ❌ Failed to deploy Firebase rules
    echo Please make sure you're logged in with 'firebase login'
    pause
    exit /b 1
)
echo ✅ Firebase security rules deployed

echo.
echo Step 3: Starting FarmKart Backend Server (with AI endpoints)...
cd farmkart-backend
start "FarmKart Backend" cmd /k "node index.js"
cd ..

timeout /t 3 >nul

echo.
echo Step 4: Checking if backend started successfully...
curl -s http://localhost:3000/ai/health >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Backend server running on http://localhost:3000
) else (
    echo ⚠️  Backend server starting... (this may take a moment)
)

echo.
echo ========================================
echo 🚀 FarmKart AI Services Status
echo ========================================
echo Ollama AI: http://localhost:11434
echo Backend API: http://localhost:3000
echo AI Health: http://localhost:3000/ai/health
echo ========================================
echo.
echo Your FarmKart AI Expert Chat is now ready!
echo You can now use the AI chat feature in your app.
echo.
echo Press any key to close this window...
pause >nul