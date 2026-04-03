import 'package:cloud_firestore/cloud_firestore.dart';

enum InventoryType {
  product,    // Marketplace products
  good,       // Consumable goods like fertilizers, seeds, etc.
  instrument, // Tools and machinery
  other       // Anything else
}

enum ItemCondition {
  new_item,
  excellent,
  good,
  fair,
  poor,
  maintenance_required
}

class InventoryItem {
  final String id;
  final String name;
  final String description;
  final String category;
  final InventoryType type;
  final double quantity;
  final String unit;
  final double price; // Purchase price or valuation
  final List<String> imageUrls;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Type specific fields
  final ItemCondition? condition; // For instruments
  final String? manufacturer;
  final String? modelNumber;
  final DateTime? purchaseDate;
  final DateTime? expiryDate; // For goods
  final bool isForSale; // If linked to a marketplace product
  final String? marketplaceProductId;

  InventoryItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.type,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.imageUrls,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.condition,
    this.manufacturer,
    this.modelNumber,
    this.purchaseDate,
    this.expiryDate,
    this.isForSale = false,
    this.marketplaceProductId,
  });

  factory InventoryItem.fromMap(String id, Map<String, dynamic> map) {
    return InventoryItem(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Other',
      type: InventoryType.values.firstWhere(
        (e) => e.toString() == 'InventoryType.${map['type']}',
        orElse: () => InventoryType.other,
      ),
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'units',
      price: (map['price'] ?? 0).toDouble(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      ownerId: map['ownerId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      condition: map['condition'] != null 
          ? ItemCondition.values.firstWhere(
              (e) => e.toString() == 'ItemCondition.${map['condition']}',
              orElse: () => ItemCondition.good,
            ) 
          : null,
      manufacturer: map['manufacturer'],
      modelNumber: map['modelNumber'],
      purchaseDate: (map['purchaseDate'] as Timestamp?)?.toDate(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
      isForSale: map['isForSale'] ?? false,
      marketplaceProductId: map['marketplaceProductId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'type': type.toString().split('.').last,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'imageUrls': imageUrls,
      'ownerId': ownerId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'condition': condition?.toString().split('.').last,
      'manufacturer': manufacturer,
      'modelNumber': modelNumber,
      'purchaseDate': purchaseDate != null ? Timestamp.fromDate(purchaseDate!) : null,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'isForSale': isForSale,
      'marketplaceProductId': marketplaceProductId,
    };
  }
}
