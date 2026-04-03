#!/bin/bash

# FarmKarts Production Deployment Script
# Complete automated deployment to production

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     FarmKarts Production Deployment Script                   ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_step() {
    echo -e "${GREEN}▶ $1${NC}"
}

print_error() {
    echo -e "${RED}✖ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check prerequisites
print_step "Checking prerequisites..."

if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed"
    exit 1
fi

if ! command -v firebase &> /dev/null; then
    print_error "Firebase CLI is not installed"
    exit 1
fi

print_step "✓ All prerequisites met"
echo ""

# Clean build
print_step "Cleaning previous builds..."
flutter clean
rm -rf build/

# Get dependencies
print_step "Getting dependencies..."
flutter pub get

# Run tests
print_step "Running tests..."
flutter test || {
    print_error "Tests failed! Aborting deployment."
    exit 1
}

# Code analysis
print_step "Running code analysis..."
flutter analyze || {
    print_warning "Code analysis warnings detected"
}

# Build Android
print_step "Building Android APK..."
flutter build apk --release --split-per-abi

print_step "Building Android App Bundle..."
flutter build appbundle --release

# Build Web
print_step "Building Web..."
flutter build web --release

# Build iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_step "Building iOS..."
    flutter build ios --release
else
    print_warning "Skipping iOS build (not on macOS)"
fi

# Deploy to Firebase
print_step "Deploying to Firebase..."

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage:rules

# Deploy Web hosting
firebase deploy --only hosting

# Deploy Cloud Functions (if any)
if [ -d "functions" ]; then
    print_step "Deploying Cloud Functions..."
    firebase deploy --only functions
fi

# Upload to Play Store (requires setup)
print_step "Preparing Play Store upload..."
print_warning "Manual Play Store upload required"
echo "Upload file: build/app/outputs/bundle/release/app-release.aab"

# Generate release notes
print_step "Generating release notes..."
VERSION=$(grep 'version:' pubspec.yaml | cut -d ' ' -f 2)
BUILD_NUMBER=$(grep 'version:' pubspec.yaml | cut -d '+' -f 2)

cat > RELEASE_NOTES.md << EOF
# FarmKarts Release v$VERSION (Build $BUILD_NUMBER)

## What's New
- Production-ready deployment
- Performance optimizations
- Bug fixes and improvements

## Builds
- Android APK: build/app/outputs/flutter-apk/
- Android Bundle: build/app/outputs/bundle/release/
- Web: build/web/
- iOS: build/ios/iphoneos/ (if built)

## Deployment
- Firebase Hosting: ✅ Deployed
- Firestore Rules: ✅ Deployed
- Storage Rules: ✅ Deployed

## Next Steps
1. Test deployed web app
2. Upload Android bundle to Play Store
3. Submit iOS build to App Store (if applicable)
4. Monitor Firebase Analytics
5. Check error reports in Crashlytics

Generated on: $(date)
EOF

# Success
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                  DEPLOYMENT COMPLETE! ✅                      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
print_step "Build artifacts:"
echo "  • Android APK: build/app/outputs/flutter-apk/"
echo "  • Android Bundle: build/app/outputs/bundle/release/"
echo "  • Web: build/web/"
echo ""
print_step "Next steps:"
echo "  1. Test the deployed web app"
echo "  2. Upload Android bundle to Play Store Console"
echo "  3. Monitor Firebase Analytics dashboard"
echo "  4. Check Crashlytics for any issues"
echo ""
print_step "Release notes saved to: RELEASE_NOTES.md"
echo ""
