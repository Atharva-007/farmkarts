@echo off
echo ========================================
echo Testing FarmKart AI Setup
echo ========================================

echo.
echo 1. Testing Ollama Connection...
curl -X POST http://localhost:11434/api/generate -H "Content-Type: application/json" -d "{\"model\":\"gemma2:2b\",\"prompt\":\"Hello, are you working?\",\"stream\":false}" --connect-timeout 10
if %errorlevel% equ 0 (
    echo ✅ Ollama connection successful
) else (
    echo ❌ Ollama connection failed
)

echo.
echo 2. Testing Backend AI Endpoint...
curl -X POST http://localhost:3000/ai/advice -H "Content-Type: application/json" -d "{\"query\":\"What's the best time to plant wheat?\"}" --connect-timeout 10
if %errorlevel% equ 0 (
    echo ✅ Backend AI endpoint working
) else (
    echo ❌ Backend AI endpoint failed
)

echo.
echo 3. Testing Backend Health...
curl http://localhost:3000/ai/health --connect-timeout 5
if %errorlevel% equ 0 (
    echo ✅ Backend health check passed
) else (
    echo ❌ Backend health check failed
)

echo.
echo 4. Checking Required Processes...
tasklist /FI "IMAGENAME eq ollama.exe" 2>NUL | find /I /N "ollama.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo ✅ Ollama process is running
) else (
    echo ❌ Ollama process not found
)

tasklist /FI "IMAGENAME eq node.exe" 2>NUL | find /I /N "node.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo ✅ Node.js process is running
) else (
    echo ❌ Node.js process not found
)

echo.
echo ========================================
echo Test Complete
echo ========================================
echo.
pause