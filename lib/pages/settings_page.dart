import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/locale_service.dart';
import '../services/theme_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/universal_header.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  final bool _locationEnabled = true;
  bool _priceAlertsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;
    final localeService = Provider.of<LocaleService>(context);
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          UniversalHeader(
            title: l10n.translate('settings'),
            subtitle: 'Customize your experience',
            icon: Icons.settings_suggest_rounded,
            showBackButton: true,
            showProfile: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSection(
                  l10n.translate('appearance'),
                  [
                    _buildSettingTile(
                      l10n.translate('language'),
                      LocaleService.getLanguageName(
                          localeService.locale.languageCode),
                      Icons.language_rounded,
                      () => _showLanguageDialog(context, localeService, l10n),
                      Colors.blue,
                    ),
                    _buildSettingTile(
                      l10n.translate('theme'),
                      _getThemeModeName(themeService.themeMode, l10n),
                      Icons.palette_outlined,
                      () => _showThemeDialog(context, themeService, l10n),
                      Colors.purple,
                    ),
                  ],
                ),
                _buildSection(
                  l10n.translate('account_settings'),
                  [
                    _buildSettingTile(
                      l10n.translate('edit_profile'),
                      'Manage your profile information',
                      Icons.person_outline_rounded,
                      () => _showComingSoon(l10n.translate('edit_profile')),
                      AppTheme.primaryGreen,
                    ),
                    _buildSettingTile(
                      'Email',
                      user?.email ?? 'No email',
                      Icons.email_outlined,
                      () => _showComingSoon('Email Settings'),
                      Colors.orange,
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
                      Colors.amber,
                    ),
                    _buildSwitchTile(
                      'Price Alerts',
                      'Get alerts for price changes',
                      Icons.attach_money_rounded,
                      _priceAlertsEnabled,
                      (value) => setState(() => _priceAlertsEnabled = value),
                      Colors.green,
                    ),
                  ],
                ),
                _buildSection(
                  'About',
                  [
                    _buildSettingTile(
                      'App Version',
                      '1.0.0',
                      Icons.info_outline_rounded,
                      null,
                      AppTheme.getPrimaryAccent(context),
                    ),
                    _buildSettingTile(
                      'Help & Support',
                      'Get help or contact us',
                      Icons.help_outline_rounded,
                      () => Navigator.pushNamed(context, '/help'),
                      Colors.cyan,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _logout(l10n),
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(l10n.translate('logout'),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.getErrorColor(context)
                            .withValues(alpha: 0.1),
                        foregroundColor: AppTheme.getErrorColor(context),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                              color: AppTheme.getErrorColor(context)
                                  .withValues(alpha: 0.5)),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 20, left: 16, right: 16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.getBorderColor(context)
              .withValues(alpha: isDark ? 0.1 : 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.getPrimaryAccent(context),
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon,
      VoidCallback? onTap, Color iconColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getTextColor(context))),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.getSecondaryTextColor(context))),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded,
                    size: 20,
                    color: AppTheme.getSecondaryTextColor(context)
                        .withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon,
      bool value, ValueChanged<bool> onChanged, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextColor(context))),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.getSecondaryTextColor(context))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.getPrimaryAccent(context),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LocaleService localeService,
      AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.translate('select_language'),
            style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocaleService.supportedLocales.map((locale) {
            return RadioListTile<String>(
              title: Text(LocaleService.getLanguageName(locale.languageCode),
                  style: TextStyle(color: AppTheme.getTextColor(context))),
              value: locale.languageCode,
              groupValue: localeService.locale.languageCode,
              activeColor: AppTheme.getPrimaryAccent(context),
              onChanged: (value) {
                if (value != null) {
                  localeService.setLocale(Locale(value));
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(
      BuildContext context, ThemeService themeService, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.translate('select_theme'),
            style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            return RadioListTile<AppThemeMode>(
              title: Text(_getThemeModeName(mode, l10n),
                  style: TextStyle(color: AppTheme.getTextColor(context))),
              value: mode,
              groupValue: themeService.themeMode,
              activeColor: AppTheme.getPrimaryAccent(context),
              onChanged: (value) {
                if (value != null) {
                  themeService.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppTheme.getPrimaryAccent(context)));
  }

  void _logout(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.translate('logout'),
            style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted)
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.getErrorColor(context),
                foregroundColor: Colors.white),
            child: Text(l10n.translate('logout')),
          ),
        ],
      ),
    );
  }
}
