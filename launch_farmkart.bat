@echo off
echo 🚀 Starting FarmKart Application...
echo.

echo 🔧 Cleaning Flutter cache...
flutter clean > nul 2>&1

echo 📦 Getting dependencies...
flutter pub get

echo 🌐 Launching app on Chrome...
echo ✅ App will open in your default browser
echo 🔄 Press Ctrl+C to stop the app
echo.
flutter run -d chrome --web-port=8080

pause
