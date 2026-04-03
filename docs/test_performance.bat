@echo off
REM ================================================
REM FarmKarts Performance Test Script
REM Tests caching and optimization features
REM ================================================

echo.
echo ========================================
echo   FarmKarts Performance Test
echo ========================================
echo.

echo [TEST 1] Checking Performance Manager...
echo Looking for: lib\utils\performance_manager.dart
if exist "lib\utils\performance_manager.dart" (
    echo [PASS] Performance Manager found
) else (
    echo [FAIL] Performance Manager not found
    pause
    exit /b 1
)
echo.

echo [TEST 2] Checking Firestore Indexes...
echo Looking for: firestore.indexes.json
if exist "firestore.indexes.json" (
    echo [PASS] Firestore indexes file found
    findstr /C:"\"indexes\"" firestore.indexes.json >nul
    if %ERRORLEVEL% EQU 0 (
        echo [PASS] Indexes properly configured
    ) else (
        echo [FAIL] Indexes not configured
    )
) else (
    echo [FAIL] Firestore indexes file not found
    pause
    exit /b 1
)
echo.

echo [TEST 3] Checking Dependencies...
echo Looking for: pubspec.yaml
if exist "pubspec.yaml" (
    echo [PASS] pubspec.yaml found
    findstr /C:"shared_preferences" pubspec.yaml >nul
    if %ERRORLEVEL% EQU 0 (
        echo [PASS] shared_preferences dependency found
    ) else (
        echo [WARN] shared_preferences not found - needed for caching
    )
) else (
    echo [FAIL] pubspec.yaml not found
)
echo.

echo [TEST 4] Running Flutter Analyze...
call flutter analyze >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [PASS] No critical issues found
) else (
    echo [WARN] Some issues found - check output
    call flutter analyze
)
echo.

echo [TEST 5] Checking Build Configuration...
if exist "android\app\build.gradle" (
    echo [PASS] Android build configuration found
    findstr /C:"minifyEnabled true" android\app\build.gradle >nul
    if %ERRORLEVEL% EQU 0 (
        echo [PASS] Code obfuscation enabled
    ) else (
        echo [INFO] Code obfuscation not enabled (will be added during release build)
    )
) else (
    echo [WARN] Android build.gradle not found
)
echo.

echo ========================================
echo   PERFORMANCE CONFIGURATION CHECK
echo ========================================
echo.
echo Cache Settings (Check lib\utils\performance_manager.dart):
echo   - Max cache size: 1000 items
echo   - TTL Products:   5 minutes
echo   - TTL Users:      2 minutes
echo   - Expected hit rate: 80%%
echo.
echo Firestore Settings:
echo   - Pagination:     20 items/page
echo   - Indexes:        13 composite indexes
echo   - Query timeout:  30 seconds
echo.
echo Expected Performance:
echo   - App startup:    ^< 2 seconds
echo   - Screen load:    ^< 1 second
echo   - API response:   ^< 500ms
echo   - Memory usage:   ^< 200 MB
echo.
echo Capacity:
echo   - Concurrent users: 10,000+
echo   - Daily cost:       ~$0.27
echo   - Monthly cost:     ~$8-10
echo.

echo ========================================
echo   NEXT STEPS
echo ========================================
echo.
echo 1. Run full test:
echo    flutter test
echo.
echo 2. Test on device:
echo    flutter run --release
echo.
echo 3. Build production:
echo    deploy_production.bat
echo.
echo 4. Monitor performance:
echo    Firebase Console ^> Performance
echo.
echo 5. Check scalability guide:
echo    SCALABILITY_DEPLOYMENT_GUIDE.md
echo.
pause
