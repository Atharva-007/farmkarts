import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../utils/responsive_helper.dart';
import '../theme/app_theme.dart';
import '../features/dashboard/dashboard_home.dart';
import 'complete_marketplace_page.dart';
import '../features/crops/ai_crop_page.dart';
import '../features/apmc/enhanced_apmc_market_live_fixed.dart';
import '../features/profile/profile_dashboard.dart';
import '../widgets/universal_drawer.dart';
import '../services/analytics_service.dart';
import '../services/performance_service.dart';

class MainAppLayout extends StatefulWidget {
  final int? initialIndex;
  
  const MainAppLayout({super.key, this.initialIndex});

  @override
  State<MainAppLayout> createState() => _MainAppLayoutState();
}

class _MainAppLayoutState extends State<MainAppLayout> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isDrawerOpen = false;
  late PageController _pageController;
  final Map<int, Widget> _lazyPages = {}; 
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    _pageController = PageController(initialPage: _currentIndex);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackScreenChange(_currentIndex);
    });
  }

  Widget _getPage(int index) {
    if (_lazyPages.containsKey(index)) {
      return _lazyPages[index]!;
    }

    Widget page;
    switch (index) {
      case 0:
        page = DashboardHome(onNavigate: _navigateToPage);
        break;
      case 1:
        page = const CompleteMarketplacePage();
        break;
      case 2:
        page = const AICropPage();
        break;
      case 3:
        page = const EnhancedAPMCMarketLiveFixed();
        break;
      case 4:
        page = const ProfileDashboard();
        break;
      default:
        page = DashboardHome(onNavigate: _navigateToPage);
    }

    _lazyPages[index] = page;
    return page;
  }

  void _trackScreenChange(int index) {
    final screenName = _getScreenName(index);
    Provider.of<AnalyticsService>(context, listen: false).logScreenView(screenName: screenName);
    Provider.of<PerformanceService>(context, listen: false).startScreenTrace(screenName);
  }

  String _getScreenName(int index) {
    switch (index) {
      case 0: return 'DashboardHome';
      case 1: return 'Marketplace';
      case 2: return 'AICropPage';
      case 3: return 'APMC_Market';
      case 4: return 'Profile';
      default: return 'UnknownScreen';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final useSideNav = isDesktop || isTablet;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use a deep color for the scaffold background to avoid white gaps during scaling
    final Color scaffoldBg = isDark ? const Color(0xFF050505) : const Color(0xFF1B5E20);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: scaffoldBg,
      // Drawer is removed here to implement it as a sliding side menu in the body
      body: Stack(
        children: [
          // Background Color / Pattern
          Container(color: scaffoldBg),
          
          Row(
            children: [
              // Side Navigation / Drawer (Integrated into Row for "Push" effect)
              if (!useSideNav)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.fastOutSlowIn,
                  width: _isDrawerOpen ? 280 : 0,
                  child: OverflowBox(
                    minWidth: 0,
                    maxWidth: 280,
                    alignment: Alignment.centerLeft,
                    child: UniversalDrawer(
                      currentPage: _getCurrentPageName(),
                      onNavigate: (index) {
                        _navigateToPage(index);
                        setState(() => _isDrawerOpen = false);
                      },
                    ),
                  ),
                ),

              if (useSideNav)
                _buildNavigationRail(),
              
              // Main Content Area
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.fastOutSlowIn,
                  decoration: BoxDecoration(
                    // Removed solid background color to allow deep scaffoldBg to show through
                    borderRadius: BorderRadius.circular(_isDrawerOpen && !useSideNav ? 40 : 0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_isDrawerOpen && !useSideNav ? 40 : 0),
                    child: Stack(
                      children: [
                        // The Page Content
                        PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                            _trackScreenChange(index);
                          },
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 5,
                          itemBuilder: (context, index) {
                            // Removed Column and SizedBox to allow content to flow under the floating bar
                            // Content can be seen through the translucent nav bar
                            return _getPage(index);
                          },
                        ),

                        // Floating Bottom Navigation (Mobile only)
                        if (!useSideNav)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: _buildBottomNavigationBar(),
                          ),
                        
                        // Tap to close overlay when drawer is open
                        if (_isDrawerOpen && !useSideNav)
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: () => setState(() => _isDrawerOpen = false),
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      extendBody: true,
    );
  }

  String _getCurrentPageName() {
    switch (_currentIndex) {
      case 0: return 'dashboard';
      case 1: return 'marketplace';
      case 2: return 'crops';
      case 3: return 'apmc';
      case 4: return 'profile';
      default: return '';
    }
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: _navigateToPage,
      labelType: NavigationRailLabelType.all,
      backgroundColor: Theme.of(context).cardColor,
      indicatorColor: AppTheme.getPrimaryAccent(context).withOpacity(0.1),
      selectedLabelTextStyle: TextStyle(
        color: AppTheme.getPrimaryAccent(context),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: AppTheme.getSecondaryTextColor(context),
        fontSize: 11,
      ),
      selectedIconTheme: IconThemeData(
        color: AppTheme.getPrimaryAccent(context),
        size: 26,
      ),
      unselectedIconTheme: IconThemeData(
        color: AppTheme.getSecondaryTextColor(context),
        size: 22,
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: Text('Market'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome),
          label: Text('AI Crop'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.business_outlined),
          selectedIcon: Icon(Icons.business),
          label: Text('APMC'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Profile'),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SafeArea(
      bottom: false,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeInBack,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: _isDrawerOpen 
          ? _buildFloatingMenuIcon() 
          : _buildFullBottomNavBar(isDark),
      ),
    );
  }

  Widget _buildFloatingMenuIcon() {
    return Container(
      key: const ValueKey('floating_icon'),
      width: 65,
      height: 65,
      margin: const EdgeInsets.only(bottom: 10, left: 20), // Reduced bottom margin
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => setState(() => _isDrawerOpen = true),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.menu, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildFullBottomNavBar(bool isDark) {
    return Container(
      key: const ValueKey('full_nav_bar'),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0), // Changed bottom margin to 0 to eliminate all white space below
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: AppTheme.getBorderColor(context).withOpacity(isDark ? 0.1 : 0.2), 
          width: 1.0
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.6 : 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 75,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Home'),
                _buildNavItem(1, Icons.storefront_rounded, Icons.storefront_outlined, 'Market'),
                _buildNavItem(2, Icons.agriculture_rounded, Icons.agriculture_outlined, 'Crops'),
                _buildNavItem(3, Icons.business_center_rounded, Icons.business_outlined, 'APMC'),
                _buildNavItem(4, Icons.person_rounded, Icons.person_outline, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    final accentColor = AppTheme.getPrimaryAccent(context);
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _navigateToPage(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                size: isSelected ? 28 : 24,
                color: isSelected
                    ? accentColor
                    : AppTheme.getSecondaryTextColor(context).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? accentColor
                    : AppTheme.getSecondaryTextColor(context).withOpacity(0.6),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPage(int index) {
    if (index != _currentIndex && index >= 0 && index < 5) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastEaseInToSlowEaseOut,
      );
      _trackScreenChange(index);
    }
  }
}
