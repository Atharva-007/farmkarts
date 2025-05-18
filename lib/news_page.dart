import 'dart:async';
import 'package:flutter/material.dart';

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late Timer _scrollTimer;

  late AnimationController _animationController;

  final List<Map<String, String?>> newsArticles = [
    {
      'title': 'Government Introduces Subsidy for Organic Farmers',
      'description': 'A new scheme provides financial support for organic farming.',
      'image': 'https://via.placeholder.com/300x200',
      'details': 'The government has announced a subsidy of 30% for farmers adopting organic farming practices. This aims to promote sustainable agriculture and reduce dependency on chemical fertilizers.'
    },
    {
      'title': 'Record High Prices for Wheat in APMC',
      'description': 'Wheat prices surged due to increased demand in the market.',
      'image': 'https://via.placeholder.com/300x200',
      'details': 'The Agricultural Produce Market Committee (APMC) reported record high prices for wheat this season, attributed to increased exports and domestic consumption.'
    },
    {
      'title': 'New Irrigation Technology Launched',
      'description': 'Drip irrigation technology improves water efficiency.',
      'image': 'https://via.placeholder.com/300x200',
      'details': 'A new drip irrigation system promises to save 40% water compared to traditional methods, making it ideal for arid regions.'
    },
    {
      'title': 'Farmers Adopt Precision Farming Tools',
      'description': 'Technology-driven farming sees a rise in adoption.',
      'image': 'https://via.placeholder.com/300x200',
      'details': 'Precision farming tools like GPS trackers and drones are helping farmers improve yield while minimizing costs and environmental impact.'
    },
    // Text-only news (no image)
    {
      'title': 'Monsoon Forecast: Above Normal Rainfall Expected',
      'description': 'Meteorologists predict above average monsoon rainfall this year.',
      'image': null,
      'details': 'This year’s monsoon is expected to be stronger than previous years, potentially benefiting farmers in rain-dependent regions.'
    },
    {
      'title': 'New Crop Insurance Policy Launched',
      'description': 'A new insurance scheme covers more crops and reduces premiums.',
      'image': null,
      'details': 'Farmers can now insure a wider variety of crops under the updated scheme, making protection more affordable.'
    },
    {
      'title': 'Rise in Organic Farming Awareness',
      'description': 'More farmers are adopting organic farming methods for sustainability.',
      'image': null,
      'details': 'The awareness campaigns have led to a significant increase in organic farming, improving soil health and crop quality.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _startScrolling();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Start the fade-in animation when page loads
    _animationController.forward();
  }

  void _startScrolling() {
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_scrollController.hasClients) {
        if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent) {
          _scrollController.jumpTo(0.0);
        } else {
          _scrollController.jumpTo(_scrollController.offset + 1.0);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer.cancel();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyleTitle = const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontSize: 18,
      shadows: [
        Shadow(
          blurRadius: 5,
          color: Colors.black54,
          offset: Offset(1, 1),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
                opacity: 0.7,
              ),
            ),
          ),
          Column(
            children: [
              // Scrolling Headlines with fade animation
              Container(
                height: 40,
                color: Colors.black.withOpacity(0.7),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: newsArticles.map((news) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: FadeTransition(
                          opacity: _animationController,
                          child: Text(
                            news['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: newsArticles.length,
                  itemBuilder: (context, index) {
                    final news = newsArticles[index];
                    final hasImage = news['image'] != null && news['image']!.isNotEmpty;

                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          index / newsArticles.length,
                          1.0,
                          curve: Curves.easeIn,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewsDetailPage(news: news),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: hasImage
                              ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  news['image']!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return SizedBox(
                                      height: 200,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: progress.expectedTotalBytes != null
                                              ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1)
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: Colors.grey[700],
                                      child: const Center(
                                        child: Icon(Icons.broken_image, size: 40, color: Colors.white),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    news['title']!,
                                    style: textStyleTitle,
                                  ),
                                ),
                              ),
                            ],
                          )
                              : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  news['title']!,
                                  style: textStyleTitle.copyWith(fontSize: 20),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  news['description'] ?? '',
                                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NewsDetailPage extends StatelessWidget {
  final Map<String, String?> news;

  const NewsDetailPage({required this.news, super.key});

  @override
  Widget build(BuildContext context) {
    final hasImage = news['image'] != null && news['image']!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(news['title'] ?? 'News Detail'),
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
            opacity: 0.7,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                news['title'] ?? '',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black54,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    news['image']!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[700],
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 40, color: Colors.white),
                        ),
                      );
                    },
                  ),
                ),
              if (hasImage) const SizedBox(height: 20),
              Text(
                news['details'] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
