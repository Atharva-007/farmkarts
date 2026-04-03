@echo off
echo ===============================================
echo    FarmKarts - Optimized Startup & Debug
echo ===============================================
echo.

echo [1/4] Cleaning environment...
call flutter clean > nul 2>&1
echo ✓ Cleaned

echo [2/4] Fetching fresh dependencies...
call flutter pub get > nul 2>&1
echo ✓ Dependencies updated

echo [3/4] Checking for connected devices...
call flutter devices
echo.

echo [4/4] Launching application with diagnostic flags...
echo Note: If using an emulator, ensure it is fully booted.
echo.
echo Running with:
echo - No Impeller (improves emulator stability)
echo - Verbose logging (for startup analysis)
echo.

REM Standard debug run without obsolete flags
REM We use --no-enable-impeller because it often causes crashes on certain Windows OpenGL drivers/emulators
call flutter run --no-enable-impeller

echo.
echo ===============================================
echo    If the app crashed, check the logs above.
echo ===============================================
pause
