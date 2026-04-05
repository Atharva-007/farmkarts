import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PriceAlert {
  final String id;
  final String userId;
  final String productName;
  final String category;
  final String state;
  final String district;
  final double targetPrice;
  final String condition; // 'above' or 'below'
  final DateTime createdAt;
  final bool isActive;

  PriceAlert({
    required this.id,
    required this.userId,
    required this.productName,
    required this.category,
    required this.state,
    required this.district,
    required this.targetPrice,
    required this.condition,
    required this.createdAt,
    this.isActive = true,
  });

  factory PriceAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PriceAlert(
      id: doc.id,
      userId: data['userId'] ?? '',
      productName: data['productName'] ?? '',
      category: data['category'] ?? '',
      state: data['state'] ?? '',
      district: data['district'] ?? '',
      targetPrice: (data['targetPrice'] ?? 0.0).toDouble(),
      condition: data['condition'] ?? 'above',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productName': productName,
      'category': category,
      'state': state,
      'district': district,
      'targetPrice': targetPrice,
      'condition': condition,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}

class PriceAlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new price alert
  Future<void> createAlert({
    required String productName,
    required String category,
    required String state,
    required String district,
    required double targetPrice,
    required String condition,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User must be logged in');

    await _firestore.collection('price_alerts').add({
      'userId': user.uid,
      'productName': productName,
      'category': category,
      'state': state,
      'district': district,
      'targetPrice': targetPrice,
      'condition': condition,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  /// Get all active alerts for the current user
  Stream<List<PriceAlert>> getMyAlerts() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('price_alerts')
        .where('userId', isEqualTo: user.uid)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PriceAlert.fromFirestore(doc)).toList());
  }

  /// Delete an alert
  Future<void> deleteAlert(String alertId) async {
    await _firestore.collection('price_alerts').doc(alertId).delete();
  }

  /// Deactivate an alert (mark as triggered or disabled)
  Future<void> deactivateAlert(String alertId) async {
    await _firestore
        .collection('price_alerts')
        .doc(alertId)
        .update({'isActive': false});
  }

  /// Check if an alert already exists for a specific product and mandi
  Future<bool> hasAlertFor(String productName, String district) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final query = await _firestore
        .collection('price_alerts')
        .where('userId', isEqualTo: user.uid)
        .where('productName', isEqualTo: productName)
        .where('district', isEqualTo: district)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Remove alert for a specific product and mandi
  Future<void> removeAlertFor(String productName, String district) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final query = await _firestore
        .collection('price_alerts')
        .where('userId', isEqualTo: user.uid)
        .where('productName', isEqualTo: productName)
        .where('district', isEqualTo: district)
        .where('isActive', isEqualTo: true)
        .get();

    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }
}
