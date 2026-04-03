import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/app_constants.dart';
import '../../widgets/universal_drawer.dart';
import '../../widgets/universal_header.dart';

class CropsDashboard extends StatefulWidget {
  const CropsDashboard({super.key});

  @override
  State<CropsDashboard> createState() => _CropsDashboardState();
}

class _CropsDashboardState extends State<CropsDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      drawer: const UniversalDrawer(currentPage: 'crops'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: ResponsiveHelper.getScreenPadding(context),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildCropOverview(),
                  SizedBox(height: AppConstants.getResponsiveSpacing(context)),
                  _buildCropManagementGrid(),
                  SizedBox(height: AppConstants.getResponsiveSpacing(context)),
                  _buildCropHealthMonitoring(),
                  SizedBox(height: AppConstants.getResponsiveSpacing(context)),
                  _buildHarvestPlanning(),
                  SizedBox(height: AppConstants.getResponsiveSpacing(context)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return UniversalHeader(
      title: 'Crops',
      subtitle: 'Manage your crop production',
      icon: Icons.agriculture,
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () => _showComingSoon('Add Crop'),
          tooltip: 'Add Crop',
        ),
      ],
    );
  }

  Widget _buildCropOverview() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppConstants.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crop Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.getResponsiveSpacing(context)),
            LayoutBuilder(
              builder: (context, constraints) {
                if (ResponsiveHelper.isMobile(context)) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildOverviewCard('Active Crops', '12', Icons.eco, AppTheme.primaryGreen)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildOverviewCard('Total Area', '45 acres', Icons.landscape, AppTheme.skyBlue)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildOverviewCard('Health Score', '92%', Icons.favorite, AppTheme.success)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildOverviewCard('Harvest Ready', '3', Icons.agriculture, AppTheme.accentOrange)),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(child: _buildOverviewCard('Active Crops', '12', Icons.eco, AppTheme.primaryGreen)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildOverviewCard('Total Area', '45 acres', Icons.landscape, AppTheme.skyBlue)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildOverviewCard('Health Score', '92%', Icons.favorite, AppTheme.success)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildOverviewCard('Harvest Ready', '3', Icons.agriculture, AppTheme.accentOrange)),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.isDesktop(context) ? 16 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: ResponsiveHelper.isDesktop(context) ? 28 : 24,
          ),
          SizedBox(height: ResponsiveHelper.isDesktop(context) ? 12 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context, 12),
              color: AppTheme.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCropManagementGrid() {
    final managementOptions = [
      {'title': 'Add New Crop', 'icon': Icons.add_circle, 'color': AppTheme.primaryGreen},
      {'title': 'Disease Detection', 'icon': Icons.camera_alt, 'color': AppTheme.error},
      {'title': 'Irrigation Schedule', 'icon': Icons.water_drop, 'color': AppTheme.skyBlue},
      {'title': 'Fertilizer Plan', 'icon': Icons.grass, 'color': AppTheme.lightGreen},
      {'title': 'Pest Control', 'icon': Icons.bug_report, 'color': AppTheme.warning},
      {'title': 'Yield Prediction', 'icon': Icons.trending_up, 'color': AppTheme.accentOrange},
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: AppConstants.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crop Management Tools',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.getResponsiveSpacing(context)),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(
                  context,
                  mobile: 2,
                  tablet: 3,
                  desktop: 3,
                ),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: ResponsiveHelper.getCardAspectRatio(context),
              ),
              itemCount: managementOptions.length,
              itemBuilder: (context, index) {
                final option = managementOptions[index];
                return _buildManagementCard(
                  option['title'] as String,
                  option['icon'] as IconData,
                  option['color'] as Color,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard(String title, IconData icon, Color color) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title feature coming soon!')),
          );
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: ResponsiveHelper.isDesktop(context) ? 28 : 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropHealthMonitoring() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppConstants.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crop Health Monitoring',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.getResponsiveSpacing(context)),
            _buildHealthItem('Wheat Field A', 95, AppTheme.success, 'Excellent'),
            const SizedBox(height: 12),
            _buildHealthItem('Corn Field B', 78, AppTheme.warning, 'Good'),
            const SizedBox(height: 12),
            _buildHealthItem('Rice Field C', 65, AppTheme.error, 'Needs Attention'),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthItem(String cropName, int healthScore, Color color, String status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.eco, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cropName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$healthScore%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(
                width: 60,
                child: LinearProgressIndicator(
                  value: healthScore / 100,
                  backgroundColor: AppTheme.borderGrey,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestPlanning() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppConstants.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Harvest Planning',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.getResponsiveSpacing(context)),
            _buildHarvestItem('Wheat Field A', 'Ready in 5 days', Icons.agriculture, AppTheme.success),
            const SizedBox(height: 12),
            _buildHarvestItem('Corn Field B', 'Ready in 12 days', Icons.grain, AppTheme.warning),
            const SizedBox(height: 12),
            _buildHarvestItem('Rice Field C', 'Ready in 25 days', Icons.grass, AppTheme.info),
          ],
        ),
      ),
    );
  }

  Widget _buildHarvestItem(String cropName, String timeToHarvest, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cropName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  timeToHarvest,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppTheme.textGrey),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }
}