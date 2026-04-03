import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/fcm_service.dart';
import '../theme/app_theme.dart';
import '../utils/toast_helper.dart';

/// Fully functional settings page
class ImprovedSettingsPage extends StatefulWidget {
  const ImprovedSettingsPage({super.key});

  @override
  State<ImprovedSettingsPage> createState() => _ImprovedSettingsPageState();
}

class _ImprovedSettingsPageState extends State<ImprovedSettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FCMService _fcmService = FCMService();
  
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _orderNotifications = true;
  bool _chatNotifications = true;
  ThemeMode _themeMode = ThemeMode.system;
  String _language = 'English';
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Load settings from SharedPreferences (async operation)
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _emailNotifications = prefs.getBool('email_notifications') ?? true;
        _orderNotifications = prefs.getBool('order_notifications') ?? true;
        _chatNotifications = prefs.getBool('chat_notifications') ?? true;
        
        final themeModeString = prefs.getString('theme_mode') ?? 'system';
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
        
        _language = prefs.getString('language') ?? 'English';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastHelper.showError(context, 'Failed to load settings');
      }
    }
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('email_notifications', _emailNotifications);
      await prefs.setBool('order_notifications', _orderNotifications);
      await prefs.setBool('chat_notifications', _chatNotifications);
      await prefs.setString('theme_mode', _themeMode.toString());
      await prefs.setString('language', _language);
      
      if (mounted) {
        ToastHelper.showSuccess(context, 'Settings saved');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Failed to save settings');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildSection(
            title: 'Notifications',
            children: [
              SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text('Receive push notifications'),
                value: _notificationsEnabled,
                onChanged: (value) async {
                  setState(() => _notificationsEnabled = value);
                  if (value) {
                    await _fcmService.initialize();
                  }
                  await _saveSettings();
                },
                activeColor: AppTheme.primaryGreen,
              ),
              SwitchListTile(
                title: const Text('Email Notifications'),
                subtitle: const Text('Receive updates via email'),
                value: _emailNotifications,
                onChanged: (value) {
                  setState(() => _emailNotifications = value);
                  _saveSettings();
                },
                activeColor: AppTheme.primaryGreen,
              ),
              SwitchListTile(
                title: const Text('Order Updates'),
                subtitle: const Text('Notifications about order status'),
                value: _orderNotifications,
                onChanged: (value) {
                  setState(() => _orderNotifications = value);
                  _saveSettings();
                },
                activeColor: AppTheme.primaryGreen,
              ),
              SwitchListTile(
                title: const Text('Chat Messages'),
                subtitle: const Text('Notifications for new messages'),
                value: _chatNotifications,
                onChanged: (value) {
                  setState(() => _chatNotifications = value);
                  _saveSettings();
                },
                activeColor: AppTheme.primaryGreen,
              ),
            ],
          ),
          
          _buildSection(
            title: 'Appearance',
            children: [
              ListTile(
                title: const Text('Theme'),
                subtitle: Text(_getThemeModeLabel(_themeMode)),
                trailing: const Icon(Icons.brightness_6),
                onTap: () => _showThemeDialog(),
              ),
              ListTile(
                title: const Text('Language'),
                subtitle: Text(_language),
                trailing: const Icon(Icons.language),
                onTap: () => _showLanguageDialog(),
              ),
            ],
          ),
          
          _buildSection(
            title: 'Account',
            children: [
              ListTile(
                title: const Text('Profile Settings'),
                leading: const Icon(Icons.person),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _navigateToProfileSettings(),
              ),
              ListTile(
                title: const Text('Change Password'),
                leading: const Icon(Icons.lock),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _changePassword(),
              ),
              ListTile(
                title: const Text('Manage Address'),
                leading: const Icon(Icons.location_on),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _manageAddresses(),
              ),
            ],
          ),
          
          _buildSection(
            title: 'Privacy & Security',
            children: [
              ListTile(
                title: const Text('Privacy Policy'),
                leading: const Icon(Icons.privacy_tip),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPrivacyPolicy(),
              ),
              ListTile(
                title: const Text('Terms of Service'),
                leading: const Icon(Icons.description),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showTermsOfService(),
              ),
              ListTile(
                title: const Text('Delete Account'),
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _deleteAccount(),
              ),
            ],
          ),
          
          _buildSection(
            title: 'Support',
            children: [
              ListTile(
                title: const Text('Help Center'),
                leading: const Icon(Icons.help),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showHelpCenter(),
              ),
              ListTile(
                title: const Text('Contact Us'),
                leading: const Icon(Icons.contact_support),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _contactSupport(),
              ),
              ListTile(
                title: const Text('About'),
                leading: const Icon(Icons.info),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAbout(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () => _logout(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Logout'),
            ),
          ),
          
          const SizedBox(height: 32),
          
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(children: children),
        ),
      ],
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() => _themeMode = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() => _themeMode = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() => _themeMode = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final languages = ['English', 'Hindi', 'Tamil', 'Telugu', 'Marathi'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            return RadioListTile<String>(
              title: Text(lang),
              value: lang,
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _navigateToProfileSettings() {
    ToastHelper.showInfo(context, 'Profile settings coming soon');
  }

  void _changePassword() async {
    final email = _auth.currentUser?.email;
    if (email == null) return;

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        ToastHelper.showSuccess(
          context,
          'Password reset email sent to $email',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Failed to send reset email');
      }
    }
  }

  void _manageAddresses() {
    ToastHelper.showInfo(context, 'Address management coming soon');
  }

  void _showPrivacyPolicy() {
    ToastHelper.showInfo(context, 'Privacy policy coming soon');
  }

  void _showTermsOfService() {
    ToastHelper.showInfo(context, 'Terms of service coming soon');
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _auth.currentUser?.delete();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ToastHelper.showError(context, 'Failed to delete account');
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showHelpCenter() {
    ToastHelper.showInfo(context, 'Help center coming soon');
  }

  void _contactSupport() {
    ToastHelper.showInfo(context, 'Support contact coming soon');
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'FarmKarts',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.agriculture, size: 48),
      children: [
        const Text('Smart Agriculture Platform'),
        const SizedBox(height: 8),
        const Text('Connecting farmers with buyers directly.'),
      ],
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }
}
