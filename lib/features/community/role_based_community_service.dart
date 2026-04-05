import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/community_group_chat_model.dart';

class RoleBasedCommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Group Chat Methods
  Stream<List<CommunityGroupChatMessage>> getGroupMessages(String groupId) {
    return _firestore
        .collection('crop_groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityGroupChatMessage.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> sendGroupMessage(
      String groupId, CommunityGroupChatMessage message) async {
    final messageData = message.toMap();

    await _firestore
        .collection('crop_groups')
        .doc(groupId)
        .collection('messages')
        .add(messageData);

    // Update last message in the group
    await _firestore.collection('crop_groups').doc(groupId).update({
      'lastMessage': message.content,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'memberCount':
          FieldValue.increment(0), // Placeholder to trigger update if needed
    });
  }

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
      case UserRole.addat:
        communityType = 'vendor_community';
        break;
      case UserRole.admin:
        // Admins can see all communities
        return _firestore
            .collection('community_posts')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots();
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
    String? videoUrl,
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
      'videoUrl': videoUrl,
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
      case UserRole.addat:
        return 'Vendor Community';
      case UserRole.admin:
        return 'All Communities';
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
      case UserRole.addat:
        return 'Network with other vendors, discuss market trends, and grow your business';
      case UserRole.admin:
        return 'Manage and moderate all community activities';
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
        .where('timestamp',
            isGreaterThan: DateTime.now().subtract(const Duration(days: 7)))
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

  // Get expert advice from Firestore
  Stream<QuerySnapshot> getExpertAdvice() {
    return _firestore
        .collection('expert_advice')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }

  // Get success stories from Firestore
  Stream<QuerySnapshot> getSuccessStories() {
    return _firestore
        .collection('success_stories')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }

  // Get list of crop discussion groups
  Stream<QuerySnapshot> getCropGroups() {
    return _firestore
        .collection('crop_groups')
        .orderBy('memberCount', descending: true)
        .snapshots();
  }

  // Like a post
  Future<void> likePost(String postId, String userId) async {
    final postRef = _firestore.collection('community_posts').doc(postId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;

      final likedBy = List<String>.from(snapshot.data()?['likedBy'] ?? []);
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
        transaction.update(postRef, {
          'likes': FieldValue.increment(-1),
          'likedBy': likedBy,
        });
      } else {
        likedBy.add(userId);
        transaction.update(postRef, {
          'likes': FieldValue.increment(1),
          'likedBy': likedBy,
        });
      }
    });
  }
}
