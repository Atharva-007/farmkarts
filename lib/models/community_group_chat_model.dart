import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class CommunityGroupChatMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final UserRole senderRole;
  final String content;
  final DateTime timestamp;
  final List<String>? imageUrls;

  CommunityGroupChatMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.timestamp,
    this.imageUrls,
  });

  factory CommunityGroupChatMessage.fromMap(
      String id, Map<String, dynamic> map) {
    return CommunityGroupChatMessage(
      id: id,
      groupId: map['groupId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Anonymous',
      senderRole: UserRole.values.firstWhere(
        (e) => e.toString() == map['senderRole'],
        orElse: () => UserRole.customer,
      ),
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole.toString(),
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'imageUrls': imageUrls ?? [],
    };
  }
}
