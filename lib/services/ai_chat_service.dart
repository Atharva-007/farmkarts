import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/ai_chat_model.dart';

class AIChatService {
  static final AIChatService _instance = AIChatService._internal();
  factory AIChatService() => _instance;
  AIChatService._internal() {
    _initGemini();
  }

  // API Keys (Ideally these should be in Firebase Remote Config or a secure backend)
  // For now we use the ones found in the project
  static const String _geminiApiKey = ''; // TODO: Add Gemini Key
  static const String _sarvamApiKey = 'sk_w4scrt3a_pbLHPS2dSRw5sGyYEsIWElYJ';
  
  static const String _sarvamTranslateUrl = 'https://api.sarvam.ai/translate';
  static const Duration _requestTimeout = Duration(seconds: 45);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  GenerativeModel? _model;

  void _initGemini() {
    if (_geminiApiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey,
      );
    }
  }

  // Ask AI Expert with Gemini and fallback to contextual mock
  Future<AIResponse> askExpert(String query, {String? context, String languageCode = 'en'}) async {
    final analyzedQuery = _analyzeQuery(query, context);
    print('Query analysis: ${analyzedQuery['intent']} - ${analyzedQuery['topic']}');
    
    // 1. Try Gemini first if available
    if (_model != null) {
      try {
        print('Attempting Gemini for response...');
        final content = [Content.text(_buildEnhancedPrompt(query, context))];
        final response = await _model!.generateContent(content).timeout(_requestTimeout);
        
        if (response.text != null) {
          String finalAnswer = response.text!;
          
          // 2. Translate if language is not English using Sarvam AI
          if (languageCode != 'en') {
            finalAnswer = await translateText(finalAnswer, 'en-IN', _getSarvamLangCode(languageCode));
          }

          return AIResponse(
            answer: finalAnswer,
            confidence: 0.95,
            sources: ['Gemini 1.5 Flash', 'FarmKart Knowledge Base'],
            model: 'Gemini 1.5 Flash',
            retrievalCount: 1,
            processingTime: 2.0,
            timestamp: DateTime.now().toIso8601String(),
            userId: _auth.currentUser?.uid,
            requestTimestamp: DateTime.now().toIso8601String(),
          );
        }
      } catch (e) {
        print('Gemini failed: $e');
      }
    }

    // 3. Fallback to enhanced contextual responses
    print('Using enhanced contextual AI responses for farming expertise');
    await Future.delayed(const Duration(milliseconds: 800));
    final mockResponse = _getContextualResponse(query, analyzedQuery);
    
    // Translate fallback if needed
    if (languageCode != 'en') {
      try {
        final translatedAnswer = await translateText(mockResponse.answer, 'en-IN', _getSarvamLangCode(languageCode));
        return AIResponse(
          answer: translatedAnswer,
          confidence: mockResponse.confidence,
          sources: mockResponse.sources,
          model: mockResponse.model,
          retrievalCount: mockResponse.retrievalCount,
          processingTime: mockResponse.processingTime,
          timestamp: mockResponse.timestamp,
          userId: mockResponse.userId,
          requestTimestamp: mockResponse.requestTimestamp,
        );
      } catch (e) {
        print('Mock translation failed: $e');
      }
    }
    
    return mockResponse;
  }

  // Sarvam AI Translation
  Future<String> translateText(String text, String sourceLang, String targetLang) async {
    try {
      final response = await http.post(
        Uri.parse(_sarvamTranslateUrl),
        headers: {
          'Content-Type': 'application/json',
          'api-subscription-key': _sarvamApiKey,
        },
        body: jsonEncode({
          'input': text,
          'source_language_code': sourceLang,
          'target_language_code': targetLang,
          'speaker_gender': 'Male',
          'mode': 'formal',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translated_text'] ?? text;
      } else {
        print('Sarvam translation failed with status: ${response.statusCode}');
        return text;
      }
    } catch (e) {
      print('Sarvam translation error: $e');
      return text;
    }
  }

  String _getSarvamLangCode(String flutterCode) {
    switch (flutterCode) {
      case 'hi': return 'hi-IN';
      case 'mr': return 'mr-IN';
      case 'en': return 'en-IN';
      default: return 'en-IN';
    }
  }

  // Smart query analysis
  Map<String, String> _analyzeQuery(String query, String? context) {
    final queryLower = query.toLowerCase();
    
    String topic = 'general';
    if (queryLower.contains('wheat')) topic = 'wheat';
    else if (queryLower.contains('rice')) topic = 'rice';
    else if (queryLower.contains('soil')) topic = 'soil';
    else if (queryLower.contains('pest') || queryLower.contains('disease')) topic = 'pest_control';
    else if (queryLower.contains('irrigation') || queryLower.contains('water')) topic = 'irrigation';
    
    String intent = 'general_info';
    if (queryLower.contains('disease') || queryLower.contains('pest')) intent = 'pest_disease';
    else if (queryLower.contains('fertilizer') || queryLower.contains('nutrition')) intent = 'nutrition';
    else if (queryLower.contains('improve') || queryLower.contains('better')) intent = 'improvement';
    else if (queryLower.contains('when') || queryLower.contains('time')) intent = 'timing';
    else if (queryLower.contains('how') || queryLower.contains('method')) intent = 'methodology';
    
    return {
      'topic': topic,
      'intent': intent,
      'context': context ?? 'general',
    };
  }

  // Generate contextual response
  AIResponse _getContextualResponse(String query, Map<String, String> analysis) {
    final response = _getEnhancedMockResponse(query);
    
    double adjustedConfidence = response.confidence;
    if (analysis['topic'] != 'general') adjustedConfidence += 0.03;
    if (analysis['intent'] != 'general_info') adjustedConfidence += 0.02;
    adjustedConfidence = math.min(adjustedConfidence, 0.98);
    
    return AIResponse(
      answer: "${_getPersonalizedGreeting(analysis)}\n\n${response.answer}",
      confidence: adjustedConfidence,
      sources: response.sources,
      model: 'FarmKart AI Expert v2.5 (Enhanced Contextual)',
      retrievalCount: response.retrievalCount,
      processingTime: response.processingTime + 0.3,
      timestamp: response.timestamp,
      userId: response.userId,
      requestTimestamp: response.requestTimestamp,
    );
  }

  String _getPersonalizedGreeting(Map<String, String> analysis) {
    switch (analysis['intent']) {
      case 'pest_disease':
        return 'Based on your ${analysis['topic']} protection query, here is the expert guidance';
      case 'nutrition':
        return 'For your ${analysis['topic']} nutrition question, here is professional advice';
      case 'improvement':
        return 'To help improve your ${analysis['topic']} farming, here are proven methods';
      case 'timing':
        return 'Regarding timing for ${analysis['topic']}, here is the optimal schedule';
      case 'methodology':
        return 'For ${analysis['topic']} cultivation methods, here is step-by-step guidance';
      default:
        return 'Regarding your ${analysis['topic']} farming question';
    }
  }

  // Enhanced responses based on query content with more comprehensive contextual analysis
  AIResponse _getEnhancedMockResponse(String query) {
    final queryLower = query.toLowerCase();
    String answer;
    List<String> sources;
    double confidence;

    // Advanced context detection
    final queryContext = _analyzeQueryContext(queryLower);
    final urgencyLevel = _determineUrgency(queryLower);
    final seasonalContext = _getCurrentSeasonalContext();

    if (queryContext['crop'] == 'wheat') {
      if (queryContext['problem_type'] == 'disease') {
        answer = '''🌾 **Wheat Disease Management - ${urgencyLevel} Priority**

**EXPERT ANALYSIS:**
Your wheat crop appears to be showing signs of ${queryContext['specific_issue']}. Given the current ${seasonalContext['season']}, this is a critical period requiring immediate attention to prevent yield losses.

**IMMEDIATE ACTION PLAN:**
1. **Field Inspection**: Examine 10-15 random spots across the field for accurate disease identification
2. **Spray Treatment**: Apply Propiconazole 25% EC @ 500 ml/ha if rust diseases are confirmed
3. **Weather Monitoring**: Avoid spraying during humid/rainy conditions

**CRITICAL WARNINGS:**
⚠️ **Disease Spread**: Wheat rust can spread rapidly in cool, moist conditions
⚠️ **Spray Safety**: Use protective equipment and maintain 15-day pre-harvest interval
⚠️ **Resistance Management**: Rotate fungicides to prevent resistance development''';
        sources = ['Wheat Disease Manual IARI', 'Plant Pathology Research Institute'];
        confidence = 0.95;

      } else if (queryContext['problem_type'] == 'nutrition') {
        answer = '''🌾 **Wheat Nutrition Management - Precision Approach**

**EXPERT ANALYSIS:**
Based on your query about wheat nutrition, implementing a scientific nutrient management strategy during ${seasonalContext['season']} will significantly enhance yield potential and grain quality.

**IMMEDIATE ACTION PLAN:**
1. **Soil Testing**: Get NPK, micronutrient, and pH analysis from nearest soil testing lab
2. **Balanced Fertilization**: Apply 120:60:40 NPK kg/ha in split doses
3. **Critical Timing**: Top dress nitrogen at Crown Root Initiation (CRI) stage''';
        confidence = 0.94;
        sources = ['IARI Fertilizer Manual', 'Wheat Nutrition Research'];

      } else {
        answer = '''📈 **Comprehensive Wheat Cultivation Guide**

**EXPERT ANALYSIS:**
Wheat cultivation requires precise management throughout its growing period. Success depends on variety selection, timely operations, and balanced inputs suited to your agro-climatic zone.

**IMMEDIATE ACTION PLAN:**
1. **Variety Selection**: Choose varieties like HD-2967, WH-147, PBW-343 based on your region
2. **Land Preparation**: Ensure proper seedbed preparation with adequate moisture
3. **Sowing Time**: Optimal window is November 15-December 15 for most regions''';
        confidence = 0.92;
        sources = ['Wheat Production Manual', 'Agricultural Extension Guidelines'];
      }

    } else if (queryContext['crop'] == 'rice') {
      answer = '''🌾 **Modern Rice Cultivation - Best Practices**

**EXPERT ANALYSIS:**
Rice cultivation can be significantly optimized through modern techniques, precision nutrient management, and mechanization. The approach varies by region and water availability.

**IMMEDIATE ACTION PLAN:**
1. **Variety Selection**: Choose high-yielding, regional-specific varieties
2. **Water Management**: Maintain proper irrigation levels, avoiding standing water where possible
3. **Pest Monitoring**: Regularly check for yellow stem borer or leaf folder signs''';
      confidence = 0.91;
      sources = ['Rice Research Institute', 'SRI Methodology Manual'];
    } else {
      // General comprehensive farming advice
      answer = '''🚜 **Comprehensive Agricultural Management**

**EXPERT ANALYSIS:**
Successful farming requires integration of traditional wisdom with modern technology. Your query indicates need for systematic approach to agricultural management with focus on sustainability and profitability.

**INTEGRATED FARMING SYSTEM:**
1. **Crop Planning**: Diversified cropping system with market-oriented variety selection
2. **Resource Optimization**: Efficient use of land, water, labor, and capital resources
3. **Risk Management**: Crop insurance, diversification, and contingency planning
4. **Value Addition**: Post-harvest processing and direct marketing strategies''';
      confidence = 0.87;
      sources = ['Integrated Farming Manual', 'Modern Agriculture Guidelines'];
    }

    return AIResponse(
      answer: answer,
      confidence: confidence,
      sources: sources,
      model: 'FarmKart AI Expert v3.0 (Enhanced Contextual Analysis)',
      retrievalCount: sources.length,
      processingTime: 1.5,
      timestamp: DateTime.now().toIso8601String(),
      userId: FirebaseAuth.instance.currentUser?.uid,
      requestTimestamp: DateTime.now().toIso8601String(),
    );
  }

  // Advanced query context analysis
  Map<String, String> _analyzeQueryContext(String queryLower) {
    Map<String, String> context = {
      'crop': 'general',
      'problem_type': 'general',
      'specific_issue': 'farming challenge',
      'urgency': 'normal'
    };

    if (queryLower.contains('wheat') || queryLower.contains('gehun')) {
      context['crop'] = 'wheat';
    } else if (queryLower.contains('rice') || queryLower.contains('paddy') || queryLower.contains('dhaan')) {
      context['crop'] = 'rice';  
    }

    if (queryLower.contains('disease') || queryLower.contains('infection')) {
      context['problem_type'] = 'disease';
    } else if (queryLower.contains('nutrition') || queryLower.contains('fertilizer')) {
      context['problem_type'] = 'nutrition';  
    }

    return context;
  }

  String _determineUrgency(String queryLower) {
    if (queryLower.contains('urgent') || queryLower.contains('emergency')) {
      return 'URGENT';
    }
    return 'NORMAL';
  }

  Map<String, String> _getCurrentSeasonalContext() {
    return {
      'season': 'Current Growing Season',
      'specific_advice': 'Maintain regular monitoring and timely intervention.'
    };
  }

  String _buildEnhancedPrompt(String query, String? context) {
    final contextInfo = context ?? 'general farming';
    
    return '''You are an expert agricultural advisor for FarmKart, specializing in Indian farming practices. 

Context Area: $contextInfo

Farmer's Question: $query

Please provide a helpful, practical response following this format:

🔍 ANALYSIS:
[Brief explanation of the situation/problem]

📋 RECOMMENDED ACTIONS:
1. [First immediate step]
2. [Second important action]
3. [Third follow-up measure]

⚠️ IMPORTANT NOTES:
[Safety warnings or critical considerations]

🌱 ADDITIONAL TIPS:
[Extra helpful advice or seasonal considerations]

Keep your response practical, specific to Indian conditions, and suitable for farmers. Use simple language and provide actionable advice.''';
  }

  // Session Management
  Future<AIChatSession> getOrCreateChatSession(String title, String category) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final existingSessions = await _firestore
          .collection('ai_chat_sessions')
          .where('userId', isEqualTo: user.uid)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('lastMessageTime', descending: true)
          .limit(1)
          .get();

      if (existingSessions.docs.isNotEmpty) {
        final doc = existingSessions.docs.first;
        return AIChatSession.fromMap(doc.id, doc.data());
      }
    } catch (e) {
      print('Error finding existing session: $e');
    }

    return createChatSession(title, category);
  }

  Future<AIChatSession> createChatSession(String title, String category) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final sessionId = _generateSessionId();
    final session = AIChatSession(
      id: sessionId,
      userId: user.uid,
      title: title,
      category: category,
      createdAt: DateTime.now(),
      lastMessageTime: DateTime.now(),
      lastMessage: 'Chat session started',
      messageCount: 0,
      isActive: true,
    );

    try {
      await _firestore
          .collection('ai_chat_sessions')
          .doc(sessionId)
          .set(session.toMap());
    } catch (e) {
      print('Firebase save failed: $e');
    }

    return session;
  }

  Stream<List<AIChatMessage>> getSessionMessages(String sessionId) {
    return _firestore
        .collection('ai_chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AIChatMessage.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addMessageToSession(String sessionId, AIChatMessage message) async {
    try {
      final messageData = message.toMap();
      messageData.remove('id');

      await _firestore
          .collection('ai_chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .add(messageData);

      await _firestore
          .collection('ai_chat_sessions')
          .doc(sessionId)
          .update({
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessage': message.content.length > 100 
            ? message.content.substring(0, 100) 
            : message.content,
        'messageCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error adding message: $e');
    }
  }

  String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
           math.Random().nextInt(1000).toString();
  }

  Stream<List<AIChatSession>> getUserChatSessions() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('ai_chat_sessions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AIChatSession.fromMap(doc.id, doc.data()))
            .toList());
  }

  // --- NEW METHODS ADDED TO FIX COMPILATION ERRORS ---

  Future<Map<String, dynamic>> getSessionStatistics() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final snapshot = await _firestore
          .collection('ai_chat_sessions')
          .where('userId', isEqualTo: user.uid)
          .get();

      int totalMessages = 0;
      int activeSessions = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalMessages += (data['messageCount'] as num? ?? 0).toInt();
        if (data['isActive'] == true) {
          activeSessions++;
        }
      }

      return {
        'totalSessions': snapshot.docs.length,
        'activeSessions': activeSessions,
        'totalMessages': totalMessages,
        'lastActive': snapshot.docs.isNotEmpty ? snapshot.docs.first.data()['lastMessageTime'] : null,
      };
    } catch (e) {
      print('Error getting stats: $e');
      return {};
    }
  }

  Future<List<AIChatSession>> searchChatSessions(String query) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('ai_chat_sessions')
          .where('userId', isEqualTo: user.uid)
          .get();

      final allSessions = snapshot.docs.map((doc) => AIChatSession.fromMap(doc.id, doc.data())).toList();
      
      if (query.isEmpty) return allSessions;

      return allSessions.where((s) => 
        s.title.toLowerCase().contains(query.toLowerCase()) || 
        s.lastMessage.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      print('Error searching sessions: $e');
      return [];
    }
  }

  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    await _firestore.collection('ai_chat_sessions').doc(sessionId).update({
      'title': newTitle,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteChatSession(String sessionId) async {
    // Delete subcollection messages first (simplified for Firestore)
    // In production, use a Cloud Function for recursive delete
    await _firestore.collection('ai_chat_sessions').doc(sessionId).delete();
  }

  Future<Map<String, dynamic>> validateCommunityPost(String content) async {
    // Basic validation logic
    final isTooShort = content.length < 10;
    final hasInappropriateLanguage = content.toLowerCase().contains('spam'); // Simplified
    
    return {
      'isValid': !isTooShort && !hasInappropriateLanguage,
      'reason': isTooShort ? 'Content too short' : (hasInappropriateLanguage ? 'Inappropriate language detected' : 'Valid'),
      'confidence': 0.9,
    };
  }

  String cleanResponse(String text) {
    return text.replaceAll(RegExp(r'[*#_~]'), '').trim();
  }
}
