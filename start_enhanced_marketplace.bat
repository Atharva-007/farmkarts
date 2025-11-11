@echo off
echo ================================
echo  FarmKart Enhanced Marketplace
echo ================================
echo.
echo Starting Enhanced Marketplace Backend...

cd farmkart-backend
start "Enhanced Backend" node enhanced-marketplace-server.js

timeout /t 3 /nobreak > nul

echo.
echo Starting Flutter Web App...
flutter run -d chrome --debug

echo.
echo ================================
echo  Enhanced Marketplace Started!
echo ================================
echo.
echo Backend: http://localhost:3002
echo Frontend: Available in Chrome
echo.
pause