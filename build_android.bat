@echo off
echo ========================================
echo FarmKarts - Modern Agriculture Platform
echo ========================================
echo Setting up environment for Android build...
set JAVA_HOME=C:\Program Files\Android\Android Studio3\jbr
set ANDROID_SDK_ROOT=C:\Users\athar\AppData\Local\Android\sdk

echo Cleaning previous build...
flutter clean

echo Getting dependencies...
flutter pub get

echo Building Android APK...
flutter build apk --debug

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo BUILD SUCCESSFUL!
    echo ========================================
    echo APK file created at: build\app\outputs\flutter-apk\app-debug.apk
    echo.
    echo Checking for connected devices...
    adb devices
    
    echo.
    echo To install on your device:
    echo 1. Connect your Android device via USB
    echo 2. Enable USB Debugging in Developer Options
    echo 3. Run: adb install -r build\app\outputs\flutter-apk\app-debug.apk
    echo.
    echo Or transfer the APK file to your device and install manually.
    echo.
) else (
    echo.
    echo ========================================
    echo BUILD FAILED!
    echo ========================================
    echo Please check the error messages above.
    echo.
)

echo.
echo Modern Agriculture App Features:
echo ✓ Beautiful Material Design 3 UI
echo ✓ Comprehensive Dashboard with Analytics
echo ✓ Real-time Market Prices
echo ✓ Weather Integration
echo ✓ Crop Management System
echo ✓ Community Features
echo ✓ Marketplace for Buying/Selling
echo ✓ Expert Consultation
echo ✓ Educational Content
echo.

pause