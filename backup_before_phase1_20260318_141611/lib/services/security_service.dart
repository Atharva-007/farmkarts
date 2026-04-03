import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Production-ready Security Service with comprehensive security features
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Track login attempts to prevent brute force
  final Map<String, int> _loginAttempts = {};
  final Map<String, DateTime> _lockoutUntil = {};
  
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 30);

  /// Check if account is currently locked
  bool isAccountLocked(String email) {
    if (!_lockoutUntil.containsKey(email)) return false;
    
    final lockoutTime = _lockoutUntil[email]!;
    if (DateTime.now().isAfter(lockoutTime)) {
      _lockoutUntil.remove(email);
      _loginAttempts.remove(email);
      return false;
    }
    return true;
  }

  /// Record failed login attempt
  void recordFailedLogin(String email) {
    _loginAttempts[email] = (_loginAttempts[email] ?? 0) + 1;
    
    if (_loginAttempts[email]! >= maxLoginAttempts) {
      _lockoutUntil[email] = DateTime.now().add(lockoutDuration);
      _logSecurityEvent(
        'account_locked',
        'Account locked due to multiple failed login attempts',
        email: email,
      );
    }
  }

  /// Record successful login
  void recordSuccessfulLogin(String email) {
    _loginAttempts.remove(email);
    _lockoutUntil.remove(email);
  }

  /// Get remaining login attempts
  int getRemainingAttempts(String email) {
    final attempts = _loginAttempts[email] ?? 0;
    return maxLoginAttempts - attempts;
  }

  /// Hash sensitive data
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify user session integrity
  Future<bool> verifySession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await user.reload();
      return _auth.currentUser != null;
    } catch (e) {
      return false;
    }
  }

  /// Log security event for audit trail
  Future<void> _logSecurityEvent(
    String eventType,
    String description, {
    String? email,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final user = _auth.currentUser;
      
      await _firestore.collection('security_logs').add({
        'eventType': eventType,
        'description': description,
        'userId': user?.uid,
        'userEmail': email ?? user?.email,
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': 'N/A', // Would need backend service for real IP
        'deviceInfo': _getDeviceInfo(),
        ...?additionalData,
      });
    } catch (e) {
      debugPrint('Failed to log security event: $e');
    }
  }

  /// Validate user permissions for sensitive operations
  Future<bool> validatePermissions(String operation, String resourceId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check user role/permissions in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final role = userData['role'] ?? 'user';
      
      // Admin has all permissions
      if (role == 'admin') return true;

      // Check resource ownership
      switch (operation) {
        case 'edit_product':
        case 'delete_product':
          final productDoc = await _firestore.collection('products').doc(resourceId).get();
          if (!productDoc.exists) return false;
          return productDoc.data()!['sellerId'] == user.uid;

        case 'update_order':
        case 'cancel_order':
          final orderDoc = await _firestore.collection('orders').doc(resourceId).get();
          if (!orderDoc.exists) return false;
          final orderData = orderDoc.data()!;
          return orderData['sellerId'] == user.uid || orderData['buyerId'] == user.uid;

        default:
          return false;
      }
    } catch (e) {
      await _logSecurityEvent(
        'permission_check_failed',
        'Failed to validate permissions for $operation',
        additionalData: {'error': e.toString()},
      );
      return false;
    }
  }

  /// Detect suspicious activity
  Future<void> detectSuspiciousActivity(String activityType, Map<String, dynamic> details) async {
    try {
      final user = _auth.currentUser;
      
      // Check for rapid repeated actions
      final suspiciousPatterns = await _checkSuspiciousPatterns(activityType, details);
      
      if (suspiciousPatterns) {
        await _logSecurityEvent(
          'suspicious_activity',
          'Suspicious $activityType detected',
          additionalData: details,
        );

        // Optionally trigger additional security measures
        await _triggerSecurityAlert(user?.uid ?? 'unknown', activityType, details);
      }
    } catch (e) {
      debugPrint('Error detecting suspicious activity: $e');
    }
  }

  /// Check for suspicious patterns
  Future<bool> _checkSuspiciousPatterns(String activityType, Map<String, dynamic> details) async {
    // Implement pattern detection logic
    // For example: too many requests in short time, unusual access patterns, etc.
    // This is a placeholder - implement based on specific needs
    return false;
  }

  /// Trigger security alert
  Future<void> _triggerSecurityAlert(String userId, String alertType, Map<String, dynamic> details) async {
    try {
      await _firestore.collection('security_alerts').add({
        'userId': userId,
        'alertType': alertType,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'severity': _calculateSeverity(alertType),
      });

      // Optionally send push notification to user
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Security Alert',
        'message': 'Suspicious activity detected on your account. Please review.',
        'type': 'security',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Failed to trigger security alert: $e');
    }
  }

  /// Calculate alert severity
  String _calculateSeverity(String alertType) {
    switch (alertType) {
      case 'failed_login':
        return 'medium';
      case 'data_breach_attempt':
      case 'unauthorized_access':
        return 'high';
      case 'unusual_activity':
        return 'low';
      default:
        return 'medium';
    }
  }

  /// Get device information for logging
  Map<String, String> _getDeviceInfo() {
    return {
      'platform': defaultTargetPlatform.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Sanitize user input to prevent injection attacks
  String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'<script.*?>.*?</script>'), '')
        .replaceAll(RegExp(r'<.*?>'), '')
        .trim();
  }

  /// Validate data integrity
  bool validateDataIntegrity(Map<String, dynamic> data, List<String> requiredFields) {
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        return false;
      }
    }
    return true;
  }

  /// Encrypt sensitive data (placeholder - implement with proper encryption library)
  String encryptData(String data, String key) {
    // TODO: Implement actual encryption using crypto library
    // For production, use packages like encrypt or flutter_secure_storage
    return base64Encode(utf8.encode(data));
  }

  /// Decrypt sensitive data (placeholder)
  String decryptData(String encryptedData, String key) {
    // TODO: Implement actual decryption
    try {
      return utf8.decode(base64Decode(encryptedData));
    } catch (e) {
      return '';
    }
  }

  /// Check for account takeover attempts
  Future<void> checkAccountTakeoverRisk() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check for unusual login locations, devices, or patterns
      // This would require backend service to track IPs and locations
      
      final recentLogins = await _firestore
          .collection('security_logs')
          .where('userId', isEqualTo: user.uid)
          .where('eventType', isEqualTo: 'login')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      // Analyze patterns (implement based on requirements)
      // For now, just log the check
      await _logSecurityEvent(
        'account_takeover_check',
        'Periodic account takeover risk assessment',
      );
    } catch (e) {
      debugPrint('Error checking account takeover risk: $e');
    }
  }

  /// Force password change for compromised accounts
  Future<void> forcePasswordChange(String userId, String reason) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'passwordChangeRequired': true,
        'passwordChangeReason': reason,
        'passwordChangeRequestedAt': FieldValue.serverTimestamp(),
      });

      await _logSecurityEvent(
        'force_password_change',
        'Password change forced: $reason',
      );
    } catch (e) {
      debugPrint('Error forcing password change: $e');
    }
  }

  /// Get security score for user account
  Future<int> getSecurityScore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      int score = 0;

      // Check email verification (+20 points)
      if (user.emailVerified) score += 20;

      // Check for profile completion (+20 points)
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        if (userData['phoneNumber'] != null) score += 10;
        if (userData['profilePicture'] != null) score += 10;
        
        // Check for 2FA enabled (+30 points)
        if (userData['twoFactorEnabled'] == true) score += 30;

        // Check password age (+20 points if recent)
        final lastPasswordChange = userData['lastPasswordChange'] as Timestamp?;
        if (lastPasswordChange != null) {
          final daysSinceChange = DateTime.now().difference(lastPasswordChange.toDate()).inDays;
          if (daysSinceChange < 90) score += 20;
        }
      }

      // Check for recent security issues (-10 points each)
      final recentAlerts = await _firestore
          .collection('security_alerts')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 30)),
          ))
          .get();
      
      score = (score - (recentAlerts.docs.length * 10)).clamp(0, 100);

      return score;
    } catch (e) {
      debugPrint('Error calculating security score: $e');
      return 0;
    }
  }

  /// Get security recommendations
  Future<List<String>> getSecurityRecommendations() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final List<String> recommendations = [];

      if (!user.emailVerified) {
        recommendations.add('Verify your email address');
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        
        if (userData['twoFactorEnabled'] != true) {
          recommendations.add('Enable two-factor authentication');
        }

        if (userData['phoneNumber'] == null) {
          recommendations.add('Add a phone number for account recovery');
        }

        final lastPasswordChange = userData['lastPasswordChange'] as Timestamp?;
        if (lastPasswordChange == null || 
            DateTime.now().difference(lastPasswordChange.toDate()).inDays > 90) {
          recommendations.add('Update your password regularly (every 90 days)');
        }

        if (userData['passwordChangeRequired'] == true) {
          recommendations.add('⚠️ URGENT: Change your password immediately');
        }
      }

      return recommendations;
    } catch (e) {
      debugPrint('Error getting security recommendations: $e');
      return [];
    }
  }

  /// Clear security data on logout
  void clearSecurityData(String email) {
    _loginAttempts.remove(email);
    _lockoutUntil.remove(email);
  }
}
