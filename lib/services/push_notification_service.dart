import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Push Notification Service
/// Handles FCM push notifications for orders, chats, and product updates
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  String? _fcmToken;

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request notification permissions (iOS)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('PushNotification: Permission status - ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // Initialize local notifications
        await _initializeLocalNotifications();

        // Get FCM token
        _fcmToken = await _firebaseMessaging.getToken();
        debugPrint('PushNotification: FCM Token - $_fcmToken');

        // Save token to Firestore
        await _saveFCMToken(_fcmToken);

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);

        // Configure message handlers
        await _configureMessageHandlers();

        _initialized = true;
        debugPrint('PushNotification: Service initialized successfully');
      } else {
        debugPrint('PushNotification: Permission denied');
      }
    } catch (e) {
      debugPrint('PushNotification: Initialization error - $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    debugPrint('PushNotification: Local notifications initialized');
  }

  /// Configure message handlers for foreground, background, and terminated states
  Future<void> _configureMessageHandlers() async {
    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background/terminated messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // Check for initial message (app opened from terminated state)
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpen(initialMessage);
    }

    debugPrint('PushNotification: Message handlers configured');
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String? token) async {
    if (token == null) return;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('PushNotification: FCM token saved for user $userId');
      }
    } catch (e) {
      debugPrint('PushNotification: Error saving FCM token - $e');
    }
  }

  // ==================== MESSAGE HANDLERS ====================

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('PushNotification: Foreground message - ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  /// Handle notification opened (background/terminated)
  void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('PushNotification: Notification opened - ${message.messageId}');
    
    final data = message.data;
    final type = data['type'] as String?;

    // Navigate based on notification type
    switch (type) {
      case 'order':
        _navigateToOrder(data['orderId']);
        break;
      case 'chat':
        _navigateToChat(data['chatId']);
        break;
      case 'product':
        _navigateToProduct(data['productId']);
        break;
      default:
        debugPrint('PushNotification: Unknown notification type - $type');
    }
  }

  /// Handle notification tap from local notification
  void _handleNotificationTap(NotificationResponse response) {
    debugPrint('PushNotification: Local notification tapped - ${response.payload}');
    
    if (response.payload != null) {
      final parts = response.payload!.split('|');
      if (parts.length >= 2) {
        final type = parts[0];
        final id = parts[1];

        switch (type) {
          case 'order':
            _navigateToOrder(id);
            break;
          case 'chat':
            _navigateToChat(id);
            break;
          case 'product':
            _navigateToProduct(id);
            break;
        }
      }
    }
  }

  // ==================== LOCAL NOTIFICATION ====================

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      channelDescription: 'Default notification channel for FarmKarts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Create payload for navigation
    final type = message.data['type'] as String? ?? '';
    final id = message.data['orderId'] ?? message.data['chatId'] ?? message.data['productId'] ?? '';
    final payload = '$type|$id';

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: payload,
    );

    debugPrint('PushNotification: Local notification shown');
  }

  // ==================== NAVIGATION ====================

  void _navigateToOrder(String? orderId) {
    if (orderId != null) {
      debugPrint('PushNotification: Navigate to order - $orderId');
      // TODO: Implement navigation to order detail page
      // Navigator.pushNamed(context, '/order-detail', arguments: orderId);
    }
  }

  void _navigateToChat(String? chatId) {
    if (chatId != null) {
      debugPrint('PushNotification: Navigate to chat - $chatId');
      // TODO: Implement navigation to chat page
      // Navigator.pushNamed(context, '/chat', arguments: chatId);
    }
  }

  void _navigateToProduct(String? productId) {
    if (productId != null) {
      debugPrint('PushNotification: Navigate to product - $productId');
      // TODO: Implement navigation to product detail page
      // Navigator.pushNamed(context, '/product-detail', arguments: productId);
    }
  }

  // ==================== SUBSCRIPTION MANAGEMENT ====================

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('PushNotification: Subscribed to topic - $topic');
    } catch (e) {
      debugPrint('PushNotification: Error subscribing to topic - $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('PushNotification: Unsubscribed from topic - $topic');
    } catch (e) {
      debugPrint('PushNotification: Error unsubscribing from topic - $e');
    }
  }

  /// Subscribe to user-specific topics (categories, location, etc.)
  Future<void> subscribeToUserTopics({
    List<String>? categories,
    String? location,
    bool newProducts = true,
    bool priceDrops = true,
  }) async {
    // Subscribe to categories
    if (categories != null) {
      for (final category in categories) {
        await subscribeToTopic('category_$category');
      }
    }

    // Subscribe to location-based notifications
    if (location != null) {
      await subscribeToTopic('location_$location');
    }

    // Subscribe to general topics
    if (newProducts) {
      await subscribeToTopic('new_products');
    }
    if (priceDrops) {
      await subscribeToTopic('price_drops');
    }

    debugPrint('PushNotification: User topics subscribed');
  }

  // ==================== SEND NOTIFICATION ====================

  /// Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null) {
        // Note: Actual sending requires server-side implementation
        // This is a placeholder for the notification payload structure
        final notification = {
          'to': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
        };

        debugPrint('PushNotification: Notification payload - $notification');
        // TODO: Send to FCM server via Cloud Functions
      } else {
        debugPrint('PushNotification: No FCM token for user $userId');
      }
    } catch (e) {
      debugPrint('PushNotification: Error sending notification - $e');
    }
  }

  /// Send order update notification
  Future<void> sendOrderNotification({
    required String userId,
    required String orderId,
    required String status,
  }) async {
    String title = 'Order Update';
    String body = '';

    switch (status) {
      case 'confirmed':
        body = 'Your order #$orderId has been confirmed';
        break;
      case 'shipped':
        body = 'Your order #$orderId has been shipped';
        break;
      case 'delivered':
        body = 'Your order #$orderId has been delivered';
        break;
      case 'cancelled':
        body = 'Your order #$orderId has been cancelled';
        break;
      default:
        body = 'Order #$orderId status: $status';
    }

    await sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      data: {
        'type': 'order',
        'orderId': orderId,
        'status': status,
      },
    );
  }

  /// Send chat message notification
  Future<void> sendChatNotification({
    required String userId,
    required String chatId,
    required String senderName,
    required String message,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: senderName,
      body: message,
      data: {
        'type': 'chat',
        'chatId': chatId,
      },
    );
  }

  /// Send product notification
  Future<void> sendProductNotification({
    required String userId,
    required String productId,
    required String productName,
    required String type,
  }) async {
    String body = '';

    switch (type) {
      case 'price_drop':
        body = 'Price dropped for $productName';
        break;
      case 'back_in_stock':
        body = '$productName is back in stock';
        break;
      case 'new_similar':
        body = 'New product similar to $productName';
        break;
      default:
        body = 'Update for $productName';
    }

    await sendNotificationToUser(
      userId: userId,
      title: 'Product Update',
      body: body,
      data: {
        'type': 'product',
        'productId': productId,
        'notificationType': type,
      },
    );
  }

  // ==================== UTILITIES ====================

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      debugPrint('PushNotification: FCM token deleted');
    } catch (e) {
      debugPrint('PushNotification: Error deleting token - $e');
    }
  }
}

// ==================== BACKGROUND MESSAGE HANDLER ====================

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('PushNotification: Background message - ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
  
  // Handle background notification
  // You can update local database, show notification, etc.
}
