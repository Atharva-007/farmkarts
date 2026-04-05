import 'package:cloud_firestore/cloud_firestore.dart';

enum InventoryType { seed, fertilizer, pesticide, tool, good, other }

class InventoryItem {
  final String id;
  final String userId;
  final String name;
  final String description;
  final double quantity;
  final String unit;
  final String category;
  final InventoryType type;
  final double price; // Price per unit
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  // NEW ENHANCED FIELDS
  final DateTime? expiryDate;
  final String? supplier;
  final double? totalValue; // Calculated total cost/value
  final String? batchNumber;
  final String stockStatus; // 'Optimal', 'Low', 'Critical'

  InventoryItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.type,
    required this.price,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
    this.expiryDate,
    this.supplier,
    this.totalValue,
    this.batchNumber,
    this.stockStatus = 'Optimal',
  });

  factory InventoryItem.fromMap(String id, Map<String, dynamic> map) {
    return InventoryItem(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
      category: map['category'] ?? '',
      type: InventoryType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['type'] ?? 'other'),
        orElse: () => InventoryType.other,
      ),
      price: (map['price'] ?? 0).toDouble(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
      supplier: map['supplier'],
      totalValue: (map['totalValue'] ?? 0).toDouble(),
      batchNumber: map['batchNumber'],
      stockStatus: map['stockStatus'] ?? 'Optimal',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'type': type.toString().split('.').last,
      'price': price,
      'imageUrls': imageUrls,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'supplier': supplier,
      'totalValue': quantity * price, // Auto-calculated
      'batchNumber': batchNumber,
      'stockStatus':
          quantity < 5 ? 'Critical' : (quantity < 15 ? 'Low' : 'Optimal'),
    };
  }

  InventoryItem copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    double? quantity,
    String? unit,
    String? category,
    InventoryType? type,
    double? price,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiryDate,
    String? supplier,
    double? totalValue,
    String? batchNumber,
    String? stockStatus,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      type: type ?? this.type,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiryDate: expiryDate ?? this.expiryDate,
      supplier: supplier ?? this.supplier,
      totalValue: totalValue ?? this.totalValue,
      batchNumber: batchNumber ?? this.batchNumber,
      stockStatus: stockStatus ?? this.stockStatus,
    );
  }
}
