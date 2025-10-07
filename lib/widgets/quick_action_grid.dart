import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../features/marketplace/marketplace_home.dart';
import '../sell_page.dart';

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.shopping_cart,
        title: 'Buy Products',
        subtitle: 'Browse marketplace',
        color: AppTheme.primaryGreen,
        onTap: () => _navigateToMarketplace(context),
      ),
      _QuickAction(
        icon: Icons.sell,
        title: 'Sell Crops',
        subtitle: 'List your produce',
        color: AppTheme.accentOrange,
        onTap: () => _navigateToSell(context),
      ),
      _QuickAction(
        icon: Icons.analytics,
        title: 'Farm Analytics',
        subtitle: 'View insights',
        color: AppTheme.skyBlue,
        onTap: () => _navigateToAnalytics(context),
      ),
      _QuickAction(
        icon: Icons.school,
        title: 'Learn',
        subtitle: 'Educational content',
        color: AppTheme.harvest,
        onTap: () => _navigateToEducation(context),
      ),
      _QuickAction(
        icon: Icons.chat,
        title: 'Expert Chat',
        subtitle: 'Get advice',
        color: AppTheme.freshMint,
        onTap: () => _navigateToExpertChat(context),
      ),
      _QuickAction(
        icon: Icons.camera_alt,
        title: 'Crop Doctor',
        subtitle: 'Diagnose diseases',
        color: AppTheme.earthBrown,
        onTap: () => _navigateToCropDoctor(context),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(context, action);
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, _QuickAction action) {
    return Material(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: AppTheme.borderGrey),
            boxShadow: AppTheme.defaultShadow,
          ),
          padding: AppConstants.defaultPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                action.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                action.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToMarketplace(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MarketplaceHome()),
    );
  }

  void _navigateToSell(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SellPage()),
    );
  }

  void _navigateToAnalytics(BuildContext context) {
    _showAnalytics(context);
  }

  void _navigateToEducation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EducationPage()),
    );
  }

  void _navigateToExpertChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExpertChatPage()),
    );
  }

  void _navigateToCropDoctor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CropDoctorPage()),
    );
  }

  static void _showAnalytics(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.borderGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Farm Analytics',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildAnalyticsCard('Total Revenue', '₹1,25,000', Icons.account_balance_wallet, AppTheme.success),
            const SizedBox(height: 12),
            _buildAnalyticsCard('Active Crops', '15 acres', Icons.agriculture, AppTheme.primaryGreen),
            const SizedBox(height: 12),
            _buildAnalyticsCard('Market Price Avg', '₹45/kg', Icons.trending_up, AppTheme.accentOrange),
            const SizedBox(height: 12),
            _buildAnalyticsCard('Profit Margin', '25%', Icons.percent, AppTheme.skyBlue),
          ],
        ),
      ),
    );
  }

  static Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: AppConstants.defaultPadding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Placeholder pages for quick actions
class EducationPage extends StatelessWidget {
  const EducationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agricultural Education'),
        backgroundColor: AppTheme.harvest,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Education content coming soon!'),
      ),
    );
  }
}

class ExpertChatPage extends StatelessWidget {
  const ExpertChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert Chat'),
        backgroundColor: AppTheme.freshMint,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Expert chat coming soon!'),
      ),
    );
  }
}

class CropDoctorPage extends StatelessWidget {
  const CropDoctorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Doctor'),
        backgroundColor: AppTheme.earthBrown,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Crop doctor coming soon!'),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}