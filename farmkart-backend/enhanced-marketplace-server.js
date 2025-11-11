// Enhanced FarmKart Marketplace Backend
// Complete marketplace system with role-based access, selling history, buyer tracking
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3002;

// Enhanced CORS configuration
app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin', 'X-Requested-With'],
  optionsSuccessStatus: 200
}));

app.options('*', cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Configure multer for file uploads
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type'), false);
    }
  }
});

// In-memory database (replace with real database in production)
const users = new Map(); // userId -> user data
const products = new Map(); // productId -> product data
const sellingHistory = new Map(); // sellerId -> array of selling records
const buyerInterests = new Map(); // productId -> array of buyer interests
const priceOffers = new Map(); // productId -> array of price offers
const transactions = new Map(); // transactionId -> transaction data
let productIdCounter = 1;
let offerIdCounter = 1;
let transactionIdCounter = 1;

// Authentication middleware
const authenticate = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, error: 'Authorization token required' });
  }
  
  const token = authHeader.substring(7);
  // Mock authentication - in production, verify JWT token
  if (token.startsWith('test-token')) {
    req.user = {
      uid: token.includes('-') ? token.split('-')[2] || 'test-user-123' : 'test-user-123',
      role: 'farmer', // Default role
      fullName: 'Test User',
      email: 'test@example.com'
    };
  } else {
    req.user = {
      uid: 'user-' + Math.random().toString(36).substr(2, 9),
      role: 'farmer',
      fullName: 'Authenticated User',
      email: 'user@example.com'
    };
  }
  
  next();
};

// Role-based access middleware
const requireRole = (roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ 
        success: false, 
        error: `Access denied. Required roles: ${roles.join(', ')}` 
      });
    }
    next();
  };
};

// Utility functions
const generateId = (prefix) => `${prefix}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

const createProductRecord = (productData, sellerId) => {
  const productId = generateId('product');
  const timestamp = new Date().toISOString();
  
  return {
    id: productId,
    ...productData,
    sellerId,
    sellerName: users.get(sellerId)?.fullName || 'Unknown Seller',
    status: 'active',
    createdAt: timestamp,
    updatedAt: timestamp,
    viewCount: 0,
    likeCount: 0,
    inquiryCount: 0,
    isAvailable: true
  };
};

// Routes

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'FarmKart Enhanced Marketplace Backend',
    version: '2.0.0'
  });
});

// User Management
app.post('/api/users', authenticate, (req, res) => {
  try {
    const { fullName, email, role, mobileNo, acresLand, dukanName } = req.body;
    
    const userData = {
      uid: req.user.uid,
      fullName: fullName || req.user.fullName,
      email: email || req.user.email,
      role: role || 'farmer',
      mobileNo: mobileNo || '',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    if (role === 'farmer') {
      userData.acresLand = parseFloat(acresLand) || 0;
    } else if (role === 'addat') {
      userData.dukanName = dukanName || '';
      userData.isLicenseVerified = false;
    }
    
    users.set(req.user.uid, userData);
    
    res.status(201).json({
      success: true,
      data: userData,
      message: 'User profile created successfully'
    });
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create user profile'
    });
  }
});

app.get('/api/users/:userId', authenticate, (req, res) => {
  try {
    const userId = req.params.userId;
    const user = users.get(userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }
    
    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch user'
    });
  }
});

// Product Management
app.post('/api/products', authenticate, requireRole(['farmer']), upload.array('images', 5), (req, res) => {
  try {
    console.log('Creating product for user:', req.user.uid);
    console.log('Product data:', req.body);
    
    const {
      name, description, category, price, unit, quantity,
      location, tags, isOrganic, harvestDate, expiryDate, certificationDetails
    } = req.body;
    
    // Validate required fields
    if (!name || !category || !price || !unit || quantity === undefined) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: name, category, price, unit, quantity'
      });
    }
    
    // Mock image URLs (in production, upload to cloud storage)
    const imageUrls = req.files ? req.files.map((_, index) => 
      `https://via.placeholder.com/400x300?text=Product+Image+${index + 1}`
    ) : [];
    
    const productData = {
      name: String(name),
      description: String(description || ''),
      category: String(category),
      price: parseFloat(price),
      unit: String(unit),
      quantity: parseInt(quantity),
      location: String(location || ''),
      imageUrls,
      tags: Array.isArray(tags) ? tags : (tags ? [tags] : []),
      isOrganic: isOrganic === 'true' || isOrganic === true,
      harvestDate: harvestDate || null,
      expiryDate: expiryDate || null,
      certificationDetails: certificationDetails || null
    };
    
    const product = createProductRecord(productData, req.user.uid);
    products.set(product.id, product);
    
    // Initialize buyer interests and offers for this product
    buyerInterests.set(product.id, []);
    priceOffers.set(product.id, []);
    
    // Add to seller's selling history
    const sellerHistory = sellingHistory.get(req.user.uid) || [];
    const historyItem = {
      id: generateId('history'),
      productId: product.id,
      productName: product.name,
      category: product.category,
      originalPrice: product.price,
      currentPrice: product.price,
      originalQuantity: product.quantity,
      currentQuantity: product.quantity,
      soldQuantity: 0,
      status: 'active',
      imageUrl: imageUrls[0] || '',
      listedDate: product.createdAt,
      totalRevenue: 0,
      totalInquiries: 0,
      totalViews: 0,
      isActive: true
    };
    
    sellerHistory.push(historyItem);
    sellingHistory.set(req.user.uid, sellerHistory);
    
    console.log('Product created successfully:', product.id);
    
    res.status(201).json({
      success: true,
      data: product,
      message: 'Product created successfully'
    });
    
  } catch (error) {
    console.error('Error creating product:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to create product'
    });
  }
});

