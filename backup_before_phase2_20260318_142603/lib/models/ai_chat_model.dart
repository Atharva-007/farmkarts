import 'package:flutter/material.dart';

class AIResponse {
  final String answer;
  final double confidence;
  final List<String> sources;
  final String model;
  final int retrievalCount;
  final double processingTime;
  final String timestamp;
  final String? userId;
  final String? requestTimestamp;

  AIResponse({
    required this.answer,
    required this.confidence,
    required this.sources,
    required this.model,
    required this.retrievalCount,
    required this.processingTime,
    required this.timestamp,
    this.userId,
    this.requestTimestamp,
  });

  factory AIResponse.fromMap(Map<String, dynamic> map) {
    print('AIResponse.fromMap called with: $map'); // Debug log
    return AIResponse(
      answer: map['answer'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      sources: List<String>.from(map['sources'] ?? []),
      model: map['model'] ?? 'unknown',
      retrievalCount: map['retrievalCount'] ?? map['retrieval_count'] ?? 0,
      processingTime: (map['processingTime'] ?? map['processing_time'] ?? 0.0).toDouble(),
      timestamp: map['timestamp'] ?? DateTime.now().toIso8601String(),
      userId: map['userId'] ?? map['user_id'],
      requestTimestamp: map['requestTimestamp'] ?? map['request_timestamp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'answer': answer,
      'confidence': confidence,
      'sources': sources,
      'model': model,
      'retrieval_count': retrievalCount,
      'processing_time': processingTime,
      'timestamp': timestamp,
      'user_id': userId,
      'request_timestamp': requestTimestamp,
    };
  }
}

class AIChatSession {
  final String id;
  final String userId;
  final String title;
  final String category;
  final DateTime createdAt;
  final DateTime lastMessageTime;
  final String lastMessage;
  final int messageCount;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  AIChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.createdAt,
    required this.lastMessageTime,
    required this.lastMessage,
    required this.messageCount,
    this.isActive = true,
    this.metadata,
  });

  factory AIChatSession.fromMap(String id, Map<String, dynamic> map) {
    return AIChatSession(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Untitled Chat',
      category: map['category'] ?? 'General',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastMessageTime: DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'] ?? 0),
      lastMessage: map['lastMessage'] ?? '',
      messageCount: map['messageCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'category': category,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'lastMessage': lastMessage,
      'messageCount': messageCount,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  AIChatSession copyWith({
    String? id,
    String? title,
    String? category,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? messageCount,
    bool? isActive,
  }) {
    return AIChatSession(
      id: id ?? this.id,
      userId: userId,
      title: title ?? this.title,
      category: category ?? this.category,
      createdAt: createdAt,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessage: lastMessage ?? this.lastMessage,
      messageCount: messageCount ?? this.messageCount,
      isActive: isActive ?? this.isActive,
      metadata: metadata,
    );
  }
}

class AIChatMessage {
  final String id;
  final String sessionId;
  final String content;
  final AIChatMessageType type;
  final DateTime timestamp;
  final String? userId; // null for AI responses
  final double? confidence; // for AI responses
  final List<String>? sources; // for AI responses
  final Map<String, dynamic>? metadata;

  AIChatMessage({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.userId,
    this.confidence,
    this.sources,
    this.metadata,
  });

  factory AIChatMessage.fromMap(String id, Map<String, dynamic> map) {
    print('Creating AIChatMessage from map: $map'); // Debug log
    
    // Handle timestamp conversion
    DateTime timestamp;
    final timestampValue = map['timestamp'];
    if (timestampValue is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue);
    } else if (timestampValue != null) {
      // Handle Firestore Timestamp
      try {
        timestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue.millisecondsSinceEpoch ?? 0);
      } catch (e) {
        print('Error parsing timestamp: $e');
        timestamp = DateTime.now();
      }
    } else {
      timestamp = DateTime.now();
    }
    
    return AIChatMessage(
      id: id,
      sessionId: map['sessionId'] ?? '',
      content: map['content'] ?? '',
      type: AIChatMessageType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => AIChatMessageType.user,
      ),
      timestamp: timestamp,
      userId: map['userId'],
      confidence: map['confidence']?.toDouble(),
      sources: map['sources'] != null ? List<String>.from(map['sources']) : null,
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'userId': userId,
      'confidence': confidence,
      'sources': sources,
      'metadata': metadata,
    };
  }

  bool get isFromUser => type == AIChatMessageType.user;
  bool get isFromAI => type == AIChatMessageType.ai;
  bool get isSystemMessage => type == AIChatMessageType.system;

  AIChatMessage copyWith({
    String? content,
    double? confidence,
    List<String>? sources,
  }) {
    return AIChatMessage(
      id: id,
      sessionId: sessionId,
      content: content ?? this.content,
      type: type,
      timestamp: timestamp,
      userId: userId,
      confidence: confidence ?? this.confidence,
      sources: sources ?? this.sources,
      metadata: metadata,
    );
  }
}

enum AIChatMessageType {
  user,
  ai,
  system,
}

class AIChatCategory {
  static const String general = 'General';
  static const String crops = 'Crops';
  static const String weather = 'Weather';
  static const String market = 'Market';
  static const String farming = 'Farming';
  static const String equipment = 'Equipment';
  static const String fertilizers = 'Fertilizers';
  static const String pestControl = 'Pest Control';
  static const String irrigation = 'Irrigation';
  static const String seeds = 'Seeds';
  static const String livestock = 'Livestock';
  static const String soilHealth = 'Soil Health';
  static const String finance = 'Finance';
  static const String government = 'Government Schemes';

  static const List<String> allCategories = [
    general,
    crops,
    weather,
    market,
    farming,
    equipment,
    fertilizers,
    pestControl,
    irrigation,
    seeds,
    livestock,
    soilHealth,
    finance,
    government,
  ];

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'crops':
        return Icons.agriculture;
      case 'weather':
        return Icons.wb_sunny;
      case 'market':
        return Icons.storefront;
      case 'farming':
        return Icons.grass;
      case 'equipment':
        return Icons.construction;
      case 'fertilizers':
        return Icons.science;
      case 'pest control':
        return Icons.pest_control;
      case 'irrigation':
        return Icons.water_drop;
      case 'seeds':
        return Icons.eco;
      case 'livestock':
        return Icons.pets;
      case 'soil health':
        return Icons.terrain;
      case 'finance':
        return Icons.attach_money;
      case 'government schemes':
        return Icons.account_balance;
      default:
        return Icons.chat;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'crops':
        return Colors.green;
      case 'weather':
        return Colors.orange;
      case 'market':
        return Colors.blue;
      case 'farming':
        return Colors.teal;
      case 'equipment':
        return Colors.grey;
      case 'fertilizers':
        return Colors.purple;
      case 'pest control':
        return Colors.red;
      case 'irrigation':
        return Colors.cyan;
      case 'seeds':
        return Colors.lightGreen;
      case 'livestock':
        return Colors.brown;
      case 'soil health':
        return Colors.amber;
      case 'finance':
        return Colors.indigo;
      case 'government schemes':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }
}

class AIExpertPrompts {
  static const List<String> quickPrompts = [
    "What's the best time to plant wheat?",
    "How can I improve my soil quality?",
    "What are the current market prices for rice?",
    "How to prevent pest attacks on crops?",
    "Which fertilizer is best for vegetables?",
    "How to set up drip irrigation?",
    "What government schemes are available for farmers?",
    "How to increase crop yield?",
    "Best practices for organic farming",
    "How to manage crop diseases?",
  ];

  static const List<String> categories = AIChatCategory.allCategories;

  static List<String> getPromptsForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'crops':
        return [
          "What crops grow best in my region?",
          "How to rotate crops for better yield?",
          "Best time to harvest tomatoes?",
          "How to grow organic vegetables?",
        ];
      case 'weather':
        return [
          "How will rain affect my crops?",
          "Best farming practices during drought?",
          "How to protect crops from hail?",
          "Weather forecast for farming?",
        ];
      case 'market':
        return [
          "Current market prices for wheat?",
          "Best time to sell my produce?",
          "How to find buyers for my crops?",
          "Market trends for vegetables?",
        ];
      case 'farming':
        return [
          "Modern farming techniques?",
          "How to increase crop productivity?",
          "Best farming equipment for small farms?",
          "Sustainable farming practices?",
        ];
      default:
        return quickPrompts.take(4).toList();
    }
  }
}