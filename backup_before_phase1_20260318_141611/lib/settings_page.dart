import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/base_layout_wrapper.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'services/locale_service.dart';
import 'services/theme_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeService = Provider.of<LocaleService>(context);
    final themeService = Provider.of<ThemeService>(context);

    return BaseLayoutWrapper(
      title: l10n.translate('settings'),
      showBottomNavBar: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _buildSectionTitle(context, l10n.translate('appearance')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language, color: AppTheme.primaryGreen),
                  title: Text(l10n.translate('language')),
                  subtitle: Text(LocaleService.getLanguageName(localeService.locale.languageCode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLanguageDialog(context, localeService, l10n),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.brightness_6, color: AppTheme.primaryGreen),
                  title: Text(l10n.translate('theme')),
                  subtitle: Text(_getThemeModeName(themeService.themeMode, l10n)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemeDialog(context, themeService, l10n),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(context, l10n),
              icon: const Icon(Icons.logout),
              label: Text(l10n.translate('logout')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          const SizedBox(height: 16),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryGreen,
        ),
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
          children: [
            RadioListTile<Locale>(
              title: const Text('English'),
              value: const Locale('en'),
              groupValue: localeService.locale,
              activeColor: AppTheme.primaryGreen,
              onChanged: (value) {
                if (value != null) {
                  localeService.setLocale(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<Locale>(
              title: const Text('हिन्दी (Hindi)'),
              value: const Locale('hi'),
              groupValue: localeService.locale,
              activeColor: AppTheme.primaryGreen,
              onChanged: (value) {
                if (value != null) {
                  localeService.setLocale(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<Locale>(
              title: const Text('मराठी (Marathi)'),
              value: const Locale('mr'),
              groupValue: localeService.locale,
              activeColor: AppTheme.primaryGreen,
              onChanged: (value) {
                if (value != null) {
                  localeService.setLocale(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('cancel')),
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
          children: [
            RadioListTile<AppThemeMode>(
              title: Text(l10n.translate('light_mode')),
              value: AppThemeMode.light,
              groupValue: themeService.themeMode,
              activeColor: AppTheme.primaryGreen,
              onChanged: (value) {
                if (value != null) {
                  themeService.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<AppThemeMode>(
              title: Text(l10n.translate('dark_mode')),
              value: AppThemeMode.dark,
              groupValue: themeService.themeMode,
              activeColor: AppTheme.primaryGreen,
              onChanged: (value) {
                if (value != null) {
                  themeService.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<AppThemeMode>(
              title: Text(l10n.translate('system_default')),
              value: AppThemeMode.system,
              groupValue: themeService.themeMode,
              activeColor: AppTheme.primaryGreen,
              onChanged: (value) {
                if (value != null) {
                  themeService.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('cancel')),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('logout')),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('no')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.translate('yes')),
          ),
        ],
      ),
    );
  }
}
