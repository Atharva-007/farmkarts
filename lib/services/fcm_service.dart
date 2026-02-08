import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

/// Firebase Cloud Messaging Service (Simplified version without local notifications)
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
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

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _fcmToken = token;
      debugPrint('FCM token saved to Firestore');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    // Notification will be shown automatically by FCM
  }

  /// Handle message that opened the app
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.messageId}');
    _handleNotificationAction(message.data);
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
      debugPrint('Notification sent to user: $userId');
      
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// Handle notification action (navigation)
  void _handleNotificationAction(Map<String, dynamic> data) {
    // Implement navigation based on notification data
    debugPrint('Notification action: $data');
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
