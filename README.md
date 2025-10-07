# FarmKarts - Agricultural Marketplace Application

A comprehensive Flutter application with Node.js backend for agricultural marketplace functionality, supporting both web and mobile platforms.

## 🚀 Quick Start

### Option 1: One-Click Launch
Run the startup script:
```bash
start_farmkart.bat
```

### Option 2: Manual Launch

#### Backend Server
```bash
cd farmkart-backend
npm start
```

#### Frontend (Web)
```bash
flutter run -d chrome --web-hostname localhost --web-port 8080
```

#### Frontend (Android)
```bash
flutter run
```

## 📱 Application Features

### Core Features
- **User Authentication** - Firebase Auth integration
- **Product Marketplace** - Buy/Sell agricultural products
- **Location Services** - Google Maps integration for mandis
- **Real-time Database** - Firebase Realtime Database
- **Notifications** - Local notifications support
- **File Sharing** - PDF generation and sharing
- **APMC Integration** - Agricultural market information
- **News & Updates** - Agricultural news and updates

### Pages & Functionality
- **Login/Signup** - User authentication
- **Home Page** - Dashboard with quick access
- **Buy Page** - Browse and purchase products
- **Sell Page** - List products for sale
- **Mandi Page** - Local market information
- **APMC Page** - Agricultural market committee data
- **MAHABEJ Page** - Market price information
- **News Page** - Agricultural news and updates
- **Profile Page** - User profile management
- **Settings Page** - Application preferences

## 🛠 Technical Stack

### Frontend (Flutter)
- **Framework**: Flutter 3.32.5
- **State Management**: StatefulWidget
- **Authentication**: Firebase Auth
- **Database**: Firebase Realtime Database & Firestore
- **Maps**: Google Maps Flutter
- **Notifications**: Flutter Local Notifications
- **HTTP**: HTTP package for API calls
- **UI**: Material Design

### Backend (Node.js)
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: Firebase Admin SDK
- **Authentication**: Firebase Admin
- **CORS**: Enabled for cross-origin requests

## 🔧 Setup & Installation

### Prerequisites
- Flutter SDK (3.1.5 or higher)
- Node.js (14.x or higher)
- Android Studio (for Android development)
- Chrome (for web development)
- Firebase project setup

### Installation Steps

1. **Clone the repository**
   ```bash
   cd C:\Users\athar\StudioProjects\farmkarts_new
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Install Backend dependencies**
   ```bash
   cd farmkart-backend
   npm install
   ```

4. **Firebase Configuration**
   - Ensure `google-services.json` is in `android/app/`
   - Firebase configuration is in `lib/firebase_options.dart`

5. **Run the application**
   ```bash
   # Start both backend and frontend
   start_farmkart.bat
   ```

## 🌐 Platform Support

### Web Browser
- **URL**: http://localhost:8080
- **Features**: Full functionality with responsive design
- **Requirements**: Modern web browser with JavaScript enabled

### Android
- **Target SDK**: 34
- **Min SDK**: 21
- **Features**: Native Android experience with location services
- **Requirements**: Android device or emulator

### API Endpoints
- **Base URL**: http://localhost:3000
- **Health Check**: `/api/health`
- **Items API**: `/api/items` (GET, POST, PUT, DELETE)

## 📊 Database Structure

### Firebase Realtime Database
```
farmkart-9f4f3
├── users/
│   ├── {userId}/
│   │   ├── email
│   │   ├── name
│   │   └── profile_data
└── itemsForSale/
    ├── {itemId}/
    │   ├── productName
    │   ├── description
    │   ├── price
    │   ├── farmerName
    │   ├── location
    │   └── createdAt
```

## 🔐 Security Features

- **Firebase Authentication** - Secure user authentication
- **Data Validation** - Input validation on both frontend and backend
- **CORS Protection** - Configured for secure cross-origin requests
- **Permission Management** - Location and storage permissions
- **Secure API** - Firebase Admin SDK for backend security

## 🚀 Development

### Debug Mode
```bash
# Web development
flutter run -d chrome --web-hostname localhost --web-port 8080

# Android development
flutter run

# Backend development
cd farmkart-backend
npm run dev  # If nodemon is configured
```

### Build for Production
```bash
# Web build
flutter build web

# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

## 📱 Features by Platform

| Feature | Web | Android | Backend API |
|---------|-----|---------|-------------|
| Authentication | ✅ | ✅ | ✅ |
| Product Listing | ✅ | ✅ | ✅ |
| Google Maps | ✅ | ✅ | N/A |
| Notifications | ✅ | ✅ | N/A |
| File Sharing | ✅ | ✅ | N/A |
| Location Services | ✅ | ✅ | N/A |
| Real-time Data | ✅ | ✅ | ✅ |

## 🐛 Troubleshooting

### Common Issues

1. **Firebase Connection Issues**
   - Check internet connection
   - Verify Firebase configuration
   - Ensure API keys are valid

2. **Build Issues**
   - Run `flutter clean && flutter pub get`
   - Check Flutter and Dart SDK versions
   - Verify Android SDK installation

3. **Backend Issues**
   - Check Node.js version
   - Verify Firebase Admin SDK setup
   - Check port 3000 availability

4. **Maps Not Loading**
   - Verify Google Maps API key
   - Check browser location permissions
   - Ensure Maps API is enabled in Google Cloud Console

### Support
For technical support or issues, check the following:
- Flutter doctor: `flutter doctor`
- Backend health: http://localhost:3000/api/health
- Firebase Console for database issues

## 📈 Performance

### Optimizations
- **Lazy Loading** - Components loaded as needed
- **Image Optimization** - Compressed assets
- **Database Indexing** - Optimized Firebase queries
- **Caching** - Local storage for frequently accessed data

### Monitoring
- Backend health endpoint for system status
- Firebase Analytics for user behavior
- Error tracking through Firebase Crashlytics

---

**Version**: 1.0.0  
**Last Updated**: October 2025  
**License**: ISC