app.get('/api/products', authenticate, (req, res) => {
  try {
    const { 
      category, sellerId, excludeSeller, limit = 20, page = 1,
      isAvailable, minPrice, maxPrice, isOrganic, location, 
      sortBy = 'createdAt', sortOrder = 'desc', search 
    } = req.query;
    
    let productList = Array.from(products.values());
    
    // Apply filters
    if (category) {
      productList = productList.filter(p => p.category === category);
    }
    
    if (sellerId) {
      productList = productList.filter(p => p.sellerId === sellerId);
    }
    
    if (excludeSeller) {
      productList = productList.filter(p => p.sellerId !== excludeSeller);
    }
    
    if (isAvailable !== undefined) {
      productList = productList.filter(p => p.isAvailable === (isAvailable === 'true'));
    }
    
    if (minPrice) {
      productList = productList.filter(p => p.price >= parseFloat(minPrice));
    }
    
    if (maxPrice) {
      productList = productList.filter(p => p.price <= parseFloat(maxPrice));
    }
    
    if (isOrganic !== undefined) {
      productList = productList.filter(p => p.isOrganic === (isOrganic === 'true'));
    }
    
    if (location) {
      productList = productList.filter(p => 
        p.location.toLowerCase().includes(location.toLowerCase())
      );
    }
    
    if (search) {
      const searchLower = search.toLowerCase();
      productList = productList.filter(p =>
        p.name.toLowerCase().includes(searchLower) ||
        p.description.toLowerCase().includes(searchLower) ||
        p.tags.some(tag => tag.toLowerCase().includes(searchLower))
      );
    }
    
    // Sort products
    productList.sort((a, b) => {
      let aVal = a[sortBy];
      let bVal = b[sortBy];
      
      if (sortBy === 'createdAt') {
        aVal = new Date(aVal);
        bVal = new Date(bVal);
      }
      
      if (sortOrder === 'desc') {
        return bVal > aVal ? 1 : -1;
      } else {
        return aVal > bVal ? 1 : -1;
      }
    });
    
    // Pagination
    const startIndex = (parseInt(page) - 1) * parseInt(limit);
    const endIndex = startIndex + parseInt(limit);
    const paginatedProducts = productList.slice(startIndex, endIndex);
    
    res.json({
      success: true,
      data: paginatedProducts,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(productList.length / parseInt(limit)),
        totalItems: productList.length,
        itemsPerPage: parseInt(limit)
      }
    });
    
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch products'
    });
  }
});

app.get('/api/products/:productId', authenticate, (req, res) => {
  try {
    const product = products.get(req.params.productId);
    
    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }
    
    // Increment view count
    product.viewCount = (product.viewCount || 0) + 1;
    products.set(product.id, product);
    
    // Update selling history view count
    const sellerHistory = sellingHistory.get(product.sellerId) || [];
    const historyItem = sellerHistory.find(h => h.productId === product.id);
    if (historyItem) {
      historyItem.totalViews = product.viewCount;
      sellingHistory.set(product.sellerId, sellerHistory);
    }
    
    res.json({
      success: true,
      data: product
    });
    
  } catch (error) {
    console.error('Error fetching product:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch product'
    });
  }
});

// Selling History
app.get('/api/users/:userId/selling-history', authenticate, (req, res) => {
  try {
    const userId = req.params.userId;
    
    // Check if user is requesting their own history or has permission
    if (req.user.uid !== userId && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    const history = sellingHistory.get(userId) || [];
    
    // Add current product data to history items
    const enrichedHistory = history.map(item => {
      const currentProduct = products.get(item.productId);
      return {
        ...item,
        currentProductData: currentProduct,
        performanceMetrics: {
          daysListed: Math.ceil((Date.now() - new Date(item.listedDate).getTime()) / (1000 * 60 * 60 * 24)),
          conversionRate: item.totalInquiries > 0 ? (item.soldQuantity / item.totalInquiries * 100) : 0,
          avgRevenuePerDay: item.totalRevenue / Math.max(1, Math.ceil((Date.now() - new Date(item.listedDate).getTime()) / (1000 * 60 * 60 * 24))),
          sellThroughRate: item.originalQuantity > 0 ? (item.soldQuantity / item.originalQuantity * 100) : 0,
          totalOffers: (priceOffers.get(item.productId) || []).length,
          totalInterests: (buyerInterests.get(item.productId) || []).length
        }
      };
    });
    
    res.json({
      success: true,
      data: enrichedHistory
    });
    
  } catch (error) {
    console.error('Error fetching selling history:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch selling history'
    });
  }
});

// Buyer Interest Management
app.post('/api/products/:productId/interest', authenticate, requireRole(['addat', 'farmer']), (req, res) => {
  try {
    const productId = req.params.productId;
    const { message, interestedQuantity, contactPreference } = req.body;
    
    const product = products.get(productId);
    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }
    
    // Don't allow sellers to show interest in their own products
    if (product.sellerId === req.user.uid) {
      return res.status(400).json({
        success: false,
        error: 'Cannot show interest in your own product'
      });
    }
    
    const interests = buyerInterests.get(productId) || [];
    
    // Check if user already showed interest
    const existingInterest = interests.find(i => i.buyerId === req.user.uid);
    if (existingInterest) {
      return res.status(400).json({
        success: false,
        error: 'You have already shown interest in this product'
      });
    }
    
    const interest = {
      id: generateId('interest'),
      productId,
      buyerId: req.user.uid,
      buyerName: req.user.fullName,
      buyerEmail: req.user.email,
      message: message || '',
      interestedQuantity: parseInt(interestedQuantity) || 1,
      contactPreference: contactPreference || 'email',
      status: 'pending',
      createdAt: new Date().toISOString()
    };
    
    interests.push(interest);
    buyerInterests.set(productId, interests);
    
    // Update product inquiry count
    product.inquiryCount = (product.inquiryCount || 0) + 1;
    products.set(productId, product);
    
    // Update selling history inquiry count
    const sellerHistory = sellingHistory.get(product.sellerId) || [];
    const historyItem = sellerHistory.find(h => h.productId === productId);
    if (historyItem) {
      historyItem.totalInquiries = product.inquiryCount;
      sellingHistory.set(product.sellerId, sellerHistory);
    }
    
    res.status(201).json({
      success: true,
      data: interest,
      message: 'Interest registered successfully'
    });
    
  } catch (error) {
    console.error('Error registering interest:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to register interest'
    });
  }
});

app.get('/api/products/:productId/interests', authenticate, (req, res) => {
  try {
    const productId = req.params.productId;
    const product = products.get(productId);
    
    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }
    
    // Only product owner can see interests
    if (product.sellerId !== req.user.uid) {
      return res.status(403).json({
        success: false,
        error: 'Access denied. Only product owner can view interests.'
      });
    }
    
    const interests = buyerInterests.get(productId) || [];
    
    res.json({
      success: true,
      data: interests
    });
    
  } catch (error) {
    console.error('Error fetching interests:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch interests'
    });
  }
});

// Price Offer Management
app.post('/api/products/:productId/offers', authenticate, requireRole(['addat', 'farmer']), (req, res) => {
  try {
    const productId = req.params.productId;
    const { offeredPrice, quantity, message, validUntil } = req.body;
    
    const product = products.get(productId);
    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }
    
    // Don't allow sellers to make offers on their own products
    if (product.sellerId === req.user.uid) {
      return res.status(400).json({
        success: false,
        error: 'Cannot make offer on your own product'
      });
    }
    
    if (!offeredPrice || !quantity) {
      return res.status(400).json({
        success: false,
        error: 'Offered price and quantity are required'
      });
    }
    
    const offers = priceOffers.get(productId) || [];
    
    const offer = {
      id: generateId('offer'),
      productId,
      buyerId: req.user.uid,
      buyerName: req.user.fullName,
      buyerEmail: req.user.email,
      offeredPrice: parseFloat(offeredPrice),
      quantity: parseInt(quantity),
      message: message || '',
      status: 'pending',
      validUntil: validUntil ? new Date(validUntil).toISOString() : null,
      createdAt: new Date().toISOString()
    };
    
    offers.push(offer);
    priceOffers.set(productId, offers);
    
    res.status(201).json({
      success: true,
      data: offer,
      message: 'Price offer submitted successfully'
    });
    
  } catch (error) {
    console.error('Error creating offer:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create offer'
    });
  }
});

app.get('/api/products/:productId/offers', authenticate, (req, res) => {
  try {
    const productId = req.params.productId;
    const product = products.get(productId);
    
    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }
    
    // Only product owner can see offers
    if (product.sellerId !== req.user.uid) {
      return res.status(403).json({
        success: false,
        error: 'Access denied. Only product owner can view offers.'
      });
    }
    
    const offers = priceOffers.get(productId) || [];
    
    // Sort offers by price (highest first) and date
    offers.sort((a, b) => {
      if (b.offeredPrice !== a.offeredPrice) {
        return b.offeredPrice - a.offeredPrice;
      }
      return new Date(b.createdAt) - new Date(a.createdAt);
    });
    
    res.json({
      success: true,
      data: offers
    });
    
  } catch (error) {
    console.error('Error fetching offers:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch offers'
    });
  }
});

// Offer Management (Accept/Reject)
app.put('/api/offers/:offerId', authenticate, (req, res) => {
  try {
    const offerId = req.params.offerId;
    const { status, response } = req.body;
    
    if (!['accepted', 'rejected'].includes(status)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid status. Must be "accepted" or "rejected"'
      });
    }
    
    // Find the offer
    let foundOffer = null;
    let productId = null;
    
    for (const [pid, offers] of priceOffers.entries()) {
      const offer = offers.find(o => o.id === offerId);
      if (offer) {
        foundOffer = offer;
        productId = pid;
        break;
      }
    }
    
    if (!foundOffer) {
      return res.status(404).json({
        success: false,
        error: 'Offer not found'
      });
    }
    
    const product = products.get(productId);
    if (!product || product.sellerId !== req.user.uid) {
      return res.status(403).json({
        success: false,
        error: 'Access denied. Only product owner can manage offers.'
      });
    }
    
    foundOffer.status = status;
    foundOffer.response = response || '';
    foundOffer.respondedAt = new Date().toISOString();
    
    // If accepted, create a transaction
    if (status === 'accepted') {
      const transaction = {
        id: generateId('transaction'),
        productId: productId,
        sellerId: product.sellerId,
        buyerId: foundOffer.buyerId,
        offerId: offerId,
        quantity: foundOffer.quantity,
        pricePerUnit: foundOffer.offeredPrice,
        totalAmount: foundOffer.offeredPrice * foundOffer.quantity,
        status: 'confirmed',
        createdAt: new Date().toISOString()
      };
      
      transactions.set(transaction.id, transaction);
      
      // Update product quantity
      product.quantity = Math.max(0, product.quantity - foundOffer.quantity);
      if (product.quantity === 0) {
        product.isAvailable = false;
      }
      products.set(productId, product);
      
      // Update selling history
      const sellerHistory = sellingHistory.get(product.sellerId) || [];
      const historyItem = sellerHistory.find(h => h.productId === productId);
      if (historyItem) {
        historyItem.soldQuantity += foundOffer.quantity;
        historyItem.currentQuantity = product.quantity;
        historyItem.totalRevenue += transaction.totalAmount;
        if (product.quantity === 0) {
          historyItem.status = 'sold_out';
          historyItem.isActive = false;
        }
        sellingHistory.set(product.sellerId, sellerHistory);
      }
    }
    
    res.json({
      success: true,
      data: foundOffer,
      message: `Offer ${status} successfully`
    });
    
  } catch (error) {
    console.error('Error updating offer:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update offer'
    });
  }
});

