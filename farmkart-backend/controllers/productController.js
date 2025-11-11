const admin = require('firebase-admin');
const Product = require('../models/Product');
const SellingHistory = require('../models/SellingHistory');
const winston = require('winston');

// Get logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console()
  ]
});

class ProductController {
  // Create new product (restricted to addats/vendors)
  static async createProduct(req, res) {
    try {
      // Get Firestore instance inside the function
      const firestore = admin.firestore();
      const {
        name,
        description,
        category,
        price,
        unit,
        quantity,
        location,
        tags,
        isOrganic,
        harvestDate,
        expiryDate,
        certificationDetails
      } = req.body;

      // Get seller info from authenticated user
      const sellerId = req.user.uid;
      const sellerName = req.userProfile.fullName || req.userProfile.dukanName || 'Unknown Seller';

      // Handle image uploads (if files are provided)
      let imageUrls = [];
      if (req.files && req.files.length > 0) {
        // In production, upload to Firebase Storage
        imageUrls = req.files.map((file, index) => 
          `https://storage.googleapis.com/farmkart-images/${sellerId}/${Date.now()}_${index}.jpg`
        );
      }

      // Create product instance for validation
      const productData = {
        name,
        description,
        category,
        price,
        unit,
        quantity,
        sellerId,
        sellerName,
        location,
        imageUrls,
        tags: tags ? (Array.isArray(tags) ? tags : JSON.parse(tags)) : [],
        isOrganic: isOrganic === 'true' || isOrganic === true,
        harvestDate,
        expiryDate,
        certificationDetails,
        isAvailable: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      const product = new Product(productData);
      
      // Add product to Firestore
      const productRef = await firestore.collection('products').add(product.toFirestore());
      
      // Create selling history entry
      const sellingHistoryData = SellingHistory.fromProduct({ 
        ...product.toFirestore(), 
        id: productRef.id 
      }, sellerId);
      
      await firestore.collection('selling_history').add(sellingHistoryData.toFirestore());

      // Log activity
      await firestore.collection('activity_logs').add({
        userId: sellerId,
        action: 'PRODUCT_CREATED',
        productId: productRef.id,
        productName: name,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });

      logger.info(`Product created: ${productRef.id} by seller: ${sellerId}`);

      res.status(201).json({
        success: true,
        data: {
          id: productRef.id,
          ...product.toFirestore()
        },
        message: 'Product created successfully'
      });

    } catch (error) {
      logger.error('Error creating product:', error);
      res.status(500).json({
        success: false,
        error: error.message || 'Failed to create product'
      });
    }
  }

  // Get products with filtering and pagination
  static async getProducts(req, res) {
    try {
      const firestore = admin.firestore();
      const {
        category,
        sellerId,
        excludeSeller,
        limit = 20,
        page = 1,
        isAvailable = true,
        minPrice,
        maxPrice,
        isOrganic,
        location,
        sortBy = 'createdAt',
        sortOrder = 'desc',
        search
      } = req.query;

      let query = firestore.collection('products');

      // Apply filters
      if (category && category !== 'All') {
        query = query.where('category', '==', category);
      }

      if (sellerId) {
        query = query.where('sellerId', '==', sellerId);
      }

      if (excludeSeller) {
        query = query.where('sellerId', '!=', excludeSeller);
      }

      if (isAvailable === 'true') {
        query = query.where('isAvailable', '==', true);
      }

      if (isOrganic === 'true') {
        query = query.where('isOrganic', '==', true);
      }

      // Apply sorting and pagination
      const offset = (parseInt(page) - 1) * parseInt(limit);
      
      try {
        query = query.orderBy(sortBy, sortOrder);
      } catch (e) {
        // Fallback if orderBy field doesn't exist
        query = query.orderBy('createdAt', 'desc');
      }
      
      query = query.limit(parseInt(limit)).offset(offset);

      const snapshot = await query.get();
      let products = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        // Convert Firestore timestamps to ISO strings
        createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || doc.data().createdAt,
        updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString() || doc.data().updatedAt
      }));

      // Apply client-side filters for complex searches
      if (search) {
        const searchLower = search.toLowerCase();
        products = products.filter(product =>
          product.name.toLowerCase().includes(searchLower) ||
          product.description.toLowerCase().includes(searchLower) ||
          (product.tags && product.tags.some(tag => tag.toLowerCase().includes(searchLower)))
        );
      }

