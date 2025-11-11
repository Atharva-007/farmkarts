// Selling History schema for tracking user's product listings
class SellingHistory {
  constructor(data) {
    this.id = data.id || null;
    this.productId = this.validateRequired(data.productId, 'Product ID');
    this.sellerId = this.validateRequired(data.sellerId, 'Seller ID');
    this.productName = data.productName || '';
    this.category = data.category || '';
    this.originalPrice = this.validatePrice(data.originalPrice);
    this.currentPrice = this.validatePrice(data.currentPrice);
    this.originalQuantity = this.validateQuantity(data.originalQuantity);
    this.currentQuantity = this.validateQuantity(data.currentQuantity);
    this.soldQuantity = data.soldQuantity || 0;
    this.status = this.validateStatus(data.status);
    this.imageUrl = data.imageUrl || '';
    this.listedDate = data.listedDate || new Date();
    this.lastSoldDate = data.lastSoldDate || null;
    this.totalRevenue = data.totalRevenue || 0;
    this.totalInquiries = data.totalInquiries || 0;
    this.totalViews = data.totalViews || 0;
    this.isActive = data.isActive !== undefined ? Boolean(data.isActive) : true;
    this.notes = data.notes || '';
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

  validateStatus(status) {
    const validStatuses = ['active', 'sold_out', 'expired', 'removed', 'paused'];
    if (!validStatuses.includes(status)) {
      return 'active'; // default status
    }
    return status;
  }

  // Convert to Firestore document
  toFirestore() {
    return {
      productId: this.productId,
      sellerId: this.sellerId,
      productName: this.productName,
      category: this.category,
      originalPrice: this.originalPrice,
      currentPrice: this.currentPrice,
      originalQuantity: this.originalQuantity,
      currentQuantity: this.currentQuantity,
      soldQuantity: this.soldQuantity,
      status: this.status,
      imageUrl: this.imageUrl,
      listedDate: this.listedDate,
      lastSoldDate: this.lastSoldDate,
      totalRevenue: this.totalRevenue,
      totalInquiries: this.totalInquiries,
      totalViews: this.totalViews,
      isActive: this.isActive,
      notes: this.notes,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    };
  }

  // Create from Firestore document
  static fromFirestore(doc) {
    const data = doc.data();
    data.id = doc.id;
    return new SellingHistory(data);
  }

  // Create from Product
  static fromProduct(product, sellerId) {
    return new SellingHistory({
      productId: product.id,
      sellerId: sellerId,
      productName: product.name,
      category: product.category,
      originalPrice: product.price,
      currentPrice: product.price,
      originalQuantity: product.quantity,
      currentQuantity: product.quantity,
      soldQuantity: 0,
      status: product.isAvailable ? 'active' : 'paused',
      imageUrl: product.imageUrls && product.imageUrls.length > 0 ? product.imageUrls[0] : '',
      listedDate: new Date(),
      totalRevenue: 0,
      totalInquiries: 0,
      totalViews: 0,
      isActive: product.isAvailable,
      notes: `Product listed on ${new Date().toLocaleDateString()}`
    });
  }

  // Update when product is sold
  recordSale(quantitySold, salePrice) {
    this.soldQuantity += quantitySold;
    this.currentQuantity = Math.max(0, this.currentQuantity - quantitySold);
    this.totalRevenue += (quantitySold * salePrice);
    this.lastSoldDate = new Date();
    this.updatedAt = new Date();
    
    if (this.currentQuantity === 0) {
      this.status = 'sold_out';
      this.isActive = false;
    }
    
    return this.toFirestore();
  }

  // Update metrics
  incrementInquiries() {
    this.totalInquiries += 1;
    this.updatedAt = new Date();
    return { 
      totalInquiries: this.totalInquiries,
      updatedAt: this.updatedAt 
    };
  }

  incrementViews() {
    this.totalViews += 1;
    this.updatedAt = new Date();
    return { 
      totalViews: this.totalViews,
      updatedAt: this.updatedAt 
    };
  }

  // Update price
  updatePrice(newPrice) {
    this.currentPrice = this.validatePrice(newPrice);
    this.updatedAt = new Date();
    return {
      currentPrice: this.currentPrice,
      updatedAt: this.updatedAt
    };
  }

  // Update status
  updateStatus(newStatus, notes = '') {
    this.status = this.validateStatus(newStatus);
    this.isActive = ['active'].includes(newStatus);
    if (notes) {
      this.notes = notes;
    }
    this.updatedAt = new Date();
    
    return {
      status: this.status,
      isActive: this.isActive,
      notes: this.notes,
      updatedAt: this.updatedAt
    };
  }

  // Get performance metrics
  getPerformanceMetrics() {
    const daysListed = Math.max(1, Math.ceil((new Date() - this.listedDate) / (1000 * 60 * 60 * 24)));
    const conversionRate = this.totalViews > 0 ? (this.totalInquiries / this.totalViews * 100) : 0;
    const avgRevenuePerDay = this.totalRevenue / daysListed;
    const sellThroughRate = this.originalQuantity > 0 ? (this.soldQuantity / this.originalQuantity * 100) : 0;

    return {
      daysListed,
      conversionRate: Math.round(conversionRate * 100) / 100,
      avgRevenuePerDay: Math.round(avgRevenuePerDay * 100) / 100,
      sellThroughRate: Math.round(sellThroughRate * 100) / 100,
      totalInquiries: this.totalInquiries,
      totalViews: this.totalViews,
      totalRevenue: this.totalRevenue,
      remainingQuantity: this.currentQuantity,
      status: this.status
    };
  }

  // Static methods for queries
  static getValidStatuses() {
    return ['active', 'sold_out', 'expired', 'removed', 'paused'];
  }

  static getFilterableFields() {
    return ['sellerId', 'category', 'status', 'isActive'];
  }

  static getSortableFields() {
    return ['listedDate', 'totalRevenue', 'totalInquiries', 'totalViews', 'currentPrice'];
  }
}

module.exports = SellingHistory;