# Quick Start - Universal Navigation Setup

## What's New

✅ **Universal Side Navigation** - One drawer component for entire app
✅ **Clean Organization** - Menu grouped by sections
✅ **Perfect Responsiveness** - No lags, no double-taps
✅ **Professional Design** - Polished and consistent

## How to Use

### Add Drawer to Any Page (3 Steps)

**Step 1:** Import the widget
```dart
import '../widgets/universal_drawer.dart';
```

**Step 2:** Add to Scaffold
```dart
Scaffold(
  drawer: const UniversalDrawer(currentPage: 'marketplace'),
  // ... rest of your code
)
```

**Step 3:** Add menu icon to AppBar
```dart
AppBar(
  leading: Builder(
    builder: (context) => IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () => Scaffold.of(context).openDrawer(),
    ),
  ),
)
```

### Page Names Reference

Use these exact names for `currentPage`:

```dart
'dashboard'   // Dashboard Home
'marketplace' // Marketplace
'crops'       // My Crops  
'apmc'        // APMC Markets
'weather'     // Weather
'community'   // Community
'profile'     // Profile
'orders'      // My Orders
'messages'    // Messages/Chat
'ai-chat'     // AI Expert
'settings'    // Settings
```

## Drawer Structure

```
╔══════════════════════════════╗
║  FarmKarts                   ║
║  user@email.com              ║
╠══════════════════════════════╣
║  Main Menu                   ║
║  ├ Dashboard                 ║
║  ├ Marketplace               ║
║  ├ My Crops                  ║
║  ├ APMC Markets ← SELECTED   ║
║  ├ Weather                   ║
║  └ Community                 ║
╠══════════════════════════════╣
║  My Account                  ║
║  ├ Profile                   ║
║  ├ My Orders                 ║
║  └ Messages                  ║
╠══════════════════════════════╣
║  More                        ║
║  ├ AI Expert                 ║
║  ├ Settings                  ║
║  └ About                     ║
╠══════════════════════════════╣
║  [    Logout    ]            ║
╚══════════════════════════════╝
```

## Already Implemented

✅ Dashboard Home
✅ APMC Commodity Detail
✅ Settings Page

## To Implement

Add the 3 steps above to:
- [ ] Marketplace pages
- [ ] Crops dashboard
- [ ] Weather dashboard
- [ ] Community pages
- [ ] Profile pages
- [ ] Orders page
- [ ] AI Chat page

## Features

### Visual Feedback
- ✅ Current page highlighted in green
- ✅ Green vertical bar on right
- ✅ Bold text for selected item
- ✅ Icons change (outlined → filled)

### Smooth Experience
- ✅ Ripple effect on tap
- ✅ 250ms navigation delay (no double-tap)
- ✅ Drawer closes before navigation
- ✅ Error recovery (goes to home if route fails)

### Organization
- ✅ Grouped by sections
- ✅ Logical ordering
- ✅ Clear visual separation
- ✅ Professional appearance

## Example: Complete Page Setup

```dart
import 'package:flutter/material.dart';
import '../widgets/universal_drawer.dart';
import '../theme/app_theme.dart';

class MarketplacePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      drawer: const UniversalDrawer(currentPage: 'marketplace'),
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: AppTheme.primaryGreen,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
      ),
      body: // Your page content here
    );
  }
}
```

## Tips

✅ **Always use exact page names** - Case sensitive!
✅ **Import relative paths correctly** - Check folder structure
✅ **Use Builder for AppBar leading** - Prevents context issues
✅ **Test on all pages** - Ensure consistency

## Common Issues

**Drawer not opening?**
- Check you're using `Builder` widget
- Verify `Scaffold.of(context).openDrawer()`

**Page not highlighting?**
- Check `currentPage` matches exactly
- Use lowercase names from reference above

**Navigation not working?**
- Verify routes are defined in `main.dart`
- Check route names match drawer routes

**Double-tap issue?**
- Don't modify the navigation logic
- 250ms delay is intentional

## Build & Test

```bash
# Run app
flutter run

# Test navigation
1. Open drawer
2. Tap a menu item
3. Check page loads
4. Open drawer again
5. Verify current page highlighted
```

---

**Quick Reference:** See UNIVERSAL_NAVIGATION_COMPLETE.md for full details
**Need Help?** Check the example code above
**Status:** ✅ Ready to implement on all pages!
