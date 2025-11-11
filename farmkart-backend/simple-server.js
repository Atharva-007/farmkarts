const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const admin = require('firebase-admin');

const app = express();
const PORT = 3002;

// Middleware
app.use(cors({
  origin: ['http://localhost:3000', 'http://127.0.0.1:3000', 'http://localhost:8080'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept']
}));

app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));

// Initialize Firebase (without service account for development)
try {
  if (!admin.apps.length) {
    admin.initializeApp({
      projectId: 'farmkart-9f4f3',
    });
  }
  console.log('✅ Firebase Admin initialized');
} catch (error) {
  console.warn('⚠️ Firebase initialization failed, continuing with mock data:', error.message);
}

const firestore = admin.firestore();

// Simple authentication middleware for development
const simpleAuth = (req, res, next) => {
  // For development, we'll accept any bearer token
  const authHeader = req.headers['authorization'];
  if (!authHeader) {
    return res.status(401).json({ success: false, error: 'Authorization header required' });
  }

  // Mock user for testing
  req.user = { uid: 'test-user-123' };
  req.userProfile = { 
    role: 'addat', 
    fullName: 'Test User',
    dukanName: 'Test Farm' 
  };
  next();
};

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    success: true, 
    message: 'FarmKart Backend is running!',
    port: PORT,
    timestamp: new Date().toISOString()
  });
});

// Create product endpoint
app.post('/api/products', simpleAuth, async (req, res) => {
  try {
    console.log('📦 Creating new product:', req.body.name);
    
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

    // Validation
    if (!name || !description || !price || !quantity) {
      return res.status(400).json({
        success: false,
        error: 'Name, description, price, and quantity are required'
      });
    }

    const sellerId = req.user.uid;
    const sellerName = req.userProfile.fullName || req.userProfile.dukanName || 'Unknown Seller';

    const productData = {
      name,
      description: description || '',
      category: category || 'Other',
      price: parseFloat(price),
      unit: unit || 'kg',
      quantity: parseInt(quantity),
      sellerId,
      sellerName,
      location: location || '',
      imageUrls: [], // Will be handled later
      tags: Array.isArray(tags) ? tags : (tags ? JSON.parse(tags) : []),
      isOrganic: isOrganic === 'true' || isOrganic === true,
      isAvailable: true,
      harvestDate: harvestDate || null,
      expiryDate: expiryDate || null,
      certificationDetails: certificationDetails || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      viewCount: 0,
      likeCount: 0,
      inquiryCount: 0
    };

    // Add to Firestore
    const docRef = await firestore.collection('products').add(productData);
    
    // Create selling history entry
    const sellingHistoryData = {
      productId: docRef.id,
      productName: name,
      sellerId,
      sellerName,
      category: category || 'Other',
      initialPrice: parseFloat(price),
      currentPrice: parseFloat(price),
      totalQuantity: parseInt(quantity),
      soldQuantity: 0,
      availableQuantity: parseInt(quantity),
      totalRevenue: 0,
      totalViews: 0,
      totalInquiries: 0,
      status: 'active',
      isActive: true,
      listedDate: admin.firestore.FieldValue.serverTimestamp(),
      lastSoldDate: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await firestore.collection('selling_history').add(sellingHistoryData);

    console.log('✅ Product created successfully:', docRef.id);

    res.status(201).json({
      success: true,
      data: {
        id: docRef.id,
        ...productData,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      },
      message: 'Product created successfully'
    });

  } catch (error) {
    console.error('❌ Error creating product:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to create product'
    });
  }
});

// Get products endpoint
app.get('/api/products', async (req, res) => {
  try {
    console.log('📋 Fetching products with filters:', req.query);
    
    const {
      category,
      sellerId,
      excludeSeller,
      limit = 20,
      page = 1,
      isAvailable = 'true',
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

    // Apply pagination
    const offset = (parseInt(page) - 1) * parseInt(limit);
    query = query.limit(parseInt(limit));

    if (offset > 0) {
      query = query.offset(offset);
    }

    const snapshot = await query.get();
    let products = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString() || new Date().toISOString()
    }));

    // Apply search filter in memory
    if (search) {
      const searchLower = search.toLowerCase();
      products = products.filter(product =>
        product.name.toLowerCase().includes(searchLower) ||
        product.description.toLowerCase().includes(searchLower) ||
        (product.tags && product.tags.some(tag => tag.toLowerCase().includes(searchLower)))
      );
    }

    console.log(`✅ Fetched ${products.length} products`);

    res.json({
      success: true,
      data: products,
      pagination: {
        currentPage: parseInt(page),
        limit: parseInt(limit),
        totalProducts: products.length,
        hasMore: products.length === parseInt(limit)
      }
    });

  } catch (error) {
    console.error('❌ Error fetching products:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to fetch products'
    });
  }
});

// Get product by ID endpoint
app.get('/api/products/:id', async (req, res) => {
  try {
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
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString() || new Date().toISOString()
    };

    // Increment view count
    await firestore.collection('products').doc(id).update({
      viewCount: admin.firestore.FieldValue.increment(1)
    });

    res.json({
      success: true,
      data: product
    });

  } catch (error) {
    console.error('❌ Error fetching product by ID:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to fetch product'
    });
  }
});

// Get selling history by user
app.get('/api/users/:userId/selling-history', simpleAuth, async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Verify user can access this data (allow test user to access any data for development)
    if (req.user.uid !== userId && req.user.uid !== 'test-user-123') {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }

    const query = firestore.collection('selling_history').where('sellerId', '==', userId);
    const snapshot = await query.get();
    
    const sellingHistory = snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        listedDate: data.listedDate?.toDate?.()?.toISOString() || new Date().toISOString(),
        lastSoldDate: data.lastSoldDate?.toDate?.()?.toISOString() || null,
        createdAt: data.createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
        updatedAt: data.updatedAt?.toDate?.()?.toISOString() || new Date().toISOString()
      };
    });

    // Calculate summary
    const totalRevenue = sellingHistory.reduce((sum, item) => sum + (item.totalRevenue || 0), 0);
    const totalListings = sellingHistory.length;
    const activeListings = sellingHistory.filter(item => item.status === 'active').length;
    const soldOutListings = sellingHistory.filter(item => item.status === 'sold_out').length;

    console.log(`✅ Fetched ${sellingHistory.length} selling history items for user: ${userId}`);

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
        currentPage: 1,
        limit: 50,
        hasMore: false
      }
    });

  } catch (error) {
    console.error('❌ Error fetching selling history:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to fetch selling history'
    });
  }
});

// Update product endpoint
app.put('/api/products/:id', simpleAuth, async (req, res) => {
  try {
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
    
    // Verify ownership (allow test user for development)
    if (existingProduct.sellerId !== req.user.uid && req.user.uid !== 'test-user-123') {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }

    updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    
    await firestore.collection('products').doc(id).update(updates);
    
    console.log('✅ Product updated:', id);

    res.json({
      success: true,
      data: {
        id,
        ...existingProduct,
        ...updates,
        updatedAt: new Date().toISOString()
      },
      message: 'Product updated successfully'
    });

  } catch (error) {
    console.error('❌ Error updating product:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to update product'
    });
  }
});

// Delete product endpoint
app.delete('/api/products/:id', simpleAuth, async (req, res) => {
  try {
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
    
    // Verify ownership (allow test user for development)
    if (existingProduct.sellerId !== req.user.uid && req.user.uid !== 'test-user-123') {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }

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
    
    console.log('✅ Product deleted:', id);

    res.json({
      success: true,
      message: 'Product deleted successfully'
    });

  } catch (error) {
    console.error('❌ Error deleting product:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to delete product'
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('❌ Unhandled error:', error);
  res.status(500).json({
    success: false,
    error: 'Internal server error'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Route not found',
    availableRoutes: {
      health: 'GET /api/health',
      products: 'GET /api/products',
      createProduct: 'POST /api/products',
      getProduct: 'GET /api/products/:id',
      updateProduct: 'PUT /api/products/:id',
      deleteProduct: 'DELETE /api/products/:id',
      sellingHistory: 'GET /api/users/:userId/selling-history'
    }
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`\n🚀 FarmKart Backend Server started successfully!`);
  console.log(`🌐 Server running on: http://localhost:${PORT}`);
  console.log(`🏥 Health check: http://localhost:${PORT}/api/health`);
  console.log(`📱 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`📋 Available endpoints:`);
  console.log(`  🛒 Products: /api/products`);
  console.log(`  ➕ Create Product: POST /api/products`);
  console.log(`  👤 Selling History: /api/users/:userId/selling-history`);
  console.log(`  ⚕️ Health: /api/health\n`);
});

module.exports = app;