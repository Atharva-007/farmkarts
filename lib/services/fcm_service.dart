import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  await FCMService().showNotification(message);
}

/// Firebase Cloud Messaging Service
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize FCM service
  Future<void> initialize() async {
    try {
      // Request permission
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // Initialize local notifications
        await _initializeLocalNotifications();

        // Get FCM token
        _fcmToken = await _firebaseMessaging.getToken();
        debugPrint('FCM Token: $_fcmToken');

        // Save token to Firestore
        if (_fcmToken != null) {
          await _saveFCMToken(_fcmToken!);
        }

        // Listen to token refresh
        _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle message opened app
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );

        // Check for initial message (app opened from terminated state)
        final initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageOpenedApp(initialMessage);
        }
      }
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
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
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    const orderChannel = AndroidNotificationChannel(
      'orders',
      'Orders',
      description: 'Notifications about order updates',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    const chatChannel = AndroidNotificationChannel(
      'chats',
      'Messages',
      description: 'New chat messages',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    const generalChannel = AndroidNotificationChannel(
      'general',
      'General',
      description: 'General notifications',
      importance: Importance.defaultImportance,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(orderChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(chatChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      _fcmToken = token;
      debugPrint('FCM token saved to Firestore');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');
    showNotification(message);
  }

  /// Handle message that opened the app
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.messageId}');
    _handleNotificationAction(message.data);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    if (response.payload != null) {
      // Parse payload and navigate
      // Implementation depends on your navigation structure
    }
  }

  /// Show local notification
  Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification == null) return;

    // Determine channel based on notification type
    String channelId = 'general';
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'order':
          channelId = 'orders';
          break;
        case 'chat':
          channelId = 'chats';
          break;
      }
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'orders' ? 'Orders' : channelId == 'chats' ? 'Messages' : 'General',
      channelDescription: 'FarmKarts notifications',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: data.toString(),
    );
  }

  /// Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        debugPrint('User has no FCM token');
        return;
      }

      // Save notification to Firestore for persistence
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      // In production, call your backend API to send FCM message
      // For now, we're using Firestore notifications
      debugPrint('Notification sent to user: $userId');
      
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// Handle notification action (navigation)
  void _handleNotificationAction(Map<String, dynamic> data) {
    // Implement navigation based on notification data
    // Example:
    // if (data['type'] == 'order') {
    //   Navigator.pushNamed(context, '/order', arguments: data['orderId']);
    // }
  }

  /// Clear badge count
  Future<void> clearBadge() async {
    await _localNotifications.cancelAll();
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }
}
