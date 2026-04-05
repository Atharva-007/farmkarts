import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Screen size breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Check device type
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static double getMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 1200;
    if (isTablet(context)) return 900;
    return MediaQuery.of(context).size.width;
  }

  // Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.all(24);
    if (isTablet(context)) return const EdgeInsets.all(20);
    return const EdgeInsets.all(16);
  }

  // Get responsive horizontal padding
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.symmetric(horizontal: 32);
    if (isTablet(context)) return const EdgeInsets.symmetric(horizontal: 24);
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  // Get responsive spacing
  static double getResponsiveSpacing(BuildContext context) {
    if (isDesktop(context)) return 24;
    if (isTablet(context)) return 20;
    return 16;
  }

  static int getGridCrossAxisCount(
    BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  static double getCardAspectRatio(BuildContext context) {
    if (isDesktop(context)) return 0.85;
    if (isTablet(context)) return 0.9;
    return 1.0;
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 64, vertical: 32);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  static double getFontSize(BuildContext context, double baseSize) {
    if (isDesktop(context)) return baseSize * 1.1;
    if (isTablet(context)) return baseSize * 1.05;
    return baseSize;
  }

  // Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final scaleFactor = MediaQuery.of(context).textScaler.scale(1.0);
    if (isDesktop(context)) return baseSize * 1.1 * scaleFactor;
    if (isTablet(context)) return baseSize * 1.05 * scaleFactor;
    return baseSize * scaleFactor;
  }

  // Get grid columns
  static int getGridColumns(BuildContext context, {int maxColumns = 4}) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return maxColumns;
    if (width >= 900) return maxColumns - 1;
    if (width >= 600) return 2;
    return 2;
  }

  // Wrap content to prevent overflow
  static Widget preventOverflow({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: child,
          ),
        );
      },
    );
  }

  // Safe area wrapper with responsive padding
  static Widget safeAreaWrapper({
    required BuildContext context,
    required Widget child,
    bool addPadding = true,
  }) {
    return SafeArea(
      child: addPadding
          ? Padding(
              padding: getResponsivePadding(context),
              child: child,
            )
          : child,
    );
  }

  // Responsive flexible widget
  static Widget responsiveFlex({
    required List<Widget> children,
    required BuildContext context,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return isMobile(context)
        ? Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: children,
          )
        : Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: children.map((child) => Expanded(child: child)).toList(),
          );
  }

  // Wrap widget to prevent RenderFlex overflow
  static Widget flexibleWrapper({
    required Widget child,
    int flex = 1,
  }) {
    return Flexible(
      flex: flex,
      child: child,
    );
  }

  // Expanded wrapper to prevent overflow
  static Widget expandedWrapper({
    required Widget child,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: child,
    );
  }

  // Get responsive border radius
  static BorderRadius getResponsiveBorderRadius(BuildContext context) {
    if (isDesktop(context)) return BorderRadius.circular(16);
    if (isTablet(context)) return BorderRadius.circular(14);
    return BorderRadius.circular(12);
  }

  // Get responsive text overflow handling
  static TextOverflow getTextOverflow() => TextOverflow.ellipsis;

  // Get responsive max lines
  static int getMaxLines(BuildContext context, {int defaultLines = 1}) {
    if (isDesktop(context)) return defaultLines + 1;
    return defaultLines;
  }

  // Auto-sizing text with overflow protection
  static Widget autoSizeText(
    String text, {
    required BuildContext context,
    TextStyle? style,
    int? maxLines,
    TextAlign textAlign = TextAlign.start,
  }) {
    return Text(
      text,
      style: style,
      maxLines: maxLines ?? getMaxLines(context),
      overflow: getTextOverflow(),
      textAlign: textAlign,
      softWrap: true,
    );
  }

  // Responsive card with overflow protection
  static Widget responsiveCard({
    required Widget child,
    required BuildContext context,
    EdgeInsets? padding,
    double? elevation,
  }) {
    return Card(
      elevation: elevation ?? 2,
      shape: RoundedRectangleBorder(
        borderRadius: getResponsiveBorderRadius(context),
      ),
      child: Padding(
        padding: padding ?? getResponsivePadding(context),
        child: child,
      ),
    );
  }
}

class BreakpointConstraints {
  static const double mobile = 768;
  static const double tablet = 1200;
  static const double desktop = 1200;
}
