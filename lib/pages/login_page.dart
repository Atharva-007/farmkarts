import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_state_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showLogo = false;
  String _selectedLanguage = 'en';

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final Animation<Offset> _slideAnimation = Tween<Offset>(
    begin: const Offset(0, 0.3),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _showLogo = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper methods for responsive design
  bool get _isMobile => MediaQuery.of(context).size.width < 768;
  bool get _isDesktop => MediaQuery.of(context).size.width >= 1200;
  
  double _getFontSize(double baseSize) {
    if (_isDesktop) return baseSize * 1.1;
    return baseSize;
  }

  bool _isEmail(String input) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input);
  }

  bool _isMobileNumber(String input) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(input.replaceAll(RegExp(r'[^\d]'), ''));
  }

  String _getFriendlyErrorMessage(String error, AppLocalizations l10n) {
    if (error.contains('wrong-password') || error.contains('invalid-credential')) {
      return l10n.translate('invalid_credentials');
    } else if (error.contains('user-not-found')) {
      return l10n.translate('user_not_found');
    } else if (error.contains('invalid-email')) {
      return l10n.translate('invalid_email_mobile');
    } else if (error.contains('too-many-requests')) {
      return l10n.translate('too_many_attempts');
    } else if (error.contains('network-request-failed')) {
      return l10n.translate('network_error');
    } else if (error.contains('user-disabled')) {
      return l10n.translate('account_disabled');
    } else if (error.contains('requires-recent-login')) {
      return l10n.translate('session_expired');
    }
    return l10n.translate('login_failed');
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    final l10n = AppLocalizations.of(context)!;

    if (_identifierController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = l10n.translate('enter_email_mobile'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String email = _identifierController.text.trim();
      
      // If mobile number, convert to email format (you may need to adjust based on your auth setup)
      if (_isMobileNumber(email)) {
        // For Firebase, you might need to convert mobile to email format
        // e.g., mobile@farmkarts.com or use phone authentication
        email = '${email.replaceAll(RegExp(r'[^\d]'), '')}@farmkarts.app';
      }

      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );
      
      if (userCredential?.user != null) {
        // Set user in state service
        final userStateService = Provider.of<UserStateService>(context, listen: false);
        await userStateService.setCurrentUser(userCredential!.user!.uid);
        
        if (userStateService.currentUser != null) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          if (mounted) {
            setState(() => _errorMessage = 'User profile not found. Please contact support.');
          }
        }
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          setState(() => _errorMessage = l10n.translate('login_failed'));
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _errorMessage = _getFriendlyErrorMessage(e.toString(), l10n));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Stack(
            children: [
              // Enhanced gradient background with depth
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.getPrimaryAccent(context).withOpacity(0.1),
                      Theme.of(context).scaffoldBackgroundColor,
                      AppTheme.accentOrange.withOpacity(0.08),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              
              // Decorative circles for depth
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.getPrimaryAccent(context).withOpacity(0.15),
                        AppTheme.getPrimaryAccent(context).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              
              Positioned(
                bottom: -150,
                left: -100,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accentOrange.withOpacity(0.12),
                        AppTheme.accentOrange.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Language selector in top right corner
              Positioned(
                top: 16,
                right: 16,
                child: Consumer<LocaleService>(
                  builder: (context, localeService, _) => PopupMenuButton<String>(
                    tooltip: 'Change Language',
                    onSelected: (String languageCode) {
                      localeService.setLocale(Locale(languageCode));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: isDark ? Border.all(color: AppTheme.getBorderColor(context)) : null,
                        boxShadow: isDark ? [] : [
                          BoxShadow(
                            color: AppTheme.getPrimaryAccent(context).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.language, size: 20, color: AppTheme.getPrimaryAccent(context)),
                          const SizedBox(width: 6),
                          Text(
                            localeService.locale.languageCode.toUpperCase(),
                            style: TextStyle(
                              color: AppTheme.getPrimaryAccent(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (BuildContext context) => LocaleService.supportedLocales.map((locale) {
                      final Map<String, String> languageNames = {
                        'en': 'English',
                        'hi': 'हिंदी',
                        'mr': 'मराठी',
                      };
                      return PopupMenuItem<String>(
                        value: locale.languageCode,
                        child: Row(
                          children: [
                            if (locale.languageCode == localeService.locale.languageCode)
                              Icon(Icons.check, color: AppTheme.getPrimaryAccent(context), size: 18)
                            else
                              const SizedBox(width: 18),
                            const SizedBox(width: 8),
                            Text(
                              languageNames[locale.languageCode] ?? locale.languageCode.toUpperCase(),
                              style: TextStyle(
                                fontWeight: locale.languageCode == localeService.locale.languageCode
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: locale.languageCode == localeService.locale.languageCode
                                    ? AppTheme.getPrimaryAccent(context)
                                    : AppTheme.getTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              // Main login form
              
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: _isDesktop ? 64 : (_isMobile ? 16 : 32),
                    vertical: _isDesktop ? 32 : 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: _isDesktop ? 500 : double.infinity,
                    ),
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Card(
                        elevation: isDark ? 4 : 12,
                        shadowColor: AppTheme.getPrimaryAccent(context).withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: isDark ? BorderSide(color: AppTheme.getBorderColor(context)) : BorderSide.none,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(_isDesktop ? 32 : 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Animated Logo & Title
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 800),
                                opacity: _showLogo ? 1 : 0,
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 600),
                                  scale: _showLogo ? 1.0 : 0.7,
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(_isDesktop ? 20 : 16),
                                        decoration: BoxDecoration(
                                          color: AppTheme.getPrimaryAccent(context).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.agriculture,
                                          size: _isDesktop ? 56 : 48,
                                          color: AppTheme.getPrimaryAccent(context),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'FarmKarts',
                                        style: TextStyle(
                                          fontSize: _getFontSize(28),
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.getPrimaryAccent(context),
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Smart Agriculture Platform',
                                        style: TextStyle(
                                          fontSize: _getFontSize(14),
                                          color: AppTheme.getSecondaryTextColor(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 32),

                            // Email/Mobile Field
                            TextField(
                              controller: _identifierController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: l10n?.translate('email_or_mobile') ?? 'Email or Mobile',
                                prefixIcon: const Icon(Icons.person_outline),
                                hintText: 'email@example.com or 9876543210',
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: l10n?.translate('password') ?? 'Password',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                hintText: 'Enter your password',
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // Navigate to forgot password
                                },
                                child: Text(l10n?.translate('forgot_password') ?? 'Forgot Password?'),
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Error Message
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: AppTheme.error),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_errorMessage != null) const SizedBox(height: 16),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: _isDesktop ? 56 : 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.getPrimaryAccent(context),
                                foregroundColor: Colors.white,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(l10n?.translate('login') ?? 'Login'),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Divider
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'or',
                                  style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            height: _isDesktop ? 56 : 48,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/signup');
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppTheme.getPrimaryAccent(context)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Create Account',
                                style: TextStyle(color: AppTheme.getPrimaryAccent(context)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Additional Info
                          Text(
                            'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: _getFontSize(12),
                              color: AppTheme.getSecondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ), // Closing Center
            ),
          ],
        ),
      ),
    ),
  );
}
}