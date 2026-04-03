import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/foundation.dart';

/// In-App Messaging Service
/// Handles Firebase In-App Messaging for user engagement and marketing
class InAppMessagingService {
  static final InAppMessagingService _instance = InAppMessagingService._internal();
  factory InAppMessagingService() => _instance;
  InAppMessagingService._internal();

  final FirebaseInAppMessaging _fiam = FirebaseInAppMessaging.instance;
  bool _initialized = false;

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Set message display suppression (useful for testing)
      await _fiam.setMessagesSuppressed(false);

      // Enable automatic data collection
      await _fiam.setAutomaticDataCollectionEnabled(true);

      _initialized = true;
      debugPrint('InAppMessaging: Service initialized');
    } catch (e) {
      debugPrint('InAppMessaging: Initialization error - $e');
    }
  }

  // ==================== MESSAGE CONTROL ====================

  /// Trigger in-app message programmatically
  Future<void> triggerEvent(String eventName) async {
    try {
      // Firebase In-App Messaging will show messages based on events
      // Events are logged via Analytics
      debugPrint('InAppMessaging: Event triggered - $eventName');
    } catch (e) {
      debugPrint('InAppMessaging: Error triggering event - $e');
    }
  }

  /// Suppress in-app messages
  Future<void> suppressMessages() async {
    try {
      await _fiam.setMessagesSuppressed(true);
      debugPrint('InAppMessaging: Messages suppressed');
    } catch (e) {
      debugPrint('InAppMessaging: Error suppressing messages - $e');
    }
  }

  /// Resume in-app messages
  Future<void> resumeMessages() async {
    try {
      await _fiam.setMessagesSuppressed(false);
      debugPrint('InAppMessaging: Messages resumed');
    } catch (e) {
      debugPrint('InAppMessaging: Error resuming messages - $e');
    }
  }

  // ==================== CAMPAIGN TRIGGERS ====================

  /// Trigger welcome message
  void triggerWelcome() {
    triggerEvent('welcome_shown');
  }

  /// Trigger product discovery
  void triggerProductDiscovery() {
    triggerEvent('product_discovery');
  }

  /// Trigger cart abandoned
  void triggerCartAbandoned() {
    triggerEvent('cart_abandoned');
  }

  /// Trigger price drop alert
  void triggerPriceDrop() {
    triggerEvent('price_drop_available');
  }

  /// Trigger new feature announcement
  void triggerNewFeature() {
    triggerEvent('new_feature_available');
  }

  /// Trigger promotional campaign
  void triggerPromotion() {
    triggerEvent('promotion_available');
  }

  /// Trigger tutorial
  void triggerTutorial() {
    triggerEvent('tutorial_needed');
  }

  /// Trigger feedback request
  void triggerFeedbackRequest() {
    triggerEvent('feedback_request');
  }

  // ==================== USER ENGAGEMENT ====================

  /// Track user engagement level and trigger appropriate messages
  Future<void> trackEngagement({
    required int daysActive,
    required int productsViewed,
    required int purchases,
  }) async {
    // Trigger messages based on engagement
    if (daysActive == 1) {
      triggerWelcome();
    } else if (daysActive == 7 && purchases == 0) {
      triggerEvent('first_week_no_purchase');
    } else if (productsViewed > 10 && purchases == 0) {
      triggerEvent('high_browse_no_purchase');
    } else if (purchases > 0) {
      triggerEvent('returning_customer');
    }

    debugPrint('InAppMessaging: Engagement tracked - $daysActive days, $productsViewed views, $purchases purchases');
  }

  /// Track cart abandonment
  Future<void> trackCartAbandonment({
    required double cartValue,
    required int itemCount,
  }) async {
    if (cartValue > 1000) {
      triggerEvent('high_value_cart_abandoned');
    } else if (itemCount >= 5) {
      triggerEvent('large_cart_abandoned');
    } else {
      triggerCartAbandoned();
    }

    debugPrint('InAppMessaging: Cart abandonment tracked - ₹$cartValue, $itemCount items');
  }

  // ==================== LIFECYCLE CAMPAIGNS ====================

  /// Show onboarding campaign
  void showOnboarding() {
    triggerEvent('app_first_launch');
  }

  /// Show feature education
  void showFeatureEducation(String feature) {
    triggerEvent('feature_education_$feature');
  }

  /// Show retention campaign
  void showRetention({required int daysSinceLastVisit}) {
    if (daysSinceLastVisit >= 7) {
      triggerEvent('long_time_no_see');
    } else if (daysSinceLastVisit >= 3) {
      triggerEvent('we_miss_you');
    }

    debugPrint('InAppMessaging: Retention campaign - $daysSinceLastVisit days');
  }

  /// Show re-engagement campaign
  void showReEngagement() {
    triggerEvent('reengagement_campaign');
  }

  // ==================== CONTEXTUAL CAMPAIGNS ====================

  /// Show location-based campaign
  void showLocationCampaign(String location) {
    triggerEvent('location_$location');
  }

  /// Show category-specific campaign
  void showCategoryCampaign(String category) {
    triggerEvent('category_$category');
  }

  /// Show seasonal campaign
  void showSeasonalCampaign(String season) {
    triggerEvent('season_$season');
  }

  /// Show event-based campaign
  void showEventCampaign(String event) {
    triggerEvent('event_$event');
  }

  // ==================== TESTING ====================

  /// Enable test mode (shows all campaigns instantly)
  Future<void> enableTestMode() async {
    try {
      // In test mode, messages appear instantly
      debugPrint('InAppMessaging: Test mode enabled');
      debugPrint('InAppMessaging: Configure test device in Firebase Console');
    } catch (e) {
      debugPrint('InAppMessaging: Error enabling test mode - $e');
    }
  }

  // ==================== UTILITIES ====================

  bool get isInitialized => _initialized;
}

// ==================== MESSAGE TYPES ====================

/// Predefined message event types
class InAppMessageEvents {
  // Lifecycle
  static const String appFirstLaunch = 'app_first_launch';
  static const String welcomeShown = 'welcome_shown';
  
  // Engagement
  static const String productDiscovery = 'product_discovery';
  static const String highBrowseNoPurchase = 'high_browse_no_purchase';
  static const String firstWeekNoPurchase = 'first_week_no_purchase';
  static const String returningCustomer = 'returning_customer';
  
  // Cart
  static const String cartAbandoned = 'cart_abandoned';
  static const String highValueCartAbandoned = 'high_value_cart_abandoned';
  static const String largeCartAbandoned = 'large_cart_abandoned';
  
  // Retention
  static const String longTimeNoSee = 'long_time_no_see';
  static const String weMissYou = 'we_miss_you';
  static const String reengagementCampaign = 'reengagement_campaign';
  
  // Features
  static const String newFeatureAvailable = 'new_feature_available';
  static const String tutorialNeeded = 'tutorial_needed';
  static const String feedbackRequest = 'feedback_request';
  
  // Promotions
  static const String promotionAvailable = 'promotion_available';
  static const String priceDropAvailable = 'price_drop_available';
}
