import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'dart:io' show Platform;

/// Enhanced authentication service with OAuth support
class OAuthService {
  static final OAuthService _instance = OAuthService._internal();
  factory OAuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  
  // Facebook Auth instance (Disabled in pubspec.yaml)
  // final FacebookAuth _facebookAuth = FacebookAuth.instance;

  OAuthService._internal() {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _googleSignIn.initialize();
    } catch (e) {
      debugPrint('OAuthService: Initialization error: $e');
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('OAuthService: Starting Google Sign-In...');
      
      if (kIsWeb) {
        // Web-specific Google Sign-In
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile Google Sign-In
        final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
        
        if (googleUser == null) {
          debugPrint('OAuthService: Google Sign-In cancelled by user');
          return null;
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

  /// Sign in with Facebook
  Future<UserCredential?> signInWithFacebook() async {
    return null; // Disabled
  }

  /// Sign in with Apple (iOS/macOS/Web only)
  Future<UserCredential?> signInWithApple() async {
    try {
      if (kIsWeb || (!Platform.isIOS && !Platform.isMacOS)) {
        throw Exception('Sign in with Apple is only available on iOS, macOS, and Web');
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
      
      // Create or update user profile
      await _createOrUpdateOAuthProfile(
        userCredential.user!,
        provider: 'apple',
        displayName: appleCredential.givenName != null && appleCredential.familyName != null
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
        // Update existing profile
        await _firestore.collection('users').doc(uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
          'oauthProvider': provider,
          'photoUrl': photoUrl ?? user.photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('OAuthService: Updated existing user profile');
      } else {
        // Create new profile with default farmer role
        final newProfile = FarmerModel(
          uid: uid,
          email: email ?? user.email ?? '',
          fullName: displayName ?? user.displayName ?? 'User',
          mobileNo: user.phoneNumber ?? '',
          acresLand: 0.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final profileData = newProfile.toMap();
        profileData['oauthProvider'] = provider;
        profileData['photoUrl'] = photoUrl ?? user.photoURL;
        profileData['lastLogin'] = FieldValue.serverTimestamp();
        
        await _firestore.collection('users').doc(uid).set(profileData);
        debugPrint('OAuthService: Created new user profile');
      }
    } catch (e) {
      debugPrint('OAuthService: Error creating/updating profile: $e');
      rethrow;
    }
  }

  /// Sign out from all OAuth providers
  Future<void> signOut() async {
    try {
      // Sign out from Google
      // In version 7.0.0+, we don't have isSignedIn() anymore, but we can call signOut()
      await _googleSignIn.signOut();
      
      // Sign out from Firebase
      await _auth.signOut();
      
      debugPrint('OAuthService: Signed out successfully');
    } catch (e) {
      debugPrint('OAuthService: Error signing out: $e');
      rethrow;
    }
  }

  /// Check if user is signed in with OAuth
  bool isOAuthUser() {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    return user.providerData.any((info) => 
      info.providerId == 'google.com' || 
      info.providerId == 'facebook.com' ||
      info.providerId == 'apple.com'
    );
  }

  /// Get current OAuth provider
  String? getCurrentOAuthProvider() {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    for (final info in user.providerData) {
      if (info.providerId == 'google.com') return 'Google';
      if (info.providerId == 'facebook.com') return 'Facebook';
      if (info.providerId == 'apple.com') return 'Apple';
    }
    
    return null;
  }

  /// Link current account with Google
  Future<void> linkWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return;
      
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      
      final String? accessToken = await _googleSignIn.authorizationClient.getAccessToken();
      
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: googleAuth.idToken,
      );
      
      await _auth.currentUser?.linkWithCredential(credential);
      debugPrint('OAuthService: Account linked with Google');
    } catch (e) {
      debugPrint('OAuthService: Error linking with Google: $e');
      rethrow;
    }
  }

  /// Link current account with Facebook
  Future<void> linkWithFacebook() async {
    // Disabled
  }

  /// Unlink OAuth provider
  Future<void> unlinkProvider(String providerId) async {
    try {
      await _auth.currentUser?.unlink(providerId);
      debugPrint('OAuthService: Unlinked $providerId');
    } catch (e) {
      debugPrint('OAuthService: Error unlinking provider: $e');
      rethrow;
    }
  }

  /// Re-authenticate with OAuth provider
  Future<void> reauthenticateWithProvider(String provider) async {
    try {
      UserCredential? credential;
      
      switch (provider.toLowerCase()) {
        case 'google':
          credential = await signInWithGoogle();
          break;
        case 'facebook':
          credential = await signInWithFacebook();
          break;
        case 'apple':
          credential = await signInWithApple();
          break;
        default:
          throw Exception('Unknown provider: $provider');
      }
      
      if (credential != null) {
        debugPrint('OAuthService: Re-authenticated with $provider');
      }
    } catch (e) {
      debugPrint('OAuthService: Error re-authenticating: $e');
      rethrow;
    }
  }
}
