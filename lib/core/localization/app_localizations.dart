import 'package:flutter/material.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, AppLocalizations> _localizations = {
    'en': AppLocalizationsEn(),
    'hi': AppLocalizationsHi(),
    'mr': AppLocalizationsMr(),
  };

  static AppLocalizations? load(Locale locale) {
    return _localizations[locale.languageCode];
  }

  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('hi', ''),
    Locale('mr', ''),
  ];

  // Common
  String get appName;
  String get ok;
  String get cancel;
  String get yes;
  String get no;
  String get save;
  String get delete;
  String get edit;
  String get search;
  String get filter;
  String get share;
  String get refresh;
  String get loading;
  String get error;
  String get success;
  String get warning;
  String get noData;
  String get retry;
  String get close;

  // Auth
  String get login;
  String get logout;
  String get signup;
  String get email;
  String get password;
  String get confirmPassword;
  String get forgotPassword;
  String get emailOrPhone;
  String get enterEmailOrPhone;
  String get enterPassword;
  String get rememberMe;
  String get dontHaveAccount;
  String get alreadyHaveAccount;
  String get createAccount;
  String get invalidCredentials;
  String get accountCreated;
  String get welcomeBack;

  // Navigation
  String get dashboard;
  String get marketplace;
  String get community;
  String get crops;
  String get weather;
  String get apmc;
  String get profile;
  String get settings;
  String get orders;
  String get wishlist;
  String get cart;
  String get aiExpert;
  String get inventory;
  String get license;

  // Dashboard
  String get welcomeMessage;
  String get quickActions;
  String get liveMarketRates;
  String get viewAll;
  String get notifications;
  String get weatherForecast;
  String get myFarm;
  String get insights;

  // Marketplace
  String get buyProducts;
  String get sellProducts;
  String get categories;
  String get priceRange;
  String get organic;
  String get inStock;
  String get outOfStock;
  String get addToCart;
  String get buyNow;
  String get addToWishlist;
  String get removeFromWishlist;
  String get productDetails;
  String get seller;
  String get contactSeller;
  String get quantity;
  String get price;
  String get totalPrice;
  String get checkout;

  // Profile
  String get myProfile;
  String get personalInfo;
  String get editProfile;
  String get changePassword;
  String get language;
  String get theme;
  String get notifications_settings;
  String get privacyPolicy;
  String get termsConditions;
  String get aboutUs;
  String get contactUs;
  String get helpSupport;
  String get version;

  // Settings
  String get generalSettings;
  String get appearance;
  String get lightMode;
  String get darkMode;
  String get systemDefault;
  String get selectLanguage;
  String get selectTheme;
  String get english;
  String get hindi;
  String get marathi;

  // Cart & Wishlist
  String get emptyCart;
  String get emptyWishlist;
  String get cartItems;
  String get wishlistItems;
  String get removeItem;
  String get moveToCart;
  String get subtotal;
  String get tax;
  String get total;
  String get proceedToCheckout;
  String get itemAdded;
  String get itemRemoved;

  // Orders
  String get myOrders;
  String get orderHistory;
  String get orderDetails;
  String get orderPlaced;
  String get orderConfirmed;
  String get orderShipped;
  String get orderDelivered;
  String get orderCancelled;
  String get trackOrder;
  String get cancelOrder;

  // Community
  String get createPost;
  String get posts;
  String get comments;
  String get likes;
  String get share_post;
  String get reportPost;
  String get deletePost;

  // Crops
  String get myCrops;
  String get addCrop;
  String get cropDetails;
  String get plantingDate;
  String get harvestDate;
  String get cropHealth;
  String get irrigation;
  String get fertilizer;

  // Weather
  String get currentWeather;
  String get forecast;
  String get temperature;
  String get humidity;
  String get rainfall;
  String get windSpeed;
  String get uvIndex;

  // APMC
  String get apmcRates;
  String get commodity;
  String get market;
  String get date;
  String get minPrice;
  String get maxPrice;
  String get modalPrice;

  // Messages
  String get somethingWentWrong;
  String get noInternetConnection;
  String get tryAgainLater;
  String get dataLoadedSuccessfully;
  String get actionCompletedSuccessfully;
  String get areYouSure;
  String get cannotUndo;
  String get confirmAction;
  String get operationSuccess;
  String get operationFailed;

  // Validation
  String get fieldRequired;
  String get invalidEmail;
  String get invalidPhone;
  String get passwordTooShort;
  String get passwordsDoNotMatch;
  String get invalidInput;
  String get valueTooLow;
  String get valueTooHigh;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'mr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations.load(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