      if (location) {
        products = products.filter(product =>
          product.location.toLowerCase().includes(location.toLowerCase())
        );
      }

      if (minPrice) {
        products = products.filter(product => product.price >= parseFloat(minPrice));
      }

      if (maxPrice) {
        products = products.filter(product => product.price <= parseFloat(maxPrice));
      }

      // Get total count for pagination
      const totalQuery = firestore.collection('products');
      let totalSnapshot;
      try {
        totalSnapshot = await totalQuery.count().get();
      } catch (e) {
        // Fallback if count() is not available
        const allDocs = await totalQuery.get();
        totalSnapshot = { data: () => ({ count: allDocs.size }) };
      }
      const totalCount = totalSnapshot.data().count;

      logger.info(`Fetched ${products.length} products`);

      res.json({
        success: true,
        data: products,
        pagination: {
          currentPage: parseInt(page),
          limit: parseInt(limit),
          totalProducts: totalCount,
          totalPages: Math.ceil(totalCount / parseInt(limit)),
          hasMore: offset + products.length < totalCount
        }
      });

    } catch (error) {
      logger.error('Error fetching products:', error);
      res.status(500).json({
        success: false,
        error: error.message || 'Failed to fetch products'
      });
    }
  }

  // Get product by ID
  static async getProductById(req, res) {
    try {
      const firestore = admin.firestore();
      const { id } = req.params;
      
      const doc = await firestore.collection('products').doc(id).get();
      
      if (!doc.exists) {
        return res.status(404).json({
          success: false,
          error: 'Product not found'
        });
      }

      const product = {
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || doc.data().createdAt,
        updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString() || doc.data().updatedAt
      };

      // Increment view count
      await firestore.collection('products').doc(id).update({
        viewCount: admin.firestore.FieldValue.increment(1)
      });

      // Also update selling history view count
      const sellingHistoryQuery = await firestore
        .collection('selling_history')
        .where('productId', '==', id)
        .limit(1)
        .get();
      
      if (!sellingHistoryQuery.empty) {
        await sellingHistoryQuery.docs[0].ref.update({
          totalViews: admin.firestore.FieldValue.increment(1),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      }

      res.json({
        success: true,
        data: product
      });

    } catch (error) {
      logger.error('Error fetching product by ID:', error);
      res.status(500).json({
        success: false,
        error: error.message || 'Failed to fetch product'
      });
    }
  }

  // Get selling history by user (seller's dashboard)
  static async getSellingHistoryByUser(req, res) {
    try {
      const firestore = admin.firestore();
      const { userId } = req.params;
      const {
        status,
        category,
        limit = 20,
        page = 1,
        sortBy = 'listedDate',
        sortOrder = 'desc'
      } = req.query;

      // Verify user can access this data
      if (req.user.uid !== userId) {
        return res.status(403).json({
          success: false,
          error: 'Access denied. You can only view your own selling history.'
        });
      }

      let query = firestore.collection('selling_history').where('sellerId', '==', userId);

      // Apply filters
      if (status) {
        query = query.where('status', '==', status);
      }

      if (category) {
        query = query.where('category', '==', category);
      }

      // Apply sorting and pagination
      const offset = (parseInt(page) - 1) * parseInt(limit);
      
      try {
        query = query.orderBy(sortBy, sortOrder);
      } catch (e) {
        // Fallback if orderBy field doesn't exist
        query = query.orderBy('listedDate', 'desc');
      }
      
      query = query.limit(parseInt(limit)).offset(offset);

      const snapshot = await query.get();
      const sellingHistory = snapshot.docs.map(doc => {
        const data = doc.data();
        const sellingHistoryItem = SellingHistory.fromFirestore(doc);
        
        return {
          id: doc.id,
          ...sellingHistoryItem.toFirestore(),
          performanceMetrics: sellingHistoryItem.getPerformanceMetrics(),
          // Convert Firestore timestamps
          listedDate: data.listedDate?.toDate?.()?.toISOString() || data.listedDate,
          lastSoldDate: data.lastSoldDate?.toDate?.()?.toISOString() || data.lastSoldDate,
          createdAt: data.createdAt?.toDate?.()?.toISOString() || data.createdAt,
          updatedAt: data.updatedAt?.toDate?.()?.toISOString() || data.updatedAt
        };
      });

      // Calculate summary statistics
      const totalRevenue = sellingHistory.reduce((sum, item) => sum + (item.totalRevenue || 0), 0);
      const totalListings = sellingHistory.length;
      const activeListings = sellingHistory.filter(item => item.status === 'active').length;
      const soldOutListings = sellingHistory.filter(item => item.status === 'sold_out').length;

      logger.info(`Fetched selling history: ${sellingHistory.length} items for user: ${userId}`);

      res.json({
        success: true,
        data: sellingHistory,
        summary: {
          totalRevenue: Math.round(totalRevenue * 100) / 100,
          totalListings,
          activeListings,
          soldOutListings,
          avgRevenuePerListing: totalListings > 0 ? Math.round((totalRevenue / totalListings) * 100) / 100 : 0
        },
        pagination: {
          currentPage: parseInt(page),
          limit: parseInt(limit),
          hasMore: sellingHistory.length === parseInt(limit)
        }
      });

    } catch (error) {
      logger.error('Error fetching selling history:', error);
      res.status(500).json({
        success: false,
        error: error.message || 'Failed to fetch selling history'
      });
    }
  }

  // Update product
  static async updateProduct(req, res) {
    try {
      const firestore = admin.firestore();
      const { id } = req.params;
      const updates = req.body;

      // Get existing product
      const doc = await firestore.collection('products').doc(id).get();
      
      if (!doc.exists) {
        return res.status(404).json({
          success: false,
          error: 'Product not found'
        });
      }

      const existingProduct = doc.data();

      // Verify ownership
      if (existingProduct.sellerId !== req.user.uid) {
        return res.status(403).json({
          success: false,
          error: 'Access denied. You can only update your own products.'
        });
      }

      // Validate updates using Product model
      const product = new Product(existingProduct);
      const validUpdates = product.updateFields(updates);
      validUpdates.updatedAt = admin.firestore.FieldValue.serverTimestamp();

      // Update product
      await firestore.collection('products').doc(id).update(validUpdates);

      // Update selling history if needed
      const sellingHistoryQuery = await firestore
        .collection('selling_history')
        .where('productId', '==', id)
        .limit(1)
        .get();

      if (!sellingHistoryQuery.empty) {
        const historyUpdates = {
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        if (validUpdates.name) historyUpdates.productName = validUpdates.name;
        if (validUpdates.price) historyUpdates.currentPrice = validUpdates.price;
        if (validUpdates.category) historyUpdates.category = validUpdates.category;
        if (validUpdates.isAvailable !== undefined) {
          historyUpdates.isActive = validUpdates.isAvailable;
          if (!validUpdates.isAvailable) {
            historyUpdates.status = 'paused';
          } else if (existingProduct.quantity > 0) {
            historyUpdates.status = 'active';
          }
        }

        await sellingHistoryQuery.docs[0].ref.update(historyUpdates);
      }

      logger.info(`Product updated: ${id}`);

      res.json({
        success: true,
        data: {
          id,
          ...existingProduct,
          ...validUpdates
        },
        message: 'Product updated successfully'
      });

    } catch (error) {
      logger.error('Error updating product:', error);
      res.status(500).json({
        success: false,
        error: error.message || 'Failed to update product'
      });
    }
  }

  // Delete product
  static async deleteProduct(req, res) {
    try {
      const firestore = admin.firestore();
      const { id } = req.params;

      // Get existing product
      const doc = await firestore.collection('products').doc(id).get();
      
      if (!doc.exists) {
        return res.status(404).json({
          success: false,
          error: 'Product not found'
        });
      }

      const existingProduct = doc.data();

      // Verify ownership
      if (existingProduct.sellerId !== req.user.uid) {
        return res.status(403).json({
          success: false,
          error: 'Access denied. You can only delete your own products.'
        });
      }

      // Delete product
      await firestore.collection('products').doc(id).delete();

      // Update selling history status
      const sellingHistoryQuery = await firestore
        .collection('selling_history')
        .where('productId', '==', id)
        .limit(1)
        .get();

      if (!sellingHistoryQuery.empty) {
        await sellingHistoryQuery.docs[0].ref.update({
          status: 'removed',
          isActive: false,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      }

      logger.info(`Product deleted: ${id}`);

      res.json({
        success: true,
        message: 'Product deleted successfully'
      });

    } catch (error) {
      logger.error('Error deleting product:', error);
      res.status(500).json({
        success: false,
        error: error.message || 'Failed to delete product'
      });
    }
  }
}

module.exports = ProductController;