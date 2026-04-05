import 'package:flutter/material.dart';
import 'responsive_helper.dart';

class AppConstants {
  // Default values
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets smallPadding = EdgeInsets.all(8.0);
  static const EdgeInsets largePadding = EdgeInsets.all(24.0);

  // Default shadow
  static const List<BoxShadow> defaultShadow = [
    BoxShadow(
      color: Colors.black12,
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
  ];

  // Responsive spacing based on screen size
  static double getResponsiveSpacing(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) return 24.0;
    if (ResponsiveHelper.isTablet(context)) return 20.0;
    return 16.0;
  }

  // Responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 64, vertical: 32);
    }
    if (ResponsiveHelper.isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  // Responsive font sizes
  static double getResponsiveFontSize(
      BuildContext context, double baseFontSize) {
    if (ResponsiveHelper.isDesktop(context)) return baseFontSize + 2;
    if (ResponsiveHelper.isTablet(context)) return baseFontSize + 1;
    return baseFontSize;
  }

  // Card aspect ratios
  static double getCardAspectRatio(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) return 0.85;
    if (ResponsiveHelper.isTablet(context)) return 0.9;
    return 1.0;
  }

  // Grid cross axis count
  static int getGridCrossAxisCount(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) return 4;
    if (ResponsiveHelper.isTablet(context)) return 3;
    return 2;
  }

  // Screen padding
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 64, vertical: 32);
    }
    if (ResponsiveHelper.isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  // Grid columns
  static int getGridColumns(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) return 4;
    if (ResponsiveHelper.isTablet(context)) return 3;
    return 2;
  }
}
