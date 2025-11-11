// Product schema and validation for FarmKart backend
class Product {
  constructor(data) {
    this.id = data.id || null;
    this.name = this.validateRequired(data.name, 'Product name');
    this.description = data.description || '';
    this.category = data.category || 'Other';
    this.price = this.validatePrice(data.price);
    this.unit = data.unit || 'kg';
    this.quantity = this.validateQuantity(data.quantity);
    this.sellerId = this.validateRequired(data.sellerId, 'Seller ID');
    this.sellerName = data.sellerName || '';
    this.location = data.location || '';
    this.imageUrls = Array.isArray(data.imageUrls) ? data.imageUrls : [];
    this.tags = Array.isArray(data.tags) ? data.tags : [];
    this.isOrganic = Boolean(data.isOrganic);
    this.isAvailable = data.isAvailable !== undefined ? Boolean(data.isAvailable) : true;
    this.harvestDate = data.harvestDate ? new Date(data.harvestDate) : null;
    this.expiryDate = data.expiryDate ? new Date(data.expiryDate) : null;
    this.certificationDetails = data.certificationDetails || null;
    this.viewCount = data.viewCount || 0;
    this.likeCount = data.likeCount || 0;
    this.inquiryCount = data.inquiryCount || 0;
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  validateRequired(value, fieldName) {
    if (!value || (typeof value === 'string' && value.trim() === '')) {
      throw new Error(`${fieldName} is required`);
    }
    return value;
  }

  validatePrice(price) {
    const numPrice = parseFloat(price);
    if (isNaN(numPrice) || numPrice < 0) {
      throw new Error('Price must be a valid positive number');
    }
    return numPrice;
  }

  validateQuantity(quantity) {
    const numQuantity = parseInt(quantity);
    if (isNaN(numQuantity) || numQuantity < 0) {
      throw new Error('Quantity must be a valid positive number');
    }
    return numQuantity;
  }

  // Convert to Firestore document
  toFirestore() {
    return {
      name: this.name,
      description: this.description,
      category: this.category,
      price: this.price,
      unit: this.unit,
      quantity: this.quantity,
      sellerId: this.sellerId,
      sellerName: this.sellerName,
      location: this.location,
      imageUrls: this.imageUrls,
      tags: this.tags,
      isOrganic: this.isOrganic,
      isAvailable: this.isAvailable,
      harvestDate: this.harvestDate,
      expiryDate: this.expiryDate,
      certificationDetails: this.certificationDetails,
      viewCount: this.viewCount,
      likeCount: this.likeCount,
      inquiryCount: this.inquiryCount,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    };
  }

  // Create from Firestore document
  static fromFirestore(doc) {
    const data = doc.data();
    data.id = doc.id;
    return new Product(data);
  }

  // Update fields
  updateFields(updates) {
    const allowedFields = [
      'name', 'description', 'category', 'price', 'unit', 'quantity',
      'location', 'imageUrls', 'tags', 'isOrganic', 'isAvailable',
      'harvestDate', 'expiryDate', 'certificationDetails'
    ];

    const filteredUpdates = {};
    Object.keys(updates).forEach(key => {
      if (allowedFields.includes(key)) {
        filteredUpdates[key] = updates[key];
      }
    });

    filteredUpdates.updatedAt = new Date();
    return filteredUpdates;
  }

  // Increment counters
  incrementViewCount() {
    return { viewCount: this.viewCount + 1 };
  }

  incrementLikeCount() {
    return { likeCount: this.likeCount + 1 };
  }

  incrementInquiryCount() {
    return { inquiryCount: this.inquiryCount + 1 };
  }

  // Search helpers
  static getSearchableFields() {
    return ['name', 'description', 'category', 'tags', 'location'];
  }

  // Default categories
  static getDefaultCategories() {
    return [
      'Vegetables',
      'Fruits',
      'Grains',
      'Seeds',
      'Equipment',
      'Dairy',
      'Spices',
      'Fertilizers',
      'Organic',
      'Other'
    ];
  }

  // Validation rules
  static getValidationRules() {
    return {
      name: { required: true, maxLength: 100 },
      description: { maxLength: 1000 },
      price: { required: true, min: 0 },
      quantity: { required: true, min: 0 },
      sellerId: { required: true },
      category: { enum: this.getDefaultCategories() },
      unit: { enum: ['kg', 'g', 'ton', 'piece', 'dozen', 'bundle', 'bag', 'liter', 'ml'] },
      imageUrls: { maxItems: 5 },
      tags: { maxItems: 10 }
    };
  }
}

module.exports = Product;