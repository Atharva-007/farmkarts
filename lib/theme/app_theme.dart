import 'package:flutter/material.dart';

class AppTheme {
  // --- Modern Agriculture App Color Palette ---
  static const Color primaryGreen = Color(0xFF1B5E20); // Deep Organic Green
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color midGreen = Color(0xFF2E7D32);
  static const Color deepGreen = Color(0xFF0D330F);
  static const Color darkGreen =
      Color(0xFF0D330F); // Alias for backward compatibility

  static const Color accentOrange = Color(0xFFE65100); // Burnt Orange
  static const Color lightOrange = Color(0xFFFFB74D);
  static const Color skyBlue = Color(0xFF0277BD);
  static const Color sunshine = Color(0xFFFBC02D);
  static const Color earthBrown =
      Color(0xFF5D4037); // Restored for backward compatibility

  // --- Legacy Status Colors (Restored for compatibility) ---
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1976D2);
  static const Color primaryBlue = Color(0xFF1976D2);

  // --- PREMIUM LIGHT MODE PALETTE (Organic & Layered) ---
  static const Color bgSageLight =
      Color(0xFFF4F7F2); // Very subtle green-tinted white
  static const Color backgroundLight =
      Color(0xFFF4F7F2); // Alias for backward compatibility
  static const Color surfaceWhite =
      Color(0xFFFFFFFF); // Pure white for top layer
  static const Color surfaceOffWhite = Color(0xFFFDFDFD); // Slightly off white
  static const Color layerSecondary =
      Color(0xFFE8F0E8); // Noticeable sage for depth
  static const Color layerTertiary = Color(0xFFDDE6DD); // Darker layer

  static const Color textPremiumDark =
      Color(0xFF121A12); // Deep green-black text
  static const Color textDark = Color(0xFF121A12); // Alias
  static const Color textPremiumGrey =
      Color(0xFF4A554A); // Soft grey-green text
  static const Color textGrey = Color(0xFF4A554A); // Alias
  static const Color borderPremium = Color(0xFFE0E7E0); // Soft organic borders
  static const Color borderGrey = Color(0xFFE0E7E0); // Alias
  static const Color cardGrey =
      Color(0xFFFFFFFF); // Alias for premium white cards

  // --- PURE DARK THEME COLORS (Slate Blue-Black) ---
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBorder = Color(0xFF1F1F1F);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkPrimaryGreen = Color(0xFF43A047);
  static const Color darkDeepGreen = Color(0xFF1B5E20);
  static const Color darkHighlight = Color(0xFF2A2A2A);

  // --- Gradients ---
  static const Gradient primaryGradient = LinearGradient(
    colors: [primaryGreen, lightGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient skyGradient = LinearGradient(
    colors: [skyBlue, lightGreen],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // --- Shadows ---
  static List<BoxShadow> get defaultShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get subtleShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  // --- Theme Getters ---

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgSageLight,
      colorScheme: ColorScheme.light(
        primary: primaryGreen,
        onPrimary: Colors.white,
        secondary: accentOrange,
        onSecondary: Colors.white,
        surface: surfaceWhite,
        onSurface: textPremiumDark,
        surfaceContainerHighest: layerSecondary,
        outline: borderPremium,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPremiumDark,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: textPremiumDark),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: borderPremium, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryGreen.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borderPremium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borderPremium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.all(20),
      ),
      textTheme: const TextTheme(
        displayLarge:
            TextStyle(color: textPremiumDark, fontWeight: FontWeight.bold),
        headlineMedium:
            TextStyle(color: textPremiumDark, fontWeight: FontWeight.bold),
        titleLarge:
            TextStyle(color: textPremiumDark, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textPremiumDark, fontSize: 16),
        bodyMedium: TextStyle(color: textPremiumGrey, fontSize: 14),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.dark(
        primary: darkPrimaryGreen,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        outline: darkBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: darkBorder, width: 1),
        ),
      ),
    );
  }

  // --- Dynamic Color Helpers (Restored and Improved) ---

  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : bgSageLight;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : surfaceWhite;
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCard
        : surfaceWhite;
  }

  static Color getLayerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : layerSecondary;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : textPremiumDark;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : textPremiumGrey;
  }

  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorder
        : borderPremium;
  }

  static Color getPrimaryAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkPrimaryGreen
        : primaryGreen;
  }

  static Color getAppBarColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : primaryGreen;
  }

  static Color getAppBarTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : Colors.white;
  }

  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFCF6679)
        : error;
  }

  static Color getSuccessColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF81C784)
        : success;
  }

  static Color getWarningColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFB74D)
        : warning;
  }

  static Color getInfoColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF64B5F6)
        : info;
  }

  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF252525)
        : borderPremium;
  }

  static Color getIconBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkHighlight.withValues(alpha: 0.5)
        : primaryGreen.withValues(alpha: 0.1);
  }

  static Color getAIBubbleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF202C33)
        : surfaceWhite;
  }

  static List<BoxShadow> getPremiumShadow(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) return [];
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: primaryGreen.withValues(alpha: 0.02),
        blurRadius: 40,
        offset: const Offset(0, 20),
      ),
    ];
  }
}
