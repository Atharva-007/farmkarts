import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app locale/language state and persistence
class LocaleManager extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  Locale _locale = const Locale('en', '');

  Locale get locale => _locale;

  /// Load saved locale from SharedPreferences
  Future<void> loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_localeKey) ?? 'en';
      _locale = Locale(languageCode, '');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading locale: $e');
    }
  }

  /// Set and persist new locale
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    try {
      _locale = locale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting locale: $e');
    }
  }

  /// Clear saved locale and reset to default
  Future<void> clearLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localeKey);
      _locale = const Locale('en', '');
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing locale: $e');
    }
  }
}
