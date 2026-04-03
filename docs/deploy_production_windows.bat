@echo off
REM FarmKarts Production Deployment Script (Windows)

echo ===============================================================
echo      FarmKarts Production Deployment Script (Windows)
echo ===============================================================
echo.

echo [Step 1/10] Checking prerequisites...
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Flutter is not installed or not in PATH
    exit /b 1
)

where firebase >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Firebase CLI is not installed
    echo Install: npm install -g firebase-tools
    exit /b 1
)

echo OK: All prerequisites met
echo.

echo [Step 2/10] Cleaning previous builds...
flutter clean
if exist build rmdir /s /q build

echo [Step 3/10] Getting dependencies...
flutter pub get

echo [Step 4/10] Running tests...
flutter test
if %errorlevel% neq 0 (
    echo ERROR: Tests failed! Aborting deployment.
    exit /b 1
)

echo [Step 5/10] Running code analysis...
flutter analyze

echo [Step 6/10] Building Android APK...
flutter build apk --release --split-per-abi

echo [Step 7/10] Building Android App Bundle...
flutter build appbundle --release

echo [Step 8/10] Building Web...
flutter build web --release

echo [Step 9/10] Deploying to Firebase...
firebase deploy --only firestore:rules,storage:rules,hosting

echo [Step 10/10] Generating release notes...
for /f "tokens=2 delims=: " %%a in ('findstr "version:" pubspec.yaml') do set VERSION=%%a

echo FarmKarts Release v%VERSION% > RELEASE_NOTES.txt
echo ================================ >> RELEASE_NOTES.txt
echo. >> RELEASE_NOTES.txt
echo Build Date: %date% %time% >> RELEASE_NOTES.txt
echo. >> RELEASE_NOTES.txt
echo Build Artifacts: >> RELEASE_NOTES.txt
echo - Android APK: build\app\outputs\flutter-apk\ >> RELEASE_NOTES.txt
echo - Android Bundle: build\app\outputs\bundle\release\ >> RELEASE_NOTES.txt
echo - Web: build\web\ >> RELEASE_NOTES.txt
echo. >> RELEASE_NOTES.txt

echo.
echo ===============================================================
echo              DEPLOYMENT COMPLETE! SUCCESS!
echo ===============================================================
echo.
echo Build artifacts generated:
echo   * Android APK: build\app\outputs\flutter-apk\
echo   * Android Bundle: build\app\outputs\bundle\release\
echo   * Web: build\web\
echo.
echo Next steps:
echo   1. Test the deployed web app
echo   2. Upload Android bundle to Play Store
echo   3. Monitor Firebase Analytics
echo   4. Check Crashlytics for errors
echo.
echo Release notes: RELEASE_NOTES.txt
echo.
pause
