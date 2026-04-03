import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/app_constants.dart';
import '../../widgets/universal_drawer.dart';
import '../../widgets/universal_header.dart';

class AICropPage extends StatefulWidget {
  const AICropPage({super.key});

  @override
  State<AICropPage> createState() => _AICropPageState();
}

class _AICropPageState extends State<AICropPage> with SingleTickerProviderStateMixin {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  _buildAIInsightsHeader(),
                  const SizedBox(height: 20),
                  _buildAIFeaturesGrid(),
                  const SizedBox(height: 24),
                  _buildCropHealthAI(),
                  const SizedBox(height: 24),
                  _buildYieldPredictionAI(),
                  const SizedBox(height: 100), // Space for bottom nav
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return const UniversalHeader(
      title: 'AI Crop Assistant',
      subtitle: 'Smart monitoring & predictions',
      icon: Icons.auto_awesome,
    );
  }

  Widget _buildAIInsightsHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [AppTheme.darkPrimaryGreen.withOpacity(0.2), AppTheme.darkSurface]
            : [AppTheme.primaryGreen.withOpacity(0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.getPrimaryAccent(context).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.getPrimaryAccent(context).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology,
              color: AppTheme.getPrimaryAccent(context),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Field Analysis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Our AI is analyzing your fields in real-time. Check for updates below.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIFeaturesGrid() {
    final features = [
      {'title': 'Disease Scan', 'icon': Icons.camera_alt, 'color': Colors.red, 'desc': 'Scan leaves for diseases'},
      {'title': 'Pest Alert', 'icon': Icons.bug_report, 'color': Colors.orange, 'desc': 'Nearby pest outbreaks'},
      {'title': 'Smart Water', 'icon': Icons.water_drop, 'color': Colors.blue, 'desc': 'AI irrigation planning'},
      {'title': 'Soil Health', 'icon': Icons.grass, 'color': Colors.green, 'desc': 'NPK level predictions'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.isMobile(context) ? 2 : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(
          feature['title'] as String,
          feature['icon'] as IconData,
          feature['color'] as Color,
          feature['desc'] as String,
        );
      },
    );
  }

  Widget _buildFeatureCard(String title, IconData icon, Color color, String desc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 0,
      color: isDark ? AppTheme.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.getBorderColor(context).withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () => _showAIAction(title),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropHealthAI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('AI Health Monitoring'),
        const SizedBox(height: 12),
        _buildHealthTile('Wheat (North)', 92, 'Optimal Growth'),
        const SizedBox(height: 8),
        _buildHealthTile('Rice (Central)', 64, 'Needs Nitrogen'),
        const SizedBox(height: 8),
        _buildHealthTile('Sugarcane', 88, 'Stable'),
      ],
    );
  }

  Widget _buildHealthTile(String name, int score, String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = score > 80 ? Colors.green : (score > 50 ? Colors.orange : Colors.red);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircularProgressIndicator(
            value: score / 100,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeWidth: 6,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$score%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYieldPredictionAI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('AI Yield Prediction'),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.getBorderColor(context).withOpacity(0.05)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Expected Total Harvest'),
                    Text(
                      '24.5 Tons',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getPrimaryAccent(context),
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const LinearProgressIndicator(
                  value: 0.75,
                  minHeight: 10,
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Confidence: 88%', style: TextStyle(fontSize: 12, color: AppTheme.getSecondaryTextColor(context))),
                    Text('Market Potential: High', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.getTextColor(context),
      ),
    );
  }

  void _showAIAction(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting AI $feature...'),
        backgroundColor: AppTheme.getPrimaryAccent(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