// Statistics and Analytics
app.get('/api/users/:userId/stats', authenticate, (req, res) => {
  try {
    const userId = req.params.userId;
    
    if (req.user.uid !== userId && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    const userProducts = Array.from(products.values()).filter(p => p.sellerId === userId);
    const userHistory = sellingHistory.get(userId) || [];
    
    const stats = {
      totalProducts: userProducts.length,
      activeProducts: userProducts.filter(p => p.isAvailable).length,
      totalViews: userProducts.reduce((sum, p) => sum + (p.viewCount || 0), 0),
      totalInquiries: userProducts.reduce((sum, p) => sum + (p.inquiryCount || 0), 0),
      totalRevenue: userHistory.reduce((sum, h) => sum + (h.totalRevenue || 0), 0),
      totalSales: userHistory.reduce((sum, h) => sum + (h.soldQuantity || 0), 0),
      averageRating: 4.2, // Mock rating
      responseTime: '2 hours', // Mock response time
      completionRate: userHistory.length > 0 ? 
        (userHistory.filter(h => h.status === 'completed').length / userHistory.length * 100) : 0
    };
    
    res.json({
      success: true,
      data: stats
    });
    
  } catch (error) {
    console.error('Error fetching stats:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch statistics'
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Server error:', error);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
    availableEndpoints: [
      'GET /api/health',
      'POST /api/users',
      'GET /api/users/:userId',
      'POST /api/products',
      'GET /api/products',
      'GET /api/products/:productId',
      'GET /api/users/:userId/selling-history',
      'POST /api/products/:productId/interest',
      'GET /api/products/:productId/interests',
      'POST /api/products/:productId/offers',
      'GET /api/products/:productId/offers',
      'PUT /api/offers/:offerId',
      'GET /api/users/:userId/stats'
    ]
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 FarmKart Enhanced Marketplace Backend running on port ${PORT}`);
  console.log('📊 Available endpoints:');
  console.log('  🏥 GET /api/health - Health check');
  console.log('  👤 POST /api/users - Create user profile');
  console.log('  👤 GET /api/users/:userId - Get user profile');
  console.log('  📦 POST /api/products - Create product (farmers only)');
  console.log('  📦 GET /api/products - Get products with filters');
  console.log('  📦 GET /api/products/:productId - Get product details');
  console.log('  📈 GET /api/users/:userId/selling-history - Get selling history');
  console.log('  💝 POST /api/products/:productId/interest - Show interest in product');
  console.log('  💝 GET /api/products/:productId/interests - Get product interests (sellers only)');
  console.log('  💰 POST /api/products/:productId/offers - Make price offer');
  console.log('  💰 GET /api/products/:productId/offers - Get price offers (sellers only)');
  console.log('  ✅ PUT /api/offers/:offerId - Accept/reject offer');
  console.log('  📊 GET /api/users/:userId/stats - Get user statistics');
  console.log('');
  console.log('🔐 Authentication: Include "Authorization: Bearer <token>" header');
  console.log('🛡️ Role-based access: farmers can create products, addats can buy');
});

module.exports = app;