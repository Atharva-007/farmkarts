import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';

class UniversalHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget>? actions;
  final double? expandedHeight;
  final Widget? bottom;
  final bool alignRight;
  final bool showBackButton;
  
  const UniversalHeader({
    super.key,
    required this.title,
    this.subtitle = '',
    this.icon = Icons.dashboard,
    this.actions,
    this.expandedHeight,
    this.bottom,
    this.alignRight = false,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SliverAppBar(
      expandedHeight: expandedHeight ?? (isDesktop ? 180 : 150),
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryGreen,
      stretch: true,
      leading: showBackButton
          ? Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: isDark ? AppTheme.darkPrimaryGreen : Colors.white, size: 26),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
                splashRadius: 20,
                padding: EdgeInsets.zero,
              ),
            )
          : Builder(
              builder: (context) => Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(Icons.menu, color: isDark ? AppTheme.darkPrimaryGreen : Colors.white, size: 26),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Menu',
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                ),
        ),
      ),
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                ? [
                    AppTheme.darkSurface,
                    AppTheme.darkBackground,
                    AppTheme.darkCard,
                  ]
                : [
                    AppTheme.primaryGreen,
                    AppTheme.lightGreen,
                    AppTheme.darkGreen,
                  ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                ResponsiveHelper.isMobile(context) ? 16 : 20,
                ResponsiveHelper.isMobile(context) ? 4 : 8,
                ResponsiveHelper.isMobile(context) ? 16 : 20,
                ResponsiveHelper.isMobile(context) ? 12 : 16,
              ),
              child: Column(
                crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (!alignRight) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkPrimaryGreen.withOpacity(0.15) : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: isDark ? AppTheme.darkPrimaryGreen : Colors.white,
                            size: isDesktop ? 32 : 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: isDark ? Colors.white : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isDesktop ? 28 : 24,
                              ),
                              textAlign: alignRight ? TextAlign.right : TextAlign.left,
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark ? AppTheme.darkTextSecondary : Colors.white.withOpacity(0.9),
                                  fontSize: isDesktop ? 14 : 13,
                                ),
                                textAlign: alignRight ? TextAlign.right : TextAlign.left,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (alignRight) ...[
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkPrimaryGreen.withOpacity(0.15) : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: isDark ? AppTheme.darkPrimaryGreen : Colors.white,
                            size: isDesktop ? 32 : 28,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        titlePadding: EdgeInsets.zero,
        centerTitle: false,
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
      ),
    );
  }
}
