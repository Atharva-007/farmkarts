# 🌾 FarmKarts - Smart Agriculture Marketplace Platform

<div align="center">

![FarmKarts Logo](https://img.shields.io/badge/FarmKarts-Smart%20Agriculture-green?style=for-the-badge&logo=leaf)

**A comprehensive Flutter-based agricultural marketplace platform connecting farmers, buyers, and agricultural experts through modern technology.**

[![Flutter](https://img.shields.io/badge/Flutter-3.1.5+-02569B?style=flat&logo=flutter)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?style=flat&logo=firebase)](https://firebase.google.com/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat&logo=dart)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-ISC-blue?style=flat)](LICENSE)

[Features](#-features) • [Quick Start](#-quick-start) • [Architecture](#-architecture) • [AI Integration](#-ai-powered-expert-chat) • [Contributing](#-contributing)

</div>

---

## 📖 About FarmKarts

FarmKarts is a modern agricultural marketplace platform that revolutionizes the way farmers, buyers, and agricultural stakeholders interact. Built with Flutter for cross-platform compatibility and powered by Firebase for real-time data management, it provides a comprehensive solution for agricultural commerce, market information, and expert consultation.

### 🎯 Mission
To bridge the gap between traditional agriculture and modern technology, enabling farmers to access better markets, real-time pricing, and expert guidance while providing buyers with direct access to quality agricultural products.

---

## ✨ Features

### 🛒 **Marketplace Core**
- **Multi-Role Authentication** - Farmers, Buyers, Vendors, and Experts.
- **Product Catalog** - Comprehensive listing with categories, images, and details.
- **Real-Time Marketplace** - Live product updates and availability.
- **Secure Transactions** - Integrated payment processing with Razorpay & UPI.
- **Order Tracking** - Enhanced real-time order lifecycle tracking and management.

### 📊 **APMC Market Integration**
- **Live Market Rates** - Real-time commodity pricing from APMC markets across India.
- **Price Analytics** - Trend analysis and historical data for 50+ commodities.
- **Regional Optimization** - Data from major agricultural states (Maharashtra, Punjab, etc.).

### 🤖 **AI-Powered Expert Chat**
- **Dual-Engine AI** - Powered by **Google Gemini 1.5 Flash** for state-of-the-art agricultural intelligence.
- **Multilingual Support** - Real-time translation into **Hindi** and **Marathi** via **Sarvam AI**.
- **Voice-Enabled** - Integrated Speech-to-Text and Text-to-Speech for hands-free operation.
- **Context-Aware** - Deep knowledge base of Indian farming practices, pests, and seasonal crops.

### 🌍 **Location & Maps**
- **Interactive Mandi Maps** - Google Maps integration for finding nearby markets.
- **Location-Based Services** - Discover nearby buyers and optimized delivery routes.

---

## 🏗️ Architecture & Organization

The project follows a **Clean Feature-based Architecture** designed for maximum scalability, performance, and maintainability.

### 📁 Project Structure
- `lib/core/` - Global configurations, themes, and shared utilities.
- `lib/features/` - Feature-specific logic (Marketplace, AI Chat, Community, Profile).
- `lib/models/` - Standardized data models and entities.
- `lib/pages/` - Organized UI screens and navigation wrappers.
- `lib/services/` - Robust singleton services for Firebase, Auth, and AI.
- `lib/widgets/` - Reusable UI components and layout wrappers.
- `lib/test/` - Isolated functional and integration tests.
- `docs/` - Comprehensive technical documentation, scripts, and guides.

### 🛠️ Key Technologies
- **Frontend**: Flutter (3.1.5+)
- **Backend**: Firebase (Auth, Firestore, Storage, Realtime DB, FCM)
- **AI/ML**: Google Gemini 1.5 Flash, Sarvam AI (Indic Language API)
- **Payments**: Razorpay & UPI Integration
- **Maps**: Google Maps Flutter SDK

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.1.5+
- Firebase Project configured
- API Keys for Gemini and Sarvam AI (See `docs/`)

### Setup & Run
```bash
# Install dependencies
flutter pub get

# Run on Android/iOS/Web
flutter run
```

---

## 📈 Performance & Resilience

- **Network Reliability**: `UserStateService` features 3-stage exponential backoff for high-latency rural connections.
- **Optimized Assets**: Enhanced image upload handling with 60s timeouts and progress tracking.
- **Lazy Loading**: UI components use lazy-loading patterns to ensure smooth performance on mid-range devices.

---

## 🤝 Contributing

We welcome contributions! Please refer to the [DEVELOPER_QUICK_REFERENCE.md](DEVELOPER_QUICK_REFERENCE.md) for coding standards and the branching model.

---

<div align="center">

**Built with ❤️ for the Agriculture Community**

**Version 1.1.0** | **Last Updated: March 2026** | **Status: Enhanced Production** ✅

</div>
