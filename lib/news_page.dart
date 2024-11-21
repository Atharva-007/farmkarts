import 'dart:async';
import 'package:flutter/material.dart';

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final ScrollController _scrollController = ScrollController();
  late Timer _scrollTimer;

  final List<Map<String, String>> newsArticles = [
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
  ];

  @override
  void initState() {
    super.initState();
    _startScrolling();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              ),
            ),
          ),
          Column(
            children: [
              // Scrolling Headlines
              Container(
                height: 30,
                color: Colors.black.withOpacity(0.7),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: newsArticles.map((news) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          news['title']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
                  itemCount: newsArticles.length,
                  itemBuilder: (context, index) {
                    final news = newsArticles[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewsDetailPage(news: news),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Image.network(
                                news['image']!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: Container(
                                color: Colors.black.withOpacity(0.6),
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  news['title']!,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
  final Map<String, String> news;

  const NewsDetailPage({required this.news, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(news['title']!),
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                news['title']!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(news['image']!),
              ),
              const SizedBox(height: 10),
              Text(
                news['details']!,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
