import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Analytics Service - Track user behavior and app events
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Initialize analytics
  Future<void> initialize() async {
    debugPrint('AnalyticsService: Initialized');
    await _analytics.setAnalyticsCollectionEnabled(true);
  }

  // ==================== USER EVENTS ====================

  /// Track user login
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
    debugPrint('Analytics: Login - $method');
  }

  /// Track user sign up
  Future<void> logSignUp(String method, String role) async {
    await _analytics.logSignUp(signUpMethod: method);
    await _analytics.logEvent(
      name: 'user_role_selected',
      parameters: {'role': role},
    );
    debugPrint('Analytics: Sign Up - $method as $role');
  }

  /// Set user properties
  Future<void> setUserProperties({
    required String userId,
    required String role,
    String? location,
  }) async {
    await _analytics.setUserId(id: userId);
    await _analytics.setUserProperty(name: 'user_role', value: role);
    if (location != null) {
      await _analytics.setUserProperty(name: 'location', value: location);
    }
    debugPrint('Analytics: User properties set for $userId');
  }

  // ==================== PRODUCT EVENTS ====================

  /// Track product view
  Future<void> logProductView({
    required String productId,
    required String productName,
    required String category,
    required double price,
  }) async {
    await _analytics.logViewItem(
      currency: 'INR',
      value: price,
      items: [
        AnalyticsEventItem(
          itemId: productId,
          itemName: productName,
          itemCategory: category,
          price: price,
        ),
      ],
    );
    debugPrint('Analytics: Product viewed - $productName');
  }

  /// Track product search
  Future<void> logSearch(String searchTerm, {String? category}) async {
    await _analytics.logSearch(
      searchTerm: searchTerm,
      parameters: category != null ? {'category': category} : null,
    );
    debugPrint('Analytics: Search - $searchTerm');
  }

  /// Track product share
  Future<void> logProductShare({
    required String productId,
    required String productName,
    required String method,
  }) async {
    await _analytics.logShare(
      contentType: 'product',
      itemId: productId,
      method: method,
    );
    debugPrint('Analytics: Product shared - $productName via $method');
  }

  // ==================== MARKETPLACE EVENTS ====================

  /// Track add to cart
  Future<void> logAddToCart({
    required String productId,
    required String productName,
    required String category,
    required double price,
    required double quantity,
  }) async {
    await _analytics.logAddToCart(
      currency: 'INR',
      value: price * quantity,
      items: [
        AnalyticsEventItem(
          itemId: productId,
          itemName: productName,
          itemCategory: category,
          price: price,
          quantity: quantity.toInt(),
        ),
      ],
    );
    debugPrint('Analytics: Added to cart - $productName');
  }

  /// Track remove from cart
  Future<void> logRemoveFromCart({
    required String productId,
    required String productName,
    required double price,
  }) async {
    await _analytics.logRemoveFromCart(
      currency: 'INR',
      value: price,
      items: [
        AnalyticsEventItem(
          itemId: productId,
          itemName: productName,
          price: price,
        ),
      ],
    );
    debugPrint('Analytics: Removed from cart - $productName');
  }

  /// Track add to wishlist
  Future<void> logAddToWishlist({
    required String productId,
    required String productName,
    required double price,
  }) async {
    await _analytics.logAddToWishlist(
      currency: 'INR',
      value: price,
      items: [
        AnalyticsEventItem(
          itemId: productId,
          itemName: productName,
          price: price,
        ),
      ],
    );
    debugPrint('Analytics: Added to wishlist - $productName');
  }

  // ==================== PURCHASE EVENTS ====================

  /// Track purchase initiation
  Future<void> logBeginCheckout({
    required double totalValue,
    required List<Map<String, dynamic>> items,
  }) async {
    await _analytics.logBeginCheckout(
      currency: 'INR',
      value: totalValue,
      items: items
          .map((item) => AnalyticsEventItem(
                itemId: item['id'],
                itemName: item['name'],
                price: item['price'],
                quantity: item['quantity'],
              ))
          .toList(),
    );
    debugPrint('Analytics: Begin checkout - ₹$totalValue');
  }

  /// Track purchase completion
  Future<void> logPurchase({
    required String transactionId,
    required double totalValue,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    await _analytics.logPurchase(
      currency: 'INR',
      value: totalValue,
      transactionId: transactionId,
      items: items
          .map((item) => AnalyticsEventItem(
                itemId: item['id'],
                itemName: item['name'],
                price: item['price'],
                quantity: item['quantity'],
              ))
          .toList(),
    );

    await _analytics.logEvent(
      name: 'payment_method_used',
      parameters: {
        'method': paymentMethod,
        'amount': totalValue,
      },
    );

    debugPrint('Analytics: Purchase - ₹$totalValue via $paymentMethod');
  }

  /// Track refund
  Future<void> logRefund({
    required String transactionId,
    required double refundAmount,
  }) async {
    await _analytics.logRefund(
      currency: 'INR',
      value: refundAmount,
      transactionId: transactionId,
    );
    debugPrint('Analytics: Refund - ₹$refundAmount');
  }

  // ==================== CHAT EVENTS ====================

  /// Track chat started
  Future<void> logChatStarted({
    required String productId,
    required String sellerId,
  }) async {
    await _analytics.logEvent(
      name: 'chat_started',
      parameters: {
        'product_id': productId,
        'seller_id': sellerId,
      },
    );
    debugPrint('Analytics: Chat started');
  }

  /// Track bid placed
  Future<void> logBidPlaced({
    required String productId,
    required double bidAmount,
    required double quantity,
  }) async {
    await _analytics.logEvent(
      name: 'bid_placed',
      parameters: {
        'product_id': productId,
        'bid_amount': bidAmount,
        'quantity': quantity,
      },
    );
    debugPrint('Analytics: Bid placed - ₹$bidAmount');
  }

  /// Track message sent
  Future<void> logMessageSent({
    required String messageType,
    bool hasMedia = false,
  }) async {
    await _analytics.logEvent(
      name: 'message_sent',
      parameters: {
        'type': messageType,
        'has_media': hasMedia,
      },
    );
  }

  // ==================== SELLER EVENTS ====================

  /// Track product listing
  Future<void> logProductListed({
    required String productId,
    required String category,
    required double price,
  }) async {
    await _analytics.logEvent(
      name: 'product_listed',
      parameters: {
        'product_id': productId,
        'category': category,
        'price': price,
      },
    );
    debugPrint('Analytics: Product listed - $productId');
  }

  /// Track product updated
  Future<void> logProductUpdated({
    required String productId,
    required String updateType,
  }) async {
    await _analytics.logEvent(
      name: 'product_updated',
      parameters: {
        'product_id': productId,
        'update_type': updateType,
      },
    );
    debugPrint('Analytics: Product updated - $updateType');
  }

  /// Track product deleted
  Future<void> logProductDeleted({
    required String productId,
    required String reason,
  }) async {
    await _analytics.logEvent(
      name: 'product_deleted',
      parameters: {
        'product_id': productId,
        'reason': reason,
      },
    );
    debugPrint('Analytics: Product deleted - $reason');
  }

  // ==================== NAVIGATION EVENTS ====================

  /// Track screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
    debugPrint('Analytics: Screen view - $screenName');
  }

  /// Track app open
  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
    debugPrint('Analytics: App opened');
  }

  // ==================== ENGAGEMENT EVENTS ====================

  /// Track tutorial begin
  Future<void> logTutorialBegin() async {
    await _analytics.logTutorialBegin();
    debugPrint('Analytics: Tutorial begin');
  }

  /// Track tutorial complete
  Future<void> logTutorialComplete() async {
    await _analytics.logTutorialComplete();
    debugPrint('Analytics: Tutorial complete');
  }

  /// Track level up (gamification)
  Future<void> logLevelUp({
    required int level,
    String? character,
  }) async {
    await _analytics.logLevelUp(
      level: level,
      character: character,
    );
    debugPrint('Analytics: Level up - $level');
  }

  // ==================== ERROR EVENTS ====================

  /// Track error
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
  }) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        if (stackTrace != null) 'stack_trace': stackTrace,
      },
    );
    debugPrint('Analytics: Error - $errorType: $errorMessage');
  }

  // ==================== CUSTOM EVENTS ====================

  /// Log custom event
  Future<void> logCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: eventName,
      parameters:
          parameters?.map((key, value) => MapEntry(key, value as Object)),
    );
    debugPrint('Analytics: Custom event - $eventName');
  }

  // ==================== CONVERSION EVENTS ====================

  /// Track conversion milestone
  Future<void> logConversionMilestone({
    required String milestoneName,
    required double value,
  }) async {
    await _analytics.logEvent(
      name: 'conversion_milestone',
      parameters: {
        'milestone_name': milestoneName,
        'value': value,
      },
    );
    debugPrint('Analytics: Milestone - $milestoneName: $value');
  }

  /// Track user retention
  Future<void> logRetentionEvent({
    required int daysSinceInstall,
  }) async {
    await _analytics.logEvent(
      name: 'user_retention',
      parameters: {
        'days_since_install': daysSinceInstall,
      },
    );
    debugPrint('Analytics: Retention - Day $daysSinceInstall');
  }

  // ==================== SOCIAL EVENTS ====================

  /// Track social share
  Future<void> logSocialShare({
    required String platform,
    required String contentType,
  }) async {
    await _analytics.logEvent(
      name: 'social_share',
      parameters: {
        'platform': platform,
        'content_type': contentType,
      },
    );
    debugPrint('Analytics: Social share - $platform');
  }

  /// Track referral
  Future<void> logReferral({
    required String referralCode,
    required String source,
  }) async {
    await _analytics.logEvent(
      name: 'referral',
      parameters: {
        'referral_code': referralCode,
        'source': source,
      },
    );
    debugPrint('Analytics: Referral - $referralCode');
  }

  // ==================== PERFORMANCE EVENTS ====================

  /// Track page load time
  Future<void> logPageLoadTime({
    required String pageName,
    required Duration loadTime,
  }) async {
    await _analytics.logEvent(
      name: 'page_load_time',
      parameters: {
        'page_name': pageName,
        'load_time_ms': loadTime.inMilliseconds,
      },
    );
    debugPrint(
        'Analytics: Page load - $pageName: ${loadTime.inMilliseconds}ms');
  }

  /// Track API call performance
  Future<void> logApiPerformance({
    required String endpoint,
    required Duration responseTime,
    required bool success,
  }) async {
    await _analytics.logEvent(
      name: 'api_performance',
      parameters: {
        'endpoint': endpoint,
        'response_time_ms': responseTime.inMilliseconds,
        'success': success,
      },
    );
  }
}
