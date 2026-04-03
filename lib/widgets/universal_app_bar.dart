import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UniversalAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;

  const UniversalAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.getAppBarColor(context),
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: AppTheme.getAppBarTextColor(context)),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
              tooltip: 'Back',
              splashRadius: 24,
            )
          : Builder(
              builder: (context) => Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(Icons.menu, color: AppTheme.getAppBarTextColor(context), size: 26),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  tooltip: 'Menu',
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: TextStyle(
            color: AppTheme.getAppBarTextColor(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark 
                ? LinearGradient(
                    colors: [AppTheme.darkSurface, AppTheme.darkBackground],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : AppTheme.primaryGradient,
          ),
          child: SafeArea(
            child: Container(
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.only(left: 56, bottom: 50, right: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkPrimaryGreen.withOpacity(0.15) : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconForTitle(title),
                      color: isDark ? AppTheme.darkPrimaryGreen : Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: bottom,
    );
  }

  IconData _getIconForTitle(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('dashboard') || titleLower.contains('home')) {
      return Icons.home;
    } else if (titleLower.contains('market')) {
      if (titleLower.contains('apmc')) {
        return Icons.business;
      }
      return Icons.store;
    } else if (titleLower.contains('crop')) {
      return Icons.agriculture;
    } else if (titleLower.contains('weather')) {
      return Icons.wb_sunny;
    } else if (titleLower.contains('community')) {
      return Icons.people;
    } else if (titleLower.contains('profile')) {
      return Icons.person;
    } else if (titleLower.contains('order')) {
      return Icons.shopping_bag;
    } else if (titleLower.contains('chat') || titleLower.contains('message')) {
      return Icons.chat_bubble;
    } else if (titleLower.contains('settings')) {
      return Icons.settings;
    } else if (titleLower.contains('ai')) {
      return Icons.psychology;
    }
    return Icons.apps;
  }

  Widget buildNonSliver(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppBar(
      backgroundColor: AppTheme.getAppBarColor(context),
      elevation: 2,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: AppTheme.getAppBarTextColor(context)),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
              tooltip: 'Back',
              splashRadius: 24,
            )
          : Builder(
              builder: (context) => Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(Icons.menu, color: AppTheme.getAppBarTextColor(context), size: 26),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Menu',
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkPrimaryGreen.withOpacity(0.15) : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getIconForTitle(title),
              color: isDark ? AppTheme.darkPrimaryGreen : Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppTheme.getAppBarTextColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: actions,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: isDark 
              ? null
              : AppTheme.primaryGradient,
          color: isDark ? AppTheme.getAppBarColor(context) : null,
        ),
      ),
      bottom: bottom,
    );
  }
}
