import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/trending_video_model.dart';
import 'package:rxdart/rxdart.dart';

class TrendingVideoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final TrendingVideoService _instance = TrendingVideoService._internal();
  
  // Replace with your actual backend URL in production
  final String _baseUrl = 'http://localhost:3000/api/videos';

  factory TrendingVideoService() => _instance;
  TrendingVideoService._internal();

  // Collection name
  static const String _collection = 'trending_videos';

  // Get trending videos with optional filtering
  // This version combines videos from trending_videos collection AND from community_posts
  Stream<List<TrendingVideo>> getTrendingVideos({String? category, String? search}) {
    // Stream 1: Trending Videos Collection
    Query trendingQuery = _firestore.collection(_collection);
    if (category != null && category != 'All') {
      trendingQuery = trendingQuery.where('category', isEqualTo: category);
    }
    
    Stream<List<TrendingVideo>> trendingStream = trendingQuery
        .orderBy('publishedDate', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            _seedInitialVideos();
            return _getMockVideos();
          }
          return snapshot.docs
              .map((doc) => TrendingVideo.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList();
        });

    // Stream 2: Videos from Community Feed
    Query feedQuery = _firestore.collection('community_posts')
        .where('isActive', isEqualTo: true);
    
    // Note: Firestore doesn't support where field exists efficiently without a special field
    // We assume posts with videos have a 'videoUrl' field
    
    Stream<List<TrendingVideo>> feedVideosStream = feedQuery
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          final videos = <TrendingVideo>[];
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final videoUrl = data['videoUrl'] as String?;
            if (videoUrl != null && videoUrl.isNotEmpty) {
              // Extract youtubeId if it's a youtube link
              String youtubeId = _extractYoutubeId(videoUrl);
              if (youtubeId.isNotEmpty) {
                videos.add(TrendingVideo(
                  id: doc.id,
                  youtubeId: youtubeId,
                  title: data['content'] ?? 'Community Video',
                  thumbnail: 'https://img.youtube.com/vi/$youtubeId/maxresdefault.jpg',
                  duration: 'Community',
                  category: data['category'] ?? 'Feed',
                  publishedDate: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  viewCount: data['likes'] ?? 0,
                ));
              }
            }
          }
          return videos;
        });

    // Combine both streams
    return CombineLatestStream.combine2<List<TrendingVideo>, List<TrendingVideo>, List<TrendingVideo>>(
      trendingStream,
      feedVideosStream,
      (trending, feed) {
        // Merge and remove duplicates by youtubeId
        final allVideos = [...feed, ...trending];
        final seenIds = <String>{};
        final uniqueVideos = <TrendingVideo>[];
        
        for (var video in allVideos) {
          if (!seenIds.contains(video.youtubeId)) {
            uniqueVideos.add(video);
            seenIds.add(video.youtubeId);
          }
        }
        
        // Sort by date or view count if needed
        uniqueVideos.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
        
        // Filter by search query if provided
        if (search != null && search.isNotEmpty) {
          return uniqueVideos.where((v) => 
            v.title.toLowerCase().contains(search.toLowerCase())
          ).toList();
        }
        
        return uniqueVideos;
      },
    );
  }

  String _extractYoutubeId(String url) {
    if (url.contains('youtu.be/')) {
      return url.split('youtu.be/').last.split('?').first;
    } else if (url.contains('v=')) {
      return url.split('v=').last.split('&').first;
    } else if (url.contains('embed/')) {
      return url.split('embed/').last.split('?').first;
    }
    return '';
  }

  /// NEW: Fetch from Node.js backend for advanced ranking logic
  Future<List<TrendingVideo>> getTrendingFromBackend() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/trending')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List videos = data['data'];
          return videos.map((v) => TrendingVideo.fromMap(v['youtubeId'] ?? v['id'] ?? '', v)).toList();
        }
      }
      return _getMockVideos(); 
    } catch (e) {
      print('Backend error: $e');
      return _getMockVideos();
    }
  }

  // Force update the engine (called on page load)
  Future<void> updateEngine() async {
    try {
      final lastUpdateDoc = await _firestore.collection('system_status').doc('video_engine').get();
      
      bool needsUpdate = true;
      if (lastUpdateDoc.exists) {
        final lastUpdate = (lastUpdateDoc.data()?['lastSync'] as Timestamp).toDate();
        final now = DateTime.now();
        if (lastUpdate.day == now.day && lastUpdate.month == now.month && lastUpdate.year == now.year) {
          needsUpdate = false;
        }
      }

      if (needsUpdate) {
        print('Video Engine: Syncing daily trending content...');
        await _syncTrendingContent();
        await _firestore.collection('system_status').doc('video_engine').set({
          'lastSync': FieldValue.serverTimestamp(),
          'status': 'active',
        });
      }
    } catch (e) {
      print('Video Engine Error: $e');
    }
  }

  Future<void> _syncTrendingContent() async {
    final mockNewVideos = _getMockVideos();
    final batch = _firestore.batch();
    for (var video in mockNewVideos) {
      final docRef = _firestore.collection(_collection).doc(video.youtubeId);
      batch.set(docRef, video.toMap());
    }
    await batch.commit();
  }

  void _seedInitialVideos() {
    _syncTrendingContent();
  }

  List<TrendingVideo> _getMockVideos() {
    final List<Map<String, dynamic>> data = [
      {
        'youtubeId': '6Lp-N8UvN_U',
        'title': 'High Yield Farming Techniques 2026',
        'thumbnail': 'https://img.youtube.com/vi/6Lp-N8UvN_U/maxresdefault.jpg',
        'duration': '12:45',
        'category': 'Education',
        'publishedDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 5))),
        'viewCount': 12500,
      },
      {
        'youtubeId': 'dQw4w9WgXcQ',
        'title': 'Organic Pest Control Strategies',
        'thumbnail': 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
        'duration': '15:20',
        'category': 'Farming Guide',
        'publishedDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'viewCount': 8900,
      },
      {
        'youtubeId': 'y8v99Y1U4rE',
        'title': 'Smart Greenhouse Automation',
        'thumbnail': 'https://img.youtube.com/vi/y8v99Y1U4rE/maxresdefault.jpg',
        'duration': '08:15',
        'category': 'Technology',
        'publishedDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
        'viewCount': 4500,
      },
      {
        'youtubeId': '9W8qE6X_U0U',
        'title': 'Water Conservation: Drip Irrigation',
        'thumbnail': 'https://img.youtube.com/vi/9W8qE6X_U0U/maxresdefault.jpg',
        'duration': '10:30',
        'category': 'Resources',
        'publishedDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
        'viewCount': 21000,
      },
    ];

    return data.map((m) => TrendingVideo.fromMap(m['youtubeId'], m)).toList();
  }
}
