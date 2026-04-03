# 🌍 Multilingual & Theming System Guide

## Overview
FarmKarts now supports **complete multilingual functionality** in **3 languages** and **3 theme modes** throughout the entire application.

---

## 🌐 Supported Languages

| Language | Code | Native Name |
|----------|------|-------------|
| English  | `en` | English     |
| Hindi    | `hi` | हिंदी       |
| Marathi  | `mr` | मराठी       |

---

## 🎨 Supported Themes

| Theme Mode      | Description                              |
|-----------------|------------------------------------------|
| Light Mode      | Bright theme for daytime use            |
| Dark Mode       | Dark theme for low-light environments   |
| System Default  | Follows device system theme settings    |

---

## 📂 File Structure

```
lib/
├── l10n/
│   └── app_localizations.dart    # All translations
├── services/
│   ├── locale_service.dart        # Language management
│   └── theme_service.dart         # Theme management
├── pages/
│   └── settings_page.dart         # Settings UI with language & theme picker
└── main.dart                      # Provider setup
```

---

## 🚀 How It Works

### 1. **Initialization**
In `main.dart`, both services are initialized with `MultiProvider`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => LocaleService()..loadLocale()),
    ChangeNotifierProvider(create: (_) => ThemeService()..loadTheme()),
  ],
  child: Consumer2<LocaleService, ThemeService>(
    builder: (context, localeService, themeService, child) {
      return MaterialApp(
        locale: localeService.locale,
        themeMode: themeService.materialThemeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        // ...
      );
    },
  ),
)
```

### 2. **Language Switching**
Users can change language from **Settings Page** or **Login Page**:

```dart
// Get localization service
final localeService = Provider.of<LocaleService>(context, listen: false);

// Change language
await localeService.setLocale(Locale('hi')); // Hindi
await localeService.setLocale(Locale('mr')); // Marathi
await localeService.setLocale(Locale('en')); // English
```

**Persistence:** Selected language is saved in `SharedPreferences` and persists across app restarts.

### 3. **Theme Switching**
Users can change theme from **Settings Page**:

```dart
// Get theme service
final themeService = Provider.of<ThemeService>(context, listen: false);

// Change theme
await themeService.setThemeMode(AppThemeMode.light);   // Light
await themeService.setThemeMode(AppThemeMode.dark);    // Dark  
await themeService.setThemeMode(AppThemeMode.system);  // System
```

**Persistence:** Selected theme is saved in `SharedPreferences` and persists across app restarts.

### 4. **Using Translations in Pages**

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  
  return Text(l10n.translate('welcome'));     // Welcome
  return Text(l10n.translate('dashboard'));   // Dashboard
  return Text(l10n.translate('marketplace')); // Marketplace
}
```

---

## 📝 Adding New Translations

### Step 1: Add to `app_localizations.dart`

```dart
static final Map<String, Map<String, String>> _localizedValues = {
  'en': {
    'your_new_key': 'Your English Text',
  },
  'hi': {
    'your_new_key': 'आपका हिंदी टेक्स्ट',
  },
  'mr': {
    'your_new_key': 'तुमचा मराठी मजकूर',
  },
};
```

### Step 2: Use in Your Page

```dart
Text(l10n.translate('your_new_key'))
```

---

## 🔑 Currently Translated Keys

### Common
- `app_name`, `welcome`, `hello`, `loading`, `save`, `cancel`, `delete`, `edit`, `done`, `ok`, `yes`, `no`, `search`, `filter`, `sort`

### Authentication
- `login`, `email_or_mobile`, `password`, `forgot_password`, `sign_up`, `logout`, `login_error`, `login_success`, etc.

### Navigation
- `dashboard`, `marketplace`, `crops`, `apmc`, `profile`, `settings`, `wishlist`, `cart`, `orders`, `ai_expert`, `community`, `weather`, `notifications`

### Settings
- `language`, `theme`, `light_mode`, `dark_mode`, `system_default`, `appearance`, `select_language`, `select_theme`

### Marketplace
- `add_product`, `product_name`, `product_price`, `add_to_cart`, `buy_now`, `category`, `organic`, etc.

### Cart & Wishlist
- `cart_empty`, `wishlist_empty`, `checkout`, `total`, `subtotal`, `remove`, etc.

### Profile
- `edit_profile`, `my_orders`, `my_products`, `inventory`, `license_management`, etc.

---

## 🎯 How Users Change Settings

### From Settings Page:
1. Open side drawer
2. Click **"Settings"**
3. Under **"Appearance"** section:
   - Click **"Language"** → Select preferred language
   - Click **"Theme"** → Select preferred theme
4. Changes apply **instantly** without restarting the app

### From Login Page:
1. Click language icon (🌐) in top-right corner
2. Select preferred language
3. Login page updates immediately

---

## 🔄 Real-Time Updates

Both language and theme changes are **immediate**:
- ✅ No app restart required
- ✅ All screens update automatically
- ✅ State preserved across navigation
- ✅ Preferences saved permanently

---

## 🛠️ Technical Details

### LocaleService
- **File:** `lib/services/locale_service.dart`
- **Purpose:** Manages app language
- **Storage:** SharedPreferences (`selected_locale` key)
- **Default:** English (`en`)

### ThemeService  
- **File:** `lib/services/theme_service.dart`
- **Purpose:** Manages app theme
- **Storage:** SharedPreferences (`theme_mode` key)
- **Default:** System (`system`)

### AppLocalizations
- **File:** `lib/l10n/app_localizations.dart`
- **Purpose:** Contains all translations
- **Method:** `translate(String key)` returns localized string
- **Fallback:** Returns key if translation missing

---

## 🌟 Best Practices

1. **Always use translations:**
   ```dart
   // ❌ Bad
   Text('Dashboard')
   
   // ✅ Good
   Text(l10n.translate('dashboard'))
   ```

2. **Use theme colors instead of hardcoded:**
   ```dart
   // ❌ Bad
   color: Colors.white
   
   // ✅ Good
   color: Theme.of(context).cardColor
   ```

3. **Test in all languages and themes:**
   - Check text overflow in Hindi/Marathi
   - Verify contrast in Dark mode
   - Ensure icons visible in both themes

---

## 📊 Coverage Status

| Feature               | Multilingual | Dark Theme |
|-----------------------|--------------|------------|
| Login Page            | ✅           | ✅         |
| Dashboard             | ✅           | ✅         |
| Marketplace           | ✅           | ✅         |
| Profile               | ✅           | ✅         |
| Settings              | ✅           | ✅         |
| Cart                  | ✅           | ✅         |
| Wishlist              | ✅           | ✅         |
| Crops                 | ✅           | ✅         |
| APMC                  | ✅           | ✅         |
| Community             | ✅           | ✅         |
| Weather               | ✅           | ✅         |
| AI Expert             | ✅           | ✅         |
| Orders                | ✅           | ✅         |
| Notifications         | ✅           | ✅         |

---

## 🚀 Future Enhancements

- [ ] Add more languages (Tamil, Telugu, etc.)
- [ ] RTL support for Arabic
- [ ] Custom theme colors
- [ ] Per-page font size adjustment
- [ ] Voice-based language detection

---

## 📞 Support

For issues or feature requests related to multilingual/theming:
1. Check this guide first
2. Verify translations in `app_localizations.dart`
3. Test in Settings page
4. Contact development team

---

**Version:** 1.0.0  
**Last Updated:** 2026-02-13  
**Maintained By:** FarmKarts Development Team
