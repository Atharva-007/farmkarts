import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class RoleBasedCommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get community feed based on user role
  Stream<QuerySnapshot> getCommunityFeed(UserRole role) {
    String communityType;
    
    switch (role) {
      case UserRole.farmer:
      case UserRole.customer:
        communityType = 'farmer_community';
        break;
      case UserRole.vendor:
      case UserRole.wholesaler:
        communityType = 'vendor_community';
        break;
      case UserRole.admin:
        // Admins can see all communities
        return _firestore
            .collection('community_posts')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots();
      default:
        communityType = 'farmer_community';
    }

    return _firestore
        .collection('community_posts')
        .where('communityType', isEqualTo: communityType)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  // Create a post in the appropriate community
  Future<void> createPost({
    required String userId,
    required String userName,
    required UserRole userRole,
    required String content,
    List<String>? imageUrls,
    String? category,
  }) async {
    String communityType;
    
    if (userRole == UserRole.farmer || userRole == UserRole.customer) {
      communityType = 'farmer_community';
    } else if (userRole == UserRole.vendor || userRole == UserRole.wholesaler) {
      communityType = 'vendor_community';
    } else {
      communityType = 'general';
    }

    await _firestore.collection('community_posts').add({
      'userId': userId,
      'userName': userName,
      'userRole': userRole.toString(),
      'communityType': communityType,
      'content': content,
      'imageUrls': imageUrls ?? [],
      'category': category ?? 'general',
      'likes': 0,
      'likedBy': [],
      'commentsCount': 0,
      'timestamp': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  // Get community name based on role
  String getCommunityName(UserRole role) {
    switch (role) {
      case UserRole.farmer:
      case UserRole.customer:
        return 'Farmer Community';
      case UserRole.vendor:
      case UserRole.wholesaler:
        return 'Vendor Community';
      case UserRole.admin:
        return 'All Communities';
      default:
        return 'Community';
    }
  }

  // Get community description based on role
  String getCommunityDescription(UserRole role) {
    switch (role) {
      case UserRole.farmer:
      case UserRole.customer:
        return 'Connect with fellow farmers, share experiences, and learn best practices';
      case UserRole.vendor:
      case UserRole.wholesaler:
        return 'Network with other vendors, discuss market trends, and grow your business';
      case UserRole.admin:
        return 'Manage and moderate all community activities';
      default:
        return 'Share and connect with the community';
    }
  }

  // Get trending topics for the community
  Future<List<String>> getTrendingTopics(UserRole role) async {
    String communityType;
    
    if (role == UserRole.farmer || role == UserRole.customer) {
      communityType = 'farmer_community';
    } else if (role == UserRole.vendor || role == UserRole.wholesaler) {
      communityType = 'vendor_community';
    } else {
      return ['All Topics'];
    }

    final snapshot = await _firestore
        .collection('community_posts')
        .where('communityType', isEqualTo: communityType)
        .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(days: 7)))
        .limit(100)
        .get();

    final Map<String, int> categoryCount = {};
    
    for (var doc in snapshot.docs) {
      final category = doc.data()['category'] as String? ?? 'general';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }

    final sortedCategories = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.take(5).map((e) => e.key).toList();
  }
}
