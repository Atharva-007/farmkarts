import 'package:flutter/material.dart';

class AppTheme {
  // Modern Agriculture App Color Palette
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color deepGreen = Color(0xFF0D5016);
  static const Color accentOrange = Color(0xFFFF8F00);
  static const Color lightOrange = Color(0xFFFFB74D);
  static const Color earthBrown = Color(0xFF5D4037);
  static const Color skyBlue = Color(0xFF03A9F4);
  static const Color sunshine = Color(0xFFFFC107);
  static const Color freshMint = Color(0xFF00E676);
  static const Color harvest = Color(0xFFFF6F00);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  static const Color primaryBlue = Color(0xFF2196F3);

  // Neutral Colors - Light Theme
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color cardGrey = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF263238);
  static const Color textGrey = Color(0xFF607D8B);
  static const Color borderGrey = Color(0xFFE0E0E0);

  // Pure Dark Theme Colors - New Slate Blue-Black Scheme
  static const Color darkBackground = Color(0xFF0A0A0A);      // Pure black base
  static const Color darkSurface = Color(0xFF121212);         // Slightly lighter black
  static const Color darkCard = Color(0xFF1A1A1A);            // Card background
  static const Color darkBorder = Color(0xFF1F1F1F);          // Border color
  static const Color darkAccent = Color(0xFF2A2A2A);          // Accent surface
  static const Color darkElevated = Color(0xFF1C1C1C);        // Elevated surface
  static const Color darkHighlight = Color(0xFF2D2D2D);       // Highlight color
  
  // Dark Theme Text Colors
  static const Color darkText = Color(0xFFE0E0E0);            // Primary text
  static const Color darkTextPrimary = Color(0xFFFFFFFF);     // Primary white text
  static const Color darkTextSecondary = Color(0xFFB0B0B0);   // Secondary text
  static const Color darkTextTertiary = Color(0xFF808080);    // Tertiary text
  static const Color darkDivider = Color(0xFF252525);         // Divider color
  
  // Dark Theme Green Accent (softer for dark mode)
  static const Color darkPrimaryGreen = Color(0xFF43A047);    // Softer green for dark
  static const Color darkLightGreen = Color(0xFF66BB6A);      // Lighter accent
  static const Color darkDeepGreen = Color(0xFF2E7D32);       // Deeper green
  
  // Dark Theme Status Colors
  static const Color darkError = Color(0xFFCF6679);           // Error color
  static const Color darkWarning = Color(0xFFFFB74D);         // Warning color
  static const Color darkSuccess = Color(0xFF81C784);         // Success color

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: const TextStyle(color: textGrey),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textGrey,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textGrey,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textGrey,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),

      // FAB Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentOrange,
        foregroundColor: Colors.white,
        elevation: 6,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: backgroundLight,
    );
  }


  
  // Helper method to get color based on brightness
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkBackground 
        : backgroundLight;
  }
  
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkSurface 
        : surfaceWhite;
  }
  
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkCard 
        : cardGrey;
  }
  
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkTextPrimary 
        : textDark;
  }
  
  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkTextSecondary 
        : textGrey;
  }
  
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkBorder 
        : borderGrey;
  }

  static Color getPrimaryAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkPrimaryGreen 
        : primaryGreen;
  }

  static Color getIconBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkHighlight.withOpacity(0.5) 
        : primaryGreen.withOpacity(0.1);
  }

  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkDivider 
        : borderGrey;
  }

  static Color getSectionTitleColor(BuildContext context) {
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

  static Color getAppBarActionColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkTextPrimary 
        : Colors.white;
  }

  static Color getSuccessColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkSuccess 
        : success;
  }

  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkError 
        : error;
  }

  static Color getWarningColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkWarning 
        : warning;
  }

  static Color getInfoColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? info 
        : info;
  }

  static Color getPlaceholderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkHighlight 
        : borderGrey;
  }

  static Color getTabIndicatorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkPrimaryGreen 
        : Colors.white;
  }

  static Color getTabLabelColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : primaryGreen;
  }

  static Color getTabUnselectedLabelColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkTextSecondary 
        : Colors.white.withOpacity(0.7);
  }

  static Color getBottomNavActiveColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkPrimaryGreen 
        : primaryGreen;
  }

  static Color getBottomNavInactiveColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkTextSecondary 
        : textGrey;
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: darkPrimaryGreen,
        primaryContainer: darkDeepGreen,
        secondary: darkLightGreen,
        secondaryContainer: Color(0xFF1E3A20),
        surface: darkSurface,
        surfaceVariant: darkCard,
        background: darkBackground,
        error: darkError,
        onPrimary: darkTextPrimary,
        onPrimaryContainer: darkTextPrimary,
        onSecondary: darkTextPrimary,
        onSecondaryContainer: darkTextPrimary,
        onSurface: darkTextPrimary,
        onSurfaceVariant: darkTextSecondary,
        onBackground: darkTextPrimary,
        onError: darkTextPrimary,
        outline: darkBorder,
        outlineVariant: darkDivider,
        shadow: Colors.black87,
        scrim: Colors.black87,
        inverseSurface: darkTextPrimary,
        onInverseSurface: darkBackground,
        inversePrimary: darkPrimaryGreen,
      ),
      
      // App Bar Theme - Deep Dark
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        shadowColor: Colors.black87,
        iconTheme: IconThemeData(color: darkTextPrimary),
        actionsIconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
      ),
      
      // Drawer Theme - Deep Dark
      drawerTheme: const DrawerThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black87,
        elevation: 16,
      ),
      
      // List Tile Theme - Deep Dark
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: darkHighlight,
        iconColor: darkTextSecondary,
        textColor: darkTextPrimary,
        selectedColor: darkPrimaryGreen,
      ),
      
      // Icon Theme - Deep Dark
      iconTheme: const IconThemeData(
        color: darkTextSecondary,
      ),
      
      // Divider Theme - Deep Dark
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
        space: 1,
      ),

      // Elevated Button Theme - Deep Dark
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryGreen,
          foregroundColor: darkTextPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 2,
          shadowColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme - Deep Dark
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimaryGreen,
          side: const BorderSide(color: darkBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text Button Theme - Deep Dark
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimaryGreen,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Card Theme - Deep Dark with elevation
      cardTheme: CardThemeData(
        color: darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: darkBorder.withOpacity(0.3), width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      ),

      // Input Decoration Theme - Deep Dark
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        hoverColor: darkElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkPrimaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkError, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkBorder.withOpacity(0.5)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: const TextStyle(color: darkTextSecondary),
        hintStyle: const TextStyle(color: darkTextTertiary),
        helperStyle: const TextStyle(color: darkTextSecondary),
        errorStyle: const TextStyle(color: darkError),
      ),

      // Text Theme - Deep Dark
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: darkTextSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: darkTextTertiary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkTextSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: darkTextTertiary,
        ),
      ),

      // Bottom Navigation Bar Theme - Deep Dark
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: darkPrimaryGreen,
        unselectedItemColor: darkTextSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),

      // Navigation Bar Theme - Deep Dark
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: darkHighlight,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(color: darkPrimaryGreen, fontSize: 12, fontWeight: FontWeight.w500);
          }
          return const TextStyle(color: darkTextSecondary, fontSize: 12);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: darkPrimaryGreen);
          }
          return const IconThemeData(color: darkTextSecondary);
        }),
      ),

      // FAB Theme - Deep Dark
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkPrimaryGreen,
        foregroundColor: darkTextPrimary,
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Chip Theme - Deep Dark
      chipTheme: ChipThemeData(
        backgroundColor: darkCard,
        selectedColor: darkPrimaryGreen.withOpacity(0.3),
        deleteIconColor: darkTextSecondary,
        labelStyle: const TextStyle(color: darkTextPrimary),
        secondaryLabelStyle: const TextStyle(color: darkTextSecondary),
        brightness: Brightness.dark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: darkBorder.withOpacity(0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Dialog Theme - Deep Dark
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 24,
        shadowColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: darkTextSecondary,
        ),
      ),

      // Bottom Sheet Theme - Deep Dark
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: darkCard,
        elevation: 16,
        shadowColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Snackbar Theme - Deep Dark
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkElevated,
        contentTextStyle: const TextStyle(color: darkTextPrimary),
        actionTextColor: darkPrimaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
      ),

      // Progress Indicator Theme - Deep Dark
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: darkPrimaryGreen,
        linearTrackColor: darkBorder,
        circularTrackColor: darkBorder,
      ),

      // Switch Theme - Deep Dark
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return darkPrimaryGreen;
          }
          return darkTextSecondary;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return darkPrimaryGreen.withOpacity(0.5);
          }
          return darkBorder;
        }),
      ),

      // Checkbox Theme - Deep Dark
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return darkPrimaryGreen;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(darkTextPrimary),
        side: const BorderSide(color: darkBorder, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Radio Theme - Deep Dark
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return darkPrimaryGreen;
          }
          return darkBorder;
        }),
      ),

      // Slider Theme - Deep Dark
      sliderTheme: SliderThemeData(
        activeTrackColor: darkPrimaryGreen,
        inactiveTrackColor: darkBorder,
        thumbColor: darkPrimaryGreen,
        overlayColor: darkPrimaryGreen.withOpacity(0.2),
        valueIndicatorColor: darkPrimaryGreen,
        valueIndicatorTextStyle: const TextStyle(color: darkTextPrimary),
      ),

      // Tooltip Theme - Deep Dark
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: darkElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: darkTextPrimary),
      ),

      // Popup Menu Theme - Deep Dark
      popupMenuTheme: PopupMenuThemeData(
        color: darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(color: darkTextPrimary),
      ),

      // Data Table Theme - Deep Dark
      dataTableTheme: DataTableThemeData(
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(12),
        ),
        dataRowColor: MaterialStateProperty.all(Colors.transparent),
        headingRowColor: MaterialStateProperty.all(darkElevated),
        dataTextStyle: const TextStyle(color: darkTextPrimary),
        headingTextStyle: const TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Expansion Tile Theme - Deep Dark
      expansionTileTheme: const ExpansionTileThemeData(
        backgroundColor: darkCard,
        collapsedBackgroundColor: Colors.transparent,
        textColor: darkTextPrimary,
        collapsedTextColor: darkTextSecondary,
        iconColor: darkTextPrimary,
        collapsedIconColor: darkTextSecondary,
      ),

      // Scaffold Background - Deep Dark
      scaffoldBackgroundColor: darkBackground,
      
      // Canvas Color - Deep Dark
      canvasColor: darkBackground,
    );
  }

  // Gradient Backgrounds
  static const Gradient primaryGradient = LinearGradient(
    colors: [primaryGreen, lightGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient harvestGradient = LinearGradient(
    colors: [accentOrange, harvest],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient skyGradient = LinearGradient(
    colors: [skyBlue, lightGreen],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Box Shadows
  static List<BoxShadow> get defaultShadow => [
    const BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    const BoxShadow(
      color: Colors.black26,
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get subtleShadow => [
    const BoxShadow(
      color: Colors.black12,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
}

// Animation Durations
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
}