import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Script to seed community posts with video content for the Trending section.
/// This ensures the trending section has real-feed related videos as requested.
Future<void> seedCommunityVideos() async {
  final firestore = FirebaseFirestore.instance;
  
  final List<Map<String, dynamic>> videoPosts = [
    {
      'userId': 'expert_farmer_1',
      'userName': 'Rajesh Kumar',
      'userRole': 'UserRole.farmer',
      'communityType': 'farmer_community',
      'content': 'Check out my new organic wheat farming techniques! Great results this season.',
      'videoUrl': 'https://www.youtube.com/watch?v=q7Spx_ZIn_I',
      'category': 'Education',
      'likes': 45,
      'likedBy': [],
      'commentsCount': 12,
      'timestamp': FieldValue.serverTimestamp(),
      'isActive': true,
    },
    {
      'userId': 'expert_farmer_2',
      'userName': 'Amit Singh',
      'userRole': 'UserRole.farmer',
      'communityType': 'farmer_community',
      'content': 'How I increased my rice yield using smart irrigation. This video explains everything.',
      'videoUrl': 'https://www.youtube.com/watch?v=B_XAnZ_vbeM',
      'category': 'Farming Guide',
      'likes': 89,
      'likedBy': [],
      'commentsCount': 24,
      'timestamp': FieldValue.serverTimestamp(),
      'isActive': true,
    },
    {
      'userId': 'tech_expert_1',
      'userName': 'Suresh Patel',
      'userRole': 'UserRole.vendor',
      'communityType': 'vendor_community',
      'content': 'New solar-powered tractors are here! Seeing them in action in the fields.',
      'videoUrl': 'https://www.youtube.com/watch?v=6X_ZIn_Iq7S',
      'category': 'Technology',
      'likes': 120,
      'likedBy': [],
      'commentsCount': 15,
      'timestamp': FieldValue.serverTimestamp(),
      'isActive': true,
    },
    {
      'userId': 'farmer_3',
      'userName': 'Sunita Devi',
      'userRole': 'UserRole.farmer',
      'communityType': 'farmer_community',
      'content': 'Drip irrigation saved my crops during the heatwave. Highly recommend watching this guide.',
      'videoUrl': 'https://www.youtube.com/watch?v=9W8qE6X_U0U',
      'category': 'Resources',
      'likes': 67,
      'likedBy': [],
      'commentsCount': 8,
      'timestamp': FieldValue.serverTimestamp(),
      'isActive': true,
    }
  ];

  print('Seeding community video posts...');
  
  for (var post in videoPosts) {
    try {
      await firestore.collection('community_posts').add(post);
      print('Added post from ${post['userName']}');
    } catch (e) {
      print('Error adding post: $e');
    }
  }
  
  print('Seeding complete!');
}
