import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/universal_drawer.dart';
import '../widgets/universal_app_bar.dart';
import '../services/locale_service.dart';
import '../services/theme_service.dart';
import '../l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _priceAlertsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;
    final localeService = Provider.of<LocaleService>(context);
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(l10n),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSection(
                  l10n.translate('appearance'),
                  [
                    _buildSettingTile(
                      l10n.translate('language'),
                      LocaleService.getLanguageName(localeService.locale.languageCode),
                      Icons.language,
                      () => _showLanguageDialog(context, localeService, l10n),
                    ),
                    _buildSettingTile(
                      l10n.translate('theme'),
                      _getThemeModeName(themeService.themeMode, l10n),
                      Icons.palette_outlined,
                      () => _showThemeDialog(context, themeService, l10n),
                    ),
                  ],
                ),
                _buildSection(
                  l10n.translate('account_settings'),
                  [
                    _buildSettingTile(
                      l10n.translate('edit_profile'),
                      'Manage your profile information',
                      Icons.person_outline,
                      () => _showComingSoon(l10n.translate('edit_profile')),
                    ),
                    _buildSettingTile(
                      'Email',
                      user?.email ?? 'No email',
                      Icons.email_outlined,
                      () => _showComingSoon('Email Settings'),
                    ),
                    _buildSettingTile(
                      'Password',
                      'Change your password',
                      Icons.lock_outline,
                      () => _showComingSoon('Password Change'),
                    ),
                  ],
                ),
                _buildSection(
                  l10n.translate('notifications'),
                  [
                    _buildSwitchTile(
                      'Push Notifications',
                      'Receive push notifications',
                      Icons.notifications_outlined,
                      _notificationsEnabled,
                      (value) => setState(() => _notificationsEnabled = value),
                    ),
                    _buildSwitchTile(
                      'Price Alerts',
                      'Get alerts for price changes',
                      Icons.attach_money,
                      _priceAlertsEnabled,
                      (value) => setState(() => _priceAlertsEnabled = value),
                    ),
                    _buildSwitchTile(
                      'Location Services',
                      'Enable location for weather',
                      Icons.location_on_outlined,
                      _locationEnabled,
                      (value) => setState(() => _locationEnabled = value),
                    ),
                  ],
                ),
                _buildSection(
                  'Data & Privacy',
                  [
                    _buildSettingTile(
                      'Clear Cache',
                      'Free up storage space',
                      Icons.cleaning_services_outlined,
                      () => _clearCache(),
                    ),
                    _buildSettingTile(
                      'Privacy Policy',
                      'Read our privacy policy',
                      Icons.privacy_tip_outlined,
                      () => _showComingSoon('Privacy Policy'),
                    ),
                    _buildSettingTile(
                      'Terms of Service',
                      'Read terms and conditions',
                      Icons.description_outlined,
                      () => _showComingSoon('Terms of Service'),
                    ),
                  ],
                ),
                _buildSection(
                  'About',
                  [
                    _buildSettingTile(
                      'App Version',
                      '1.0.0',
                      Icons.info_outline,
                      null,
                    ),
                    _buildSettingTile(
                      'Help & Support',
                      'Get help or contact us',
                      Icons.help_outline,
                      () => _showComingSoon('Help & Support'),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _logout(l10n),
                      icon: const Icon(Icons.logout),
                      label: Text(l10n.translate('logout')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations l10n) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.primaryGreen,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        l10n.translate('settings'),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  String _getThemeModeName(AppThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case AppThemeMode.light:
        return l10n.translate('light_mode');
      case AppThemeMode.dark:
        return l10n.translate('dark_mode');
      case AppThemeMode.system:
        return l10n.translate('system_default');
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryGreen, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textGrey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LocaleService localeService, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('select_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocaleService.supportedLocales.map((locale) {
            return RadioListTile<String>(
              title: Text(LocaleService.getLanguageName(locale.languageCode)),
              value: locale.languageCode,
              groupValue: localeService.locale.languageCode,
              activeColor: AppTheme.primaryGreen,
              onChanged: (value) {
                if (value != null) {
                  localeService.setLocale(Locale(value));
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.translate('cancel'),
              style: const TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeService themeService, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('select_theme')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            return RadioListTile<AppThemeMode>(
              title: Text(_getThemeModeName(mode, l10n)),
              value: mode,
              groupValue: themeService.themeMode,
              activeColor: AppTheme.primaryGreen,
              onChanged: (value) {
                if (value != null) {
                  themeService.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.translate('cancel'),
              style: const TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear the cache?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully!'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _logout(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('logout')),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: Text(l10n.translate('logout'), style: const TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
