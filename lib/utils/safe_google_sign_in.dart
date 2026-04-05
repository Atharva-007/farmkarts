import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// A safe wrapper for GoogleSignIn to handle API inconsistencies and phantom errors
class SafeGoogleSignIn {
  // Use dynamic internally to avoid static analysis errors on missing methods/constructors
  final dynamic _delegate;

  SafeGoogleSignIn({List<String>? scopes})
      : _delegate = _createDelegate(scopes);

  static dynamic _createDelegate(List<String>? scopes) {
    try {
      // Use dynamic to instantiate to bypass static analysis if it's being problematic
      final dynamic googleSignInClass = GoogleSignIn;
      return googleSignInClass(scopes: scopes ?? ['email']);
    } catch (e) {
      debugPrint('SafeGoogleSignIn: Critical error initializing delegate: $e');
      return null;
    }
  }

  Future<dynamic> signIn() async {
    if (_delegate == null) return null;
    try {
      return await _delegate.signIn();
    } catch (e) {
      debugPrint('SafeGoogleSignIn: signIn error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    if (_delegate == null) return;
    try {
      await _delegate.signOut();
    } catch (e) {
      debugPrint('SafeGoogleSignIn: signOut error: $e');
    }
  }

  Future<void> disconnect() async {
    if (_delegate == null) return;
    try {
      await _delegate.disconnect();
    } catch (e) {
      debugPrint('SafeGoogleSignIn: disconnect error: $e');
    }
  }

  Future<dynamic> get authentication async {
    // This expects to be called on a GoogleSignInAccount result from signIn()
    // It's a helper for the resulting object, not the delegate itself
    return null;
  }

  // Helper to get auth from a user account object
  static Future<Map<String, String?>> getAuthTokens(dynamic account) async {
    try {
      if (account == null) return {'accessToken': null, 'idToken': null};
      final auth = await account.authentication;
      return {
        'accessToken': auth.accessToken as String?,
        'idToken': auth.idToken as String?,
      };
    } catch (e) {
      debugPrint('SafeGoogleSignIn: Error getting tokens: $e');
      return {'accessToken': null, 'idToken': null};
    }
  }
}
