import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'services/locale_service.dart';
import 'services/theme_service.dart';

class EnhancedSettingsPage extends StatelessWidget {
  const EnhancedSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localeService = Provider.of<LocaleService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.translate('settings')),
        elevation: 0,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language Section
          _buildSectionTitle(context, l10n.translate('language')),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.language, color: AppTheme.primaryGreen),
              title: Text(
                l10n.translate('language'),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(LocaleService.getLanguageName(
                localeService.locale.languageCode,
              )),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguageDialog(context, localeService, l10n),
            ),
          ),
          const SizedBox(height: 16),

          // Theme Section
          _buildSectionTitle(context, l10n.translate('theme')),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.brightness_6, color: AppTheme.primaryGreen),
              title: Text(
                l10n.translate('theme'),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(_getThemeModeName(themeService.themeMode, l10n)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemeDialog(context, themeService, l10n),
            ),
          ),
          const SizedBox(height: 24),

          // Account Section
          _buildSectionTitle(context, 'Account'),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                l10n.translate('logout'),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              onTap: () => _showLogoutDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
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

  void _showLanguageDialog(
    BuildContext context,
    LocaleService localeService,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.translate('select_language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: LocaleService.supportedLocales.map((locale) {
              final isSelected = localeService.locale == locale;
              return RadioListTile<Locale>(
                title: Text(LocaleService.getLanguageName(locale.languageCode)),
                value: locale,
                groupValue: localeService.locale,
                activeColor: AppTheme.primaryGreen,
                selected: isSelected,
                onChanged: (Locale? value) {
                  if (value != null) {
                    localeService.setLocale(value);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showThemeDialog(
    BuildContext context,
    ThemeService themeService,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.translate('select_theme')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppThemeMode.values.map((mode) {
              final isSelected = themeService.themeMode == mode;
              return RadioListTile<AppThemeMode>(
                title: Text(_getThemeModeName(mode, l10n)),
                value: mode,
                groupValue: themeService.themeMode,
                activeColor: AppTheme.primaryGreen,
                selected: isSelected,
                onChanged: (AppThemeMode? value) {
                  if (value != null) {
                    themeService.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.translate('logout')),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.translate('logout')),
            ),
          ],
        );
      },
    );
  }
}
