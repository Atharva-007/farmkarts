import 'package:flutter/material.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;

  final Map<String, Map<String, String>> _translations = {
    'en': {
      'app_name': 'FarmKarts',
      'email_or_mobile': 'Email or Mobile Number',
      'password': 'Password',
      'login': 'Login',
      'register': 'Register',
      'forgot_password': 'Forgot Password?',
      'language': 'Language',
      'dashboard': 'Dashboard',
      'marketplace': 'Marketplace',
      'community': 'Community',
      'crops': 'Crops',
      'weather': 'Weather',
      'apmc': 'APMC Markets',
      'profile': 'Profile',
      'wishlist': 'Wishlist',
      'cart': 'Cart',
      'orders': 'Orders',
      'settings': 'Settings',
      'ai_expert': 'AI Expert',
      'logout': 'Logout',
      'invalid_credentials': 'Invalid email/mobile or password',
      'login_failed': 'Login failed. Please try again.',
      'enter_email_mobile': 'Please enter email or mobile number',
      'enter_password': 'Please enter password',
      'user_not_found': 'No account found with this credential',
      'invalid_email_mobile': 'Please enter a valid email or mobile number',
      'too_many_attempts': 'Too many failed attempts. Please try again later',
      'network_error': 'Network error. Please check your connection',
      'account_disabled': 'Your account has been disabled',
      'session_expired': 'Session expired. Please login again',
    },
    'hi': {
      'app_name': 'फार्मकार्ट्स',
      'email_or_mobile': 'ईमेल या मोबाइल नंबर',
      'password': 'पासवर्ड',
      'login': 'लॉगिन',
      'register': 'रजिस्टर करें',
      'forgot_password': 'पासवर्ड भूल गए?',
      'language': 'भाषा',
      'dashboard': 'डैशबोर्ड',
      'marketplace': 'बाज़ार',
      'community': 'समुदाय',
      'crops': 'फसलें',
      'weather': 'मौसम',
      'apmc': 'एपीएमसी बाज़ार',
      'profile': 'प्रोफ़ाइल',
      'wishlist': 'इच्छा सूची',
      'cart': 'कार्ट',
      'orders': 'आदेश',
      'settings': 'सेटिंग्स',
      'ai_expert': 'एआई विशेषज्ञ',
      'logout': 'लॉगआउट',
      'invalid_credentials': 'अमान्य ईमेल/मोबाइल या पासवर्ड',
      'login_failed': 'लॉगिन विफल रहा। कृपया पुनः प्रयास करें',
      'enter_email_mobile': 'कृपया ईमेल या मोबाइल नंबर दर्ज करें',
      'enter_password': 'कृपया पासवर्ड दर्ज करें',
      'user_not_found': 'इस क्रेडेंशियल के साथ कोई खाता नहीं मिला',
      'invalid_email_mobile': 'कृपया एक वैध ईमेल या मोबाइल नंबर दर्ज करें',
      'too_many_attempts': 'बहुत अधिक असफल प्रयास। कृपया बाद में पुनः प्रयास करें',
      'network_error': 'नेटवर्क त्रुटि। कृपया अपना कनेक्शन जांचें',
      'account_disabled': 'आपका खाता अक्षम कर दिया गया है',
      'session_expired': 'सत्र समाप्त हो गया। कृपया फिर से लॉगिन करें',
    },
    'mr': {
      'app_name': 'फार्मकार्ट्स',
      'email_or_mobile': 'ईमेल किंवा मोबाइल नंबर',
      'password': 'पासवर्ड',
      'login': 'लॉगिन',
      'register': 'नोंदणी करा',
      'forgot_password': 'पासवर्ड विसरलात?',
      'language': 'भाषा',
      'dashboard': 'डॅशबोर्ड',
      'marketplace': 'बाजारपेठ',
      'community': 'समुदाय',
      'crops': 'पिके',
      'weather': 'हवामान',
      'apmc': 'एपीएमसी बाजार',
      'profile': 'प्रोफाइल',
      'wishlist': 'इच्छा यादी',
      'cart': 'कार्ट',
      'orders': 'ऑर्डर',
      'settings': 'सेटिंग्ज',
      'ai_expert': 'एआय तज्ञ',
      'logout': 'लॉगआउट',
      'invalid_credentials': 'अवैध ईमेल/मोबाइल किंवा पासवर्ड',
      'login_failed': 'लॉगिन अयशस्वी. कृपया पुन्हा प्रयत्न करा',
      'enter_email_mobile': 'कृपया ईमेल किंवा मोबाइल नंबर प्रविष्ट करा',
      'enter_password': 'कृपया पासवर्ड प्रविष्ट करा',
      'user_not_found': 'या क्रेडेंशियलसह कोणतेही खाते आढळले नाही',
      'invalid_email_mobile': 'कृपया वैध ईमेल किंवा मोबाइल नंबर प्रविष्ट करा',
      'too_many_attempts': 'खूप अयशस्वी प्रयत्न. कृपया नंतर पुन्हा प्रयत्न करा',
      'network_error': 'नेटवर्क त्रुटी. कृपया आपले कनेक्शन तपासा',
      'account_disabled': 'तुमचे खाते अक्षम केले गेले आहे',
      'session_expired': 'सत्र संपले. कृपया पुन्हा लॉगिन करा',
      'logout': 'लॉगआउट',
      'invalid_credentials': 'अवैध ईमेल/मोबाइल किंवा पासवर्ड',
      'login_failed': 'लॉगिन अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      'enter_email_mobile': 'कृपया ईमेल किंवा मोबाइल नंबर प्रविष्ट करा',
      'enter_password': 'कृपया पासवर्ड प्रविष्ट करा',
    },
  };

  String translate(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }

  void changeLanguage(String languageCode) {
    _currentLanguage = languageCode;
    notifyListeners();
  }

  List<Map<String, String>> get supportedLanguages => [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'हिंदी'},
    {'code': 'mr', 'name': 'मराठी'},
  ];
}
