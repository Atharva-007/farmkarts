# Quick Reference - Multilingual & Theme System

## 🚀 For Developers: How to Use

### Change Language in UI

```dart
// In any widget with BuildContext
final localeService = Provider.of<LocaleService>(context, listen: false);
await localeService.setLocale(Locale('hi')); // Hindi
await localeService.setLocale(Locale('mr')); // Marathi
await localeService.setLocale(Locale('en')); // English
```

### Change Theme in UI

```dart
// In any widget with BuildContext
final themeService = Provider.of<ThemeService>(context, listen: false);
await themeService.setThemeMode(AppThemeMode.light);  // Light mode
await themeService.setThemeMode(AppThemeMode.dark);   // Dark mode
await themeService.setThemeMode(AppThemeMode.system); // System default
```

### Use Translations in Widgets

```dart
// Get localization instance
final l10n = AppLocalizations.of(context)!;

// Use translations
Text(l10n.translate('login'))
Text(l10n.translate('dashboard'))
Text(l10n.translate('add_to_cart'))
ElevatedButton(
  onPressed: () {},
  child: Text(l10n.translate('buy_now')),
)
```

### Available Translation Keys

#### Common
- `app_name`, `welcome`, `hello`, `loading`
- `save`, `cancel`, `delete`, `edit`, `done`
- `ok`, `yes`, `no`
- `search`, `filter`, `sort`

#### Authentication
- `login`, `signup`, `password`, `logout`
- `email_or_mobile`, `forgot_password`
- `login_button`, `signup_button`
- `login_error`, `login_success`

#### Navigation
- `dashboard`, `marketplace`, `crops`, `apmc`, `profile`
- `settings`, `wishlist`, `cart`, `orders`
- `ai_expert`, `community`, `weather`, `notifications`

#### Settings
- `language`, `theme`, `appearance`
- `light_mode`, `dark_mode`, `system_default`
- `select_language`, `select_theme`

#### Marketplace
- `add_product`, `product_name`, `product_price`
- `add_to_cart`, `buy_now`
- `category`, `organic`, `fresh`, `location`
- `added_to_cart`, `added_to_wishlist`

#### Cart & Wishlist
- `cart_empty`, `wishlist_empty`
- `checkout`, `total`, `subtotal`
- `proceed_to_checkout`, `remove`, `move_to_cart`

#### Profile
- `edit_profile`, `my_orders`, `my_products`
- `inventory`, `license_management`
- `selling_history`, `buying_history`

#### General UI
- `refresh`, `error_occurred`, `try_again`
- `no_data`, `coming_soon`

---

## 📝 Adding New Translations

### Step 1: Add to app_localizations.dart

```dart
static final Map<String, Map<String, String>> _localizedValues = {
  'en': {
    'new_feature': 'New Feature',
    // ... existing translations
  },
  'hi': {
    'new_feature': 'नई सुविधा',
    // ... existing translations
  },
  'mr': {
    'new_feature': 'नवीन वैशिष्ट्य',
    // ... existing translations
  },
};
```

### Step 2: Use in Widget

```dart
Text(l10n.translate('new_feature'))
```

---

## 🎨 Using Theme Colors

```dart
// Always use theme colors, not hardcoded
Container(
  color: AppTheme.primaryGreen,  // ✅ Good
  // color: Colors.green,        // ❌ Bad
)

Text(
  'Hello',
  style: Theme.of(context).textTheme.titleLarge, // ✅ Good
  // style: TextStyle(fontSize: 20),              // ❌ Bad
)
```

---

## 🔧 Common Patterns

### Language Selector Dropdown
```dart
DropdownButton<Locale>(
  value: localeService.locale,
  items: LocaleService.supportedLocales.map((locale) {
    return DropdownMenuItem(
      value: locale,
      child: Text(LocaleService.getLanguageName(locale.languageCode)),
    );
  }).toList(),
  onChanged: (locale) => localeService.setLocale(locale!),
)
```

### Theme Toggle Button
```dart
IconButton(
  icon: Icon(
    themeService.themeMode == AppThemeMode.light 
      ? Icons.dark_mode 
      : Icons.light_mode
  ),
  onPressed: () {
    themeService.setThemeMode(
      themeService.themeMode == AppThemeMode.light
        ? AppThemeMode.dark
        : AppThemeMode.light
    );
  },
)
```

---

## ⚡ Hot Tips

1. **Always use `l10n.translate('key')`** - Never hardcode strings
2. **Use theme colors** - `AppTheme.primaryGreen` instead of `Colors.green`
3. **Test all languages** - Before pushing code
4. **Keep keys organized** - Group related translations
5. **Use descriptive keys** - `product_added_to_cart` not `msg1`

---

## 🐛 Troubleshooting

**Language not updating?**
```dart
// Use Provider.of with listen: false for actions
final service = Provider.of<LocaleService>(context, listen: false);
await service.setLocale(Locale('hi'));
```

**Missing translation?**
- Check if key exists in all 3 languages (en, hi, mr)
- Verify key spelling
- Hot restart app if needed

**Theme not applying?**
- Ensure you're using `Theme.of(context)` for colors
- Check if custom colors are defined in both light/dark themes

---

## 📱 Testing Checklist

- [ ] Test all 3 languages
- [ ] Test all 3 theme modes
- [ ] Test language persistence (restart app)
- [ ] Test theme persistence (restart app)
- [ ] Test on different screen sizes
- [ ] Test with system theme changes

---

**Quick Access**: Settings → Language/Theme → Select → Done!

