import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/user_role.dart';

/// Production-ready multi-provider authentication service
/// Supports: Email/Password, Phone, Google Sign-In
/// Optimized for 10,000+ concurrent users
class MultiAuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MultiAuthService() {
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize();
    } catch (e) {
      debugPrint('Google Sign-In initialization error: $e');
    }
  }

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  String? _verificationId;
  int? _resendToken;

  // ==================== EMAIL/PASSWORD AUTHENTICATION ====================

  /// Sign in with email or mobile (checks both)
  Future<UserCredential?> signInWithEmailOrMobile(String identifier, String password) async {
    try {
      // Check if identifier is email or mobile
      if (_isEmail(identifier)) {
        return await _auth.signInWithEmailAndPassword(
          email: identifier,
          password: password,
        );
      } else {
        // Mobile number - convert to email format
        final email = _mobileToEmail(identifier);
        return await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  /// Register with email/password
  Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? mobile,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _createUserProfile(
          uid: credential.user!.uid,
          email: email,
          name: name,
          role: role,
          mobile: mobile,
        );

        await credential.user!.updateDisplayName(name);
      }

      return credential;
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    }
  }

  /// Register with mobile number (creates email from mobile)
  Future<UserCredential?> registerWithMobile({
    required String mobile,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      final email = _mobileToEmail(mobile);
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _createUserProfile(
          uid: credential.user!.uid,
          email: email,
          name: name,
          role: role,
          mobile: mobile,
        );

        await credential.user!.updateDisplayName(name);
      }

      return credential;
    } catch (e) {
      debugPrint('Mobile registration error: $e');
      rethrow;
    }
  }

  // ==================== PHONE AUTHENTICATION ====================

  /// Send OTP to phone number
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onVerificationFailed,
    required Function(PhoneAuthCredential) onAutoVerify,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          onAutoVerify(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onVerificationFailed(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent('OTP sent successfully');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      debugPrint('Send OTP error: $e');
      onVerificationFailed(e.toString());
    }
  }

  /// Verify OTP and sign in
  Future<UserCredential?> verifyOTP({
    required String otp,
    required String name,
    required UserRole role,
    String? phoneNumber,
  }) async {
    try {
      if (_verificationId == null) {
        throw Exception('Verification ID is null. Please request OTP first.');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user profile
      if (userCredential.user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          await _createUserProfile(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            name: name,
            role: role,
            mobile: phoneNumber ?? userCredential.user!.phoneNumber,
          );
        }
      }

      return userCredential;
    } catch (e) {
      debugPrint('Verify OTP error: $e');
      rethrow;
    }
  }

  // ==================== GOOGLE SIGN-IN ====================

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle({
    required String name,
    required UserRole role,
  }) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      
      if (googleUser == null) {
        return null; // User cancelled
      }

      // In version 7.0.0+, authentication property is synchronous
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // In version 7.0.0+, we need to request the access token explicitly
      final String? accessToken = await _googleSignIn.authorizationClient.getAccessToken();

      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user profile
      if (userCredential.user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          await _createUserProfile(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            name: userCredential.user!.displayName ?? name,
            role: role,
            photoUrl: userCredential.user!.photoURL,
          );
        }
      }

      return userCredential;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      rethrow;
    }
  }

  // ==================== PASSWORD RESET ====================

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Password reset error: $e');
      rethrow;
    }
  }

  /// Reset password for mobile users
  Future<void> resetPasswordForMobile(String mobile) async {
    try {
      final email = _mobileToEmail(mobile);
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Password reset error: $e');
      rethrow;
    }
  }

  // ==================== SIGN OUT ====================

  /// Sign out from all providers
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  // ==================== USER PROFILE MANAGEMENT ====================

  /// Create user profile in Firestore
  Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String name,
    required UserRole role,
    String? mobile,
    String? photoUrl,
  }) async {
    final userModel = UserModel(
      uid: uid,
      email: email,
      name: name,
      role: role,
      mobile: mobile ?? '',
      profilePicture: photoUrl ?? '',
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      isActive: true,
    );

    await _firestore
        .collection('users')
        .doc(uid)
        .set(userModel.toMap(), SetOptions(merge: true));
  }

  /// Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Get user profile error: $e');
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore.collection('users').doc(uid).update(updates);
      notifyListeners();
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Check if string is email
  bool _isEmail(String identifier) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(identifier);
  }

  /// Convert mobile number to email format
  String _mobileToEmail(String mobile) {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^\d]'), '');
    return '$cleanMobile@farmkarts.app';
  }

  /// Get error message from FirebaseAuthException
  String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email/mobile';
        case 'wrong-password':
          return 'Incorrect password';
        case 'email-already-in-use':
          return 'This email/mobile is already registered';
        case 'weak-password':
          return 'Password should be at least 6 characters';
        case 'invalid-email':
          return 'Invalid email format';
        case 'user-disabled':
          return 'This account has been disabled';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled';
        case 'invalid-verification-code':
          return 'Invalid OTP code';
        case 'invalid-verification-id':
          return 'Invalid verification. Please request new OTP';
        default:
          return error.message ?? 'Authentication failed';
      }
    }
    return error.toString();
  }

  /// Check if user exists
  Future<bool> userExists(String identifier) async {
    try {
      if (_isEmail(identifier)) {
        final methods = await _auth.fetchSignInMethodsForEmail(identifier);
        return methods.isNotEmpty;
      } else {
        final email = _mobileToEmail(identifier);
        final methods = await _auth.fetchSignInMethodsForEmail(email);
        return methods.isNotEmpty;
      }
    } catch (e) {
      return false;
    }
  }

  /// Link phone number to existing account
  Future<void> linkPhoneNumber({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      if (_verificationId == null) {
        throw Exception('Verification ID is null');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await currentUser?.linkWithCredential(credential);
      notifyListeners();
    } catch (e) {
      debugPrint('Link phone error: $e');
      rethrow;
    }
  }

  /// Unlink phone number
  Future<void> unlinkPhoneNumber() async {
    try {
      await currentUser?.unlink('phone');
      notifyListeners();
    } catch (e) {
      debugPrint('Unlink phone error: $e');
      rethrow;
    }
  }
}
