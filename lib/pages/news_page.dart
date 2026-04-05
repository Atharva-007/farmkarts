import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final String apiKey =
      'api_live_oLI3hcXISCFyNBcH62iEhHOqZAytCUSc6mpYrQcXat2UfKW8CU02shae';
  List<dynamic> newsArticles = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchLiveNews();
  }

  Future<void> fetchLiveNews() async {
    final url = Uri.parse(
        'https://api.apitube.io/v1/news/everything?per_page=10&language.code=en');
    try {
      final response = await http.get(url, headers: {
        'X-API-Key': apiKey,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (mounted) {
          setState(() {
            newsArticles = jsonData['data'] ?? [];
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Failed to load news: ${response.statusCode}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: $e';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Live News'),
        centerTitle: true,
        backgroundColor: AppTheme.getAppBarColor(context),
        foregroundColor: AppTheme.getAppBarTextColor(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: AppTheme.getPrimaryAccent(context)))
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: AppTheme.error),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppTheme.getSecondaryTextColor(context)),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                              errorMessage = null;
                            });
                            fetchLiveNews();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.getPrimaryAccent(context),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchLiveNews,
                  color: AppTheme.getPrimaryAccent(context),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: newsArticles.length,
                    itemBuilder: (context, index) {
                      final news = newsArticles[index];
                      final title = news['title'] ?? 'No title';
                      final description = news['description'] ?? '';
                      final imageUrl = news['image'] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        elevation: isDark ? 2 : 4,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    NewsDetailPage(news: news),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (imageUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                  child: Image.network(
                                    imageUrl,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 200,
                                        color: AppTheme.getIconBackgroundColor(
                                            context),
                                        child: Center(
                                          child: Icon(Icons.broken_image,
                                              size: 40,
                                              color: AppTheme.getPrimaryAccent(
                                                  context)),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      description,
                                      style: TextStyle(
                                          color: AppTheme.getSecondaryTextColor(
                                              context),
                                          fontSize: 14),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Read More',
                                          style: TextStyle(
                                            color: AppTheme.getPrimaryAccent(
                                                context),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Icon(Icons.arrow_forward,
                                            size: 14,
                                            color: AppTheme.getPrimaryAccent(
                                                context)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class NewsDetailPage extends StatelessWidget {
  final Map<String, dynamic> news;

  const NewsDetailPage({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    final title = news['title'] ?? 'News Detail';
    final content =
        news['content'] ?? news['description'] ?? 'No details available.';
    final imageUrl = news['image'] ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('News Detail'),
        backgroundColor: AppTheme.getAppBarColor(context),
        foregroundColor: AppTheme.getAppBarTextColor(context),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: AppTheme.getIconBackgroundColor(context),
                      child: Center(
                        child: Icon(Icons.broken_image,
                            size: 40,
                            color: AppTheme.getPrimaryAccent(context)),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: AppTheme.getDividerColor(context)),
            const SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.getTextColor(context).withValues(alpha: 0.9),
                  height: 1.6),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
