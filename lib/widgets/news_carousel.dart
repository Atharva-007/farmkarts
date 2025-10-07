import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: news.length,
        itemBuilder: (context, index) {
          final newsItem = news[index];
          return _buildNewsCard(context, newsItem);
        },
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, _NewsItem newsItem) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: InkWell(
          onTap: () {
            // Navigate to full news article
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening: ${newsItem.title}')),
            );
          },
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              boxShadow: AppTheme.defaultShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppConstants.borderRadius),
                  ),
                  child: Image.network(
                    newsItem.imageUrl,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100,
                        color: AppTheme.cardGrey,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: AppTheme.textGrey,
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          newsItem.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            newsItem.summary,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textGrey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppTheme.textGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              newsItem.timeAgo,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textGrey,
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