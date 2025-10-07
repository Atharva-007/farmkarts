import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../marketplace/marketplace_home.dart';
import '../weather/weather_dashboard.dart';
import '../crops/crops_dashboard.dart';
import '../community/community_dashboard.dart';
import '../profile/profile_dashboard.dart';
import 'dashboard_home.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _pages = [
    const DashboardHome(),
    const MarketplaceHome(),
    const WeatherDashboard(),
    const CropsDashboard(),
    const CommunityDashboard(),
    const ProfileDashboard(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      activeIcon: Icon(Icons.dashboard_outlined),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.storefront),
      activeIcon: Icon(Icons.storefront_outlined),
      label: 'Marketplace',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.cloud),
      activeIcon: Icon(Icons.cloud_outlined),
      label: 'Weather',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.agriculture),
      activeIcon: Icon(Icons.agriculture_outlined),
      label: 'Crops',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.people),
      activeIcon: Icon(Icons.people_outline),
      label: 'Community',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      activeIcon: Icon(Icons.person_outline),
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: AppTheme.defaultShadow,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          items: _navItems,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: AppTheme.textGrey,
          backgroundColor: AppTheme.surfaceWhite,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
        ),
      ),
    );
  }
}