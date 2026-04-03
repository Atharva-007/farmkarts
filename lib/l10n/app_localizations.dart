import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Common
      'app_name': 'FarmKarts',
      'welcome': 'Welcome',
      'hello': 'Hello',
      'loading': 'Loading...',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'done': 'Done',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'search': 'Search',
      'filter': 'Filter',
      'sort': 'Sort',
      
      // Authentication
      'login': 'Login',
      'email_or_mobile': 'Email or Mobile Number',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'dont_have_account': "Don't have an account?",
      'sign_up': 'Sign Up',
      'login_button': 'Login',
      'signup_button': 'Sign Up',
      'logout': 'Logout',
      'login_error': 'Invalid email/mobile or password',
      'login_success': 'Login successful',
      'invalid_credentials': 'Invalid email/mobile or password',
      'user_not_found': 'User not found. Please sign up.',
      'invalid_email_mobile': 'Please enter valid email or mobile number',
      'too_many_attempts': 'Too many login attempts. Please try again later.',
      'network_error': 'Network error. Please check your connection.',
      'account_disabled': 'This account has been disabled.',
      'session_expired': 'Your session has expired. Please login again.',
      'login_failed': 'Login failed. Please try again.',
      'enter_email_mobile': 'Please enter email or mobile number',
      
      // Navigation
      'dashboard': 'Dashboard',
      'marketplace': 'Marketplace',
      'crops': 'Crops',
      'apmc': 'APMC Markets',
      'profile': 'Profile',
      'settings': 'Settings',
      'wishlist': 'Wishlist',
      'cart': 'Shopping Cart',
      'orders': 'Orders',
      'ai_expert': 'AI Expert',
      'community': 'Community',
      'weather': 'Weather',
      'notifications': 'Notifications',
      
      // Settings
      'language': 'Language',
      'theme': 'Theme',
      'light_mode': 'Light Mode',
      'dark_mode': 'Dark Mode',
      'system_default': 'System Default',
      'appearance': 'Appearance',
      'account_settings': 'Account Settings',
      'select_language': 'Select Language',
      'select_theme': 'Select Theme',
      
      // Marketplace
      'add_product': 'Add Product',
      'product_name': 'Product Name',
      'product_price': 'Price',
      'product_quantity': 'Quantity',
      'product_description': 'Description',
      'add_to_cart': 'Add to Cart',
      'buy_now': 'Buy Now',
      'added_to_cart': 'Added to cart',
      'added_to_wishlist': 'Added to wishlist',
      'removed_from_wishlist': 'Removed from wishlist',
      'category': 'Category',
      'organic': 'Organic',
      'fresh': 'Fresh',
      'location': 'Location',
      
      // Cart & Wishlist
      'cart_empty': 'Your cart is empty',
      'wishlist_empty': 'Your wishlist is empty',
      'checkout': 'Checkout',
      'total': 'Total',
      'subtotal': 'Subtotal',
      'proceed_to_checkout': 'Proceed to Checkout',
      'remove': 'Remove',
      'move_to_cart': 'Move to Cart',
      
      // Profile
      'edit_profile': 'Edit Profile',
      'my_orders': 'My Orders',
      'my_products': 'My Products',
      'inventory': 'Inventory',
      'license_management': 'License Management',
      'selling_history': 'Selling History',
      'buying_history': 'Buying History',
      
      // General UI
      'refresh': 'Refresh',
      'error_occurred': 'An error occurred',
      'try_again': 'Try Again',
      'no_data': 'No data available',
      'coming_soon': 'Coming Soon',
    },
    'hi': {
      // Common
      'app_name': 'फार्मकार्ट्स',
      'welcome': 'स्वागत है',
      'hello': 'नमस्ते',
      'loading': 'लोड हो रहा है...',
      'save': 'सहेजें',
      'cancel': 'रद्द करें',
      'delete': 'हटाएं',
      'edit': 'संपादित करें',
      'done': 'पूर्ण',
      'ok': 'ठीक है',
      'yes': 'हां',
      'no': 'नहीं',
      'search': 'खोजें',
      'filter': 'फ़िल्टर',
      'sort': 'क्रमबद्ध करें',
      
      // Authentication
      'login': 'लॉगिन',
      'email_or_mobile': 'ईमेल या मोबाइल नंबर',
      'password': 'पासवर्ड',
      'forgot_password': 'पासवर्ड भूल गए?',
      'dont_have_account': 'खाता नहीं है?',
      'sign_up': 'साइन अप करें',
      'login_button': 'लॉगिन करें',
      'signup_button': 'साइन अप करें',
      'logout': 'लॉगआउट',
      'login_error': 'अमान्य ईमेल/मोबाइल या पासवर्ड',
      'login_success': 'लॉगिन सफल',
      'invalid_credentials': 'अमान्य ईमेल/मोबाइल या पासवर्ड',
      'user_not_found': 'उपयोगकर्ता नहीं मिला। कृपया साइन अप करें।',
      'invalid_email_mobile': 'कृपया मान्य ईमेल या मोबाइल नंबर दर्ज करें',
      'too_many_attempts': 'बहुत अधिक लॉगिन प्रयास। कृपया बाद में पुनः प्रयास करें।',
      'network_error': 'नेटवर्क त्रुटि। कृपया अपना कनेक्शन जांचें।',
      'account_disabled': 'यह खाता अक्षम कर दिया गया है।',
      'session_expired': 'आपका सत्र समाप्त हो गया है। कृपया फिर से लॉगिन करें।',
      'login_failed': 'लॉगिन विफल। कृपया पुनः प्रयास करें।',
      'enter_email_mobile': 'कृपया ईमेल या मोबाइल नंबर दर्ज करें',
      
      // Navigation
      'dashboard': 'डैशबोर्ड',
      'marketplace': 'बाज़ार',
      'crops': 'फसलें',
      'apmc': 'एपीएमसी बाज़ार',
      'profile': 'प्रोफाइल',
      'settings': 'सेटिंग्स',
      'wishlist': 'इच्छा सूची',
      'cart': 'शॉपिंग कार्ट',
      'orders': 'आदेश',
      'ai_expert': 'एआई विशेषज्ञ',
      'community': 'समुदाय',
      'weather': 'मौसम',
      'notifications': 'सूचनाएं',
      
      // Settings
      'language': 'भाषा',
      'theme': 'थीम',
      'light_mode': 'लाइट मोड',
      'dark_mode': 'डार्क मोड',
      'system_default': 'सिस्टम डिफ़ॉल्ट',
      'appearance': 'दिखावट',
      'account_settings': 'खाता सेटिंग्स',
      'select_language': 'भाषा चुनें',
      'select_theme': 'थीम चुनें',
      
      // Marketplace
      'add_product': 'उत्पाद जोड़ें',
      'product_name': 'उत्पाद का नाम',
      'product_price': 'मूल्य',
      'product_quantity': 'मात्रा',
      'product_description': 'विवरण',
      'add_to_cart': 'कार्ट में डालें',
      'buy_now': 'अभी खरीदें',
      'added_to_cart': 'कार्ट में जोड़ा गया',
      'added_to_wishlist': 'इच्छा सूची में जोड़ा गया',
      'removed_from_wishlist': 'इच्छा सूची से हटाया गया',
      'category': 'श्रेणी',
      'organic': 'जैविक',
      'fresh': 'ताज़ा',
      'location': 'स्थान',
      
      // Cart & Wishlist
      'cart_empty': 'आपकी कार्ट खाली है',
      'wishlist_empty': 'आपकी इच्छा सूची खाली है',
      'checkout': 'चेकआउट',
      'total': 'कुल',
      'subtotal': 'उप-योग',
      'proceed_to_checkout': 'चेकआउट करें',
      'remove': 'हटाएं',
      'move_to_cart': 'कार्ट में ले जाएं',
      
      // Profile
      'edit_profile': 'प्रोफाइल संपादित करें',
      'my_orders': 'मेरे आदेश',
      'my_products': 'मेरे उत्पाद',
      'inventory': 'इन्वेंटरी',
      'license_management': 'लाइसेंस प्रबंधन',
      'selling_history': 'बिक्री इतिहास',
      'buying_history': 'खरीद इतिहास',
      
      // General UI
      'refresh': 'रीफ्रेश करें',
      'error_occurred': 'एक त्रुटि हुई',
      'try_again': 'पुनः प्रयास करें',
      'no_data': 'कोई डेटा उपलब्ध नहीं',
      'coming_soon': 'जल्द आ रहा है',
    },
    'mr': {
      // Common
      'app_name': 'फार्मकार्ट्स',
      'welcome': 'स्वागत आहे',
      'hello': 'नमस्कार',
      'loading': 'लोड होत आहे...',
      'save': 'जतन करा',
      'cancel': 'रद्द करा',
      'delete': 'हटवा',
      'edit': 'संपादित करा',
      'done': 'पूर्ण',
      'ok': 'ठीक आहे',
      'yes': 'होय',
      'no': 'नाही',
      'search': 'शोधा',
      'filter': 'फिल्टर',
      'sort': 'क्रमवारी लावा',
      
      // Authentication
      'login': 'लॉगिन',
      'email_or_mobile': 'ईमेल किंवा मोबाईल नंबर',
      'password': 'पासवर्ड',
      'forgot_password': 'पासवर्ड विसरलात?',
      'dont_have_account': 'खाते नाही?',
      'sign_up': 'साइन अप करा',
      'login_button': 'लॉगिन करा',
      'signup_button': 'साइन अप करा',
      'logout': 'लॉगआउट',
      'login_error': 'अवैध ईमेल/मोबाईल किंवा पासवर्ड',
      'login_success': 'लॉगिन यशस्वी',
      'invalid_credentials': 'अवैध ईमेल/मोबाईल किंवा पासवर्ड',
      'user_not_found': 'वापरकर्ता सापडला नाही. कृपया साइन अप करा.',
      'invalid_email_mobile': 'कृपया वैध ईमेल किंवा मोबाईल नंबर टाका',
      'too_many_attempts': 'खूप जास्त लॉगिन प्रयत्न. कृपया नंतर प्रयत्न करा.',
      'network_error': 'नेटवर्क त्रुटी. कृपया तुमचे कनेक्शन तपासा.',
      'account_disabled': 'हे खाते अक्षम केले गेले आहे.',
      'session_expired': 'तुमचे सत्र संपले आहे. कृपया पुन्हा लॉगिन करा.',
      'login_failed': 'लॉगिन अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      'enter_email_mobile': 'कृपया ईमेल किंवा मोबाईल नंबर टाका',
      
      // Navigation
      'dashboard': 'डॅशबोर्ड',
      'marketplace': 'बाजारपेठ',
      'crops': 'पिके',
      'apmc': 'एपीएमसी बाजार',
      'profile': 'प्रोफाइल',
      'settings': 'सेटिंग्ज',
      'wishlist': 'इच्छा यादी',
      'cart': 'खरेदी कार्ट',
      'orders': 'ऑर्डर्स',
      'ai_expert': 'एआय तज्ञ',
      'community': 'समुदाय',
      'weather': 'हवामान',
      'notifications': 'सूचना',
      
      // Settings
      'language': 'भाषा',
      'theme': 'थीम',
      'light_mode': 'लाइट मोड',
      'dark_mode': 'डार्क मोड',
      'system_default': 'सिस्टम डीफॉल्ट',
      'appearance': 'दिखावा',
      'account_settings': 'खाते सेटिंग्ज',
      'select_language': 'भाषा निवडा',
      'select_theme': 'थीम निवडा',
      
      // Marketplace
      'add_product': 'उत्पादन जोडा',
      'product_name': 'उत्पादनाचे नाव',
      'product_price': 'किंमत',
      'product_quantity': 'प्रमाण',
      'product_description': 'वर्णन',
      'add_to_cart': 'कार्टमध्ये टाका',
      'buy_now': 'आता खरेदी करा',
      'added_to_cart': 'कार्टमध्ये जोडले',
      'added_to_wishlist': 'इच्छा यादीत जोडले',
      'removed_from_wishlist': 'इच्छा यादीतून काढले',
      'category': 'श्रेणी',
      'organic': 'सेंद्रिय',
      'fresh': 'ताजे',
      'location': 'स्थान',
      
      // Cart & Wishlist
      'cart_empty': 'तुमची कार्ट रिकामी आहे',
      'wishlist_empty': 'तुमची इच्छा यादी रिकामी आहे',
      'checkout': 'चेकआउट',
      'total': 'एकूण',
      'subtotal': 'उप-एकूण',
      'proceed_to_checkout': 'चेकआउट करा',
      'remove': 'काढा',
      'move_to_cart': 'कार्टमध्ये हलवा',
      
      // Profile
      'edit_profile': 'प्रोफाइल संपादित करा',
      'my_orders': 'माझे ऑर्डर्स',
      'my_products': 'माझी उत्पादने',
      'inventory': 'इन्व्हेंटरी',
      'license_management': 'परवाना व्यवस्थापन',
      'selling_history': 'विक्री इतिहास',
      'buying_history': 'खरेदी इतिहास',
      
      // General UI
      'refresh': 'रीफ्रेश करा',
      'error_occurred': 'एक त्रुटी झाली',
      'try_again': 'पुन्हा प्रयत्न करा',
      'no_data': 'डेटा उपलब्ध नाही',
      'coming_soon': 'लवकरच येत आहे',
      'logout': 'लॉगआउट',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'mr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
