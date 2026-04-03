import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';

class NewsCarousel extends StatelessWidget {
  const NewsCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final news = [
      _NewsItem(
        title: 'Government launches new subsidy scheme for organic farming',
        summary: 'Farmers can now get up to 50% subsidy on organic fertilizers and equipment.',
        imageUrl: 'https://images.unsplash.com/photo-1500595046743-cd271d694d30?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=400&q=80',
        timeAgo: '2 hours ago',
      ),
      _NewsItem(
        title: 'Record high wheat prices in international markets',
        summary: 'Global wheat shortage drives prices to 15-year high, benefiting Indian farmers.',
        imageUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=400&q=80',
        timeAgo: '5 hours ago',
      ),
      _NewsItem(
        title: 'New drought-resistant crop varieties developed',
        summary: 'Scientists develop climate-resilient seeds that can withstand extreme weather.',
        imageUrl: 'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=400&q=80',
        timeAgo: '1 day ago',
      ),
    ];

    return SizedBox(
      height: ResponsiveHelper.isMobile(context) ? 160 : 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: news.length,
        itemBuilder: (context, index) {
          final newsItem = news[index];
          return _buildNewsCard(context, newsItem);
        },
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, _NewsItem newsItem) {
    final cardWidth = ResponsiveHelper.isMobile(context) ? 240.0 : 260.0;
    final imageHeight = ResponsiveHelper.isMobile(context) ? 70.0 : 80.0;
    
    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: ResponsiveHelper.getResponsiveSpacing(context) * 0.75),
      child: Material(
        borderRadius: ResponsiveHelper.getResponsiveBorderRadius(context),
        child: InkWell(
          onTap: () {
            // Navigate to full news article
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening: ${newsItem.title}')),
            );
          },
          borderRadius: ResponsiveHelper.getResponsiveBorderRadius(context),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: ResponsiveHelper.getResponsiveBorderRadius(context),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(
                      ResponsiveHelper.getResponsiveBorderRadius(context).topLeft.x,
                    ),
                  ),
                  child: Image.network(
                    newsItem.imageUrl,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: imageHeight,
                        color: AppTheme.cardGrey,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: imageHeight,
                        color: AppTheme.cardGrey,
                        child: Icon(
                          Icons.image_not_supported,
                          size: ResponsiveHelper.isMobile(context) ? 25 : 30,
                          color: AppTheme.textGrey,
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: ResponsiveHelper.getResponsivePadding(context).copyWith(
                      top: 12,
                      bottom: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveHelper.autoSizeText(
                          newsItem.title,
                          context: context,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.getFontSize(context, 14),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: ResponsiveHelper.autoSizeText(
                            newsItem.summary,
                            context: context,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textGrey,
                              fontSize: ResponsiveHelper.getFontSize(context, 11),
                            ),
                            maxLines: ResponsiveHelper.isMobile(context) ? 2 : 3,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: ResponsiveHelper.isMobile(context) ? 10 : 12,
                              color: AppTheme.textGrey,
                            ),
                            const SizedBox(width: 4),
                            ResponsiveHelper.autoSizeText(
                              newsItem.timeAgo,
                              context: context,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textGrey,
                                fontSize: ResponsiveHelper.getFontSize(context, 10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewsItem {
  final String title;
  final String summary;
  final String imageUrl;
  final String timeAgo;

  _NewsItem({
    required this.title,
    required this.summary,
    required this.imageUrl,
    required this.timeAgo,
  });
}