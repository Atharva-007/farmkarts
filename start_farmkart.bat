@echo off
echo ===============================================
echo        Starting FarmKarts Application
echo ===============================================
echo.

echo [1/3] Starting Backend Server...
echo.
start "FarmKart Backend" cmd /k "cd farmkart-backend && echo Starting FarmKart Backend Server... && npm start"

echo [2/3] Waiting for backend to initialize...
timeout /t 5 /nobreak > nul

echo [3/3] Starting Flutter Web App...
echo.
start "FarmKart Frontend" cmd /k "echo Starting FarmKart Web Application... && flutter run -d chrome --web-hostname localhost --web-port 8080"

echo.
echo ===============================================
echo        FarmKarts Application Starting!
echo ===============================================
echo.
echo Backend API:    http://localhost:3000
echo Frontend App:   http://localhost:8080
echo Health Check:   http://localhost:3000/api/health
echo.
echo Both applications are launching...
echo Close this window only after both applications are running.
echo.
echo Press any key to exit...
pause > nul