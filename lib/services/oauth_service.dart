import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/safe_google_sign_in.dart';
import 'dart:io' show Platform;

/// Enhanced authentication service with OAuth support
class OAuthService {
  static final OAuthService _instance = OAuthService._internal();
  factory OAuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Safe Google Sign-In instance
  final SafeGoogleSignIn _googleSignIn = SafeGoogleSignIn();

  OAuthService._internal();

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('OAuthService: Starting Google Sign-In...');

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        return await _auth.signInWithPopup(googleProvider);
      } else {
        final googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          debugPrint('OAuthService: Google Sign-In cancelled by user');
          return null;
        }

        final tokens = await SafeGoogleSignIn.getAuthTokens(googleUser);

        final credential = GoogleAuthProvider.credential(
          accessToken: tokens['accessToken'],
          idToken: tokens['idToken'],
        );

        final userCredential = await _auth.signInWithCredential(credential);

        await _createOrUpdateOAuthProfile(
          userCredential.user!,
          provider: 'google',
          displayName: googleUser.displayName,
          email: googleUser.email,
          photoUrl: googleUser.photoUrl,
        );

        return userCredential;
      }
    } catch (e) {
      debugPrint('OAuthService: Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      if (kIsWeb || (!Platform.isIOS && !Platform.isMacOS)) {
        throw Exception(
            'Sign in with Apple is only available on iOS, macOS, and Web');
      }

      debugPrint('OAuthService: Starting Apple Sign-In...');

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      await _createOrUpdateOAuthProfile(
        userCredential.user!,
        provider: 'apple',
        displayName: appleCredential.givenName != null &&
                appleCredential.familyName != null
            ? '${appleCredential.givenName} ${appleCredential.familyName}'
            : null,
        email: appleCredential.email,
      );

      return userCredential;
    } catch (e) {
      debugPrint('OAuthService: Apple Sign-In error: $e');
      rethrow;
    }
  }

  /// Create or update OAuth user profile
  Future<void> _createOrUpdateOAuthProfile(
    User user, {
    required String provider,
    String? displayName,
    String? email,
    String? photoUrl,
  }) async {
    try {
      final uid = user.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        await _firestore.collection('users').doc(uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
          'oauthProvider': provider,
          'photoUrl': photoUrl ?? user.photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final newProfile = UserModel(
          uid: uid,
          email: email ?? user.email ?? '',
          fullName: displayName ?? user.displayName ?? 'User',
          mobileNo: user.phoneNumber ?? '',
          role: UserRole.farmer, // Default role for OAuth signup
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final profileData = newProfile.toMap();
        profileData['oauthProvider'] = provider;
        profileData['photoUrl'] = photoUrl ?? user.photoURL;
        profileData['lastLogin'] = FieldValue.serverTimestamp();

        await _firestore.collection('users').doc(uid).set(profileData);
      }
    } catch (e) {
      debugPrint('OAuthService: Error creating/updating profile: $e');
      rethrow;
    }
  }

  /// Sign out from all OAuth providers
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('OAuthService: Error signing out: $e');
      rethrow;
    }
  }

  /// Link account with Google
  Future<void> linkWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final tokens = await SafeGoogleSignIn.getAuthTokens(googleUser);

      final credential = GoogleAuthProvider.credential(
        accessToken: tokens['accessToken'],
        idToken: tokens['idToken'],
      );

      await _auth.currentUser?.linkWithCredential(credential);
    } catch (e) {
      debugPrint('OAuthService: Error linking with Google: $e');
      rethrow;
    }
  }
}
