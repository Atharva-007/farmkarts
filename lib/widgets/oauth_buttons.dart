import 'package:flutter/material.dart';
import '../services/oauth_service.dart';

/// OAuth Sign-In Buttons Widget
class OAuthButtons extends StatelessWidget {
  final VoidCallback? onSuccess;
  final Function(String)? onError;
  
  const OAuthButtons({
    super.key,
    this.onSuccess,
    this.onError,
  });

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final oauthService = OAuthService();
      final result = await oauthService.signInWithGoogle();
      
      if (result != null && context.mounted) {
        onSuccess?.call();
      }
    } catch (e) {
      if (context.mounted) {
        onError?.call('Google Sign-In failed: ${e.toString()}');
      }
    }
  }

  Future<void> _handleFacebookSignIn(BuildContext context) async {
    try {
      final oauthService = OAuthService();
      final result = await oauthService.signInWithFacebook();
      
      if (result != null && context.mounted) {
        onSuccess?.call();
      }
    } catch (e) {
      if (context.mounted) {
        onError?.call('Facebook Sign-In failed: ${e.toString()}');
      }
    }
  }

  Future<void> _handleAppleSignIn(BuildContext context) async {
    try {
      final oauthService = OAuthService();
      final result = await oauthService.signInWithApple();
      
      if (result != null && context.mounted) {
        onSuccess?.call();
      }
    } catch (e) {
      if (context.mounted) {
        onError?.call('Apple Sign-In failed: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider with "OR"
        Row(
          children: [
            const Expanded(child: Divider(thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            const Expanded(child: Divider(thickness: 1)),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Google Sign-In Button
        _OAuthButton(
          onPressed: () => _handleGoogleSignIn(context),
          icon: Icons.g_mobiledata,
          label: 'Continue with Google',
          backgroundColor: Colors.white,
          textColor: Colors.black87,
          borderColor: Colors.grey[300]!,
        ),
        
        const SizedBox(height: 12),
        
        // Facebook Sign-In Button
        _OAuthButton(
          onPressed: () => _handleFacebookSignIn(context),
          icon: Icons.facebook,
          label: 'Continue with Facebook',
          backgroundColor: const Color(0xFF1877F2),
          textColor: Colors.white,
        ),
        
        const SizedBox(height: 12),
        
        // Apple Sign-In Button (iOS/macOS only)
        if (Theme.of(context).platform == TargetPlatform.iOS ||
            Theme.of(context).platform == TargetPlatform.macOS)
          _OAuthButton(
            onPressed: () => _handleAppleSignIn(context),
            icon: Icons.apple,
            label: 'Continue with Apple',
            backgroundColor: Colors.black,
            textColor: Colors.white,
          ),
      ],
    );
  }
}

class _OAuthButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  
  const _OAuthButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor ?? backgroundColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
