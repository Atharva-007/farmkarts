class TrendingVideo {
  final String id;
  final String youtubeId;
  final String title;
  final String thumbnail;
  final String duration;
  final String category;
  final DateTime publishedDate;
  final int viewCount;

  TrendingVideo({
    required this.id,
    required this.youtubeId,
    required this.title,
    required this.thumbnail,
    required this.duration,
    required this.category,
    required this.publishedDate,
    required this.viewCount,
  });

  factory TrendingVideo.fromMap(String id, Map<String, dynamic> map) {
    return TrendingVideo(
      id: id,
      youtubeId: map['youtubeId'] ?? '',
      title: map['title'] ?? '',
      thumbnail: map['thumbnail'] ?? '',
      duration: map['duration'] ?? '',
      category: map['category'] ?? 'General',
      publishedDate: (map['publishedDate'] != null)
          ? (map['publishedDate'] as dynamic).toDate()
          : DateTime.now(),
      viewCount: map['viewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'youtubeId': youtubeId,
      'title': title,
      'thumbnail': thumbnail,
      'duration': duration,
      'category': category,
      'publishedDate': publishedDate,
      'viewCount': viewCount,
    };
  }
}
