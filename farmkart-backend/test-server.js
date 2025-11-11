// Simple test server for product management without Firebase
const express = require('express');
const cors = require('cors');
const multer = require('multer');

const app = express();
const PORT = process.env.PORT || 3002; // Changed port to avoid conflicts

// Middleware - CORS must be first with explicit Flutter web support
app.use(cors({
  origin: true, // Allow all origins for development
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin', 'X-Requested-With'],
  optionsSuccessStatus: 200 // Support legacy browsers
}));

// Handle preflight requests explicitly
app.options('*', cors());

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Configure multer for file uploads
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type'), false);
    }
  }
});

// In-memory storage for testing
const products = [];
const sellingHistory = [];
let productIdCounter = 1;

// Test authentication middleware
const testAuth = (req, res, next) => {
  // For testing, accept any Authorization header
  const authHeader = req.headers['authorization'];
  if (!authHeader) {
    return res.status(401).json({ success: false, error: 'Authorization required' });
  }
  
  // Mock user data
  req.user = { uid: 'test-user-123' };
  req.userRole = 'addat';
  req.userProfile = { fullName: 'Test User', role: 'addat' };
  next();
};

// Routes

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    service: 'FarmKart Test Backend'
  });
});

// Create product
app.post('/api/products', testAuth, upload.array('images', 5), (req, res) => {
  try {
    console.log('Received product creation request');
    console.log('Headers:', req.headers);
    console.log('Body:', req.body);
    console.log('Files:', req.files ? req.files.length : 0);
    console.log('Raw body type:', typeof req.body);
    
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

    // Validate required fields with better error messages
    const missingFields = [];
    if (!name) missingFields.push('name');
    if (!category) missingFields.push('category');
    if (!price && price !== 0) missingFields.push('price');
    if (!unit) missingFields.push('unit');
    if (quantity === undefined || quantity === null) missingFields.push('quantity');
    
    if (missingFields.length > 0) {
      return res.status(400).json({
        success: false,
        error: `Missing required fields: ${missingFields.join(', ')}`,
        received: {
          name: !!name,
          category: !!category,
          price: !!price,
          unit: !!unit,
          quantity: quantity !== undefined,
        }
      });
    }

    // Parse tags if it's a string
    let parsedTags = [];
    try {
      parsedTags = tags ? (typeof tags === 'string' ? JSON.parse(tags) : tags) : [];
    } catch (e) {
      console.log('Warning: Could not parse tags, using empty array');
      parsedTags = [];
    }

    // Mock image URLs
    const imageUrls = req.files ? req.files.map((_, index) => 
      `https://via.placeholder.com/400x300?text=Product+Image+${index + 1}`
    ) : [];

    const product = {
      id: `product_${productIdCounter++}`,
      name: String(name || ''),
      description: String(description || ''),
      category: String(category || 'Other'),
      price: parseFloat(price) || 0,
      unit: String(unit || 'kg'),
      quantity: parseInt(quantity) || 0,
      sellerId: req.user.uid,
      sellerName: req.userProfile.fullName,
      location: String(location || ''),
      imageUrls,
      tags: Array.isArray(parsedTags) ? parsedTags : [],
      isOrganic: isOrganic === 'true' || isOrganic === true,
      isAvailable: true,
      harvestDate: harvestDate || null,
      expiryDate: expiryDate || null,
      certificationDetails: certificationDetails || null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      timestamp: new Date(),
      viewCount: 0,
      likeCount: 0,
      inquiryCount: 0
    };

    products.push(product);

    // Add to selling history
    const historyItem = {
      id: `history_${productIdCounter}`,
      productId: product.id,
      sellerId: req.user.uid,
      productName: product.name,
      category: product.category,
      originalPrice: product.price,
      currentPrice: product.price,
      originalQuantity: product.quantity,
      currentQuantity: product.quantity,
      soldQuantity: 0,
      status: 'active',
      imageUrl: imageUrls.length > 0 ? imageUrls[0] : '',
      listedDate: new Date().toISOString(),
      totalRevenue: 0,
      totalInquiries: 0,
      totalViews: 0,
      isActive: true,
      performanceMetrics: {
        daysListed: 1,
        conversionRate: 0,
        avgRevenuePerDay: 0,
        sellThroughRate: 0,
        totalInquiries: 0,
        totalViews: 0,
        totalRevenue: 0,
        remainingQuantity: product.quantity,
        status: 'active'
      }
    };

    sellingHistory.push(historyItem);

    console.log('Product created successfully:', product.id);

    res.status(201).json({
      success: true,
      data: product,
      message: 'Product created successfully'
    });

  } catch (error) {
    console.error('Error creating product:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to create product',
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// Get products
app.get('/api/products', (req, res) => {
  try {
    const {
      category,
      sellerId,
      excludeSeller,
      limit = 20,
      page = 1,
      isAvailable = 'true',
      search
    } = req.query;

    let filteredProducts = [...products];

    // Apply filters
    if (category && category !== 'All') {
      filteredProducts = filteredProducts.filter(p => p.category === category);
    }

    if (sellerId) {
      filteredProducts = filteredProducts.filter(p => p.sellerId === sellerId);
    }

    if (excludeSeller) {
      filteredProducts = filteredProducts.filter(p => p.sellerId !== excludeSeller);
    }

    if (isAvailable === 'true') {
      filteredProducts = filteredProducts.filter(p => p.isAvailable);
    }

    if (search) {
      const searchLower = search.toLowerCase();
      filteredProducts = filteredProducts.filter(p =>
        p.name.toLowerCase().includes(searchLower) ||
        p.description.toLowerCase().includes(searchLower)
      );
    }

    // Pagination
    const startIndex = (parseInt(page) - 1) * parseInt(limit);
    const endIndex = startIndex + parseInt(limit);
    const paginatedProducts = filteredProducts.slice(startIndex, endIndex);

    res.json({
      success: true,
      data: paginatedProducts,
      pagination: {
        currentPage: parseInt(page),
        limit: parseInt(limit),
        totalProducts: filteredProducts.length,
        totalPages: Math.ceil(filteredProducts.length / parseInt(limit)),
        hasMore: endIndex < filteredProducts.length
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to fetch products'
    });
  }
});

// Get product by ID
app.get('/api/products/:id', (req, res) => {
  try {
    const { id } = req.params;
    const product = products.find(p => p.id === id);
    
    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }

    // Increment view count
    product.viewCount = (product.viewCount || 0) + 1;

    res.json({
      success: true,
      data: product
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to fetch product'
    });
  }
});

// Get selling history - Apply auth middleware only, no body parsing issues
app.get('/api/users/:userId/selling-history', (req, res, next) => {
  // Manual auth check for GET request
  const authHeader = req.headers['authorization'];
  if (!authHeader) {
    return res.status(401).json({ success: false, error: 'Authorization required' });
  }
  
  req.user = { uid: 'test-user-123' };
  req.userRole = 'addat';
  req.userProfile = { fullName: 'Test User', role: 'addat' };
  next();
}, (req, res) => {
  try {
    const { userId } = req.params;

    if (req.user.uid !== userId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }

    const userHistory = sellingHistory.filter(item => item.sellerId === userId);
    
    // Calculate summary
    const summary = {
      totalRevenue: userHistory.reduce((sum, item) => sum + item.totalRevenue, 0),
      totalListings: userHistory.length,
      activeListings: userHistory.filter(item => item.status === 'active').length,
      soldOutListings: userHistory.filter(item => item.status === 'sold_out').length,
      avgRevenuePerListing: userHistory.length > 0 ? 
        userHistory.reduce((sum, item) => sum + item.totalRevenue, 0) / userHistory.length : 0
    };

    res.json({
      success: true,
      data: userHistory,
      summary,
      pagination: {
        currentPage: 1,
        limit: 20,
        hasMore: false
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to fetch selling history'
    });
  }
});

// Error handling
app.use((error, req, res, next) => {
  console.error('Server error:', error);
  res.status(500).json({
    success: false,
    error: 'Internal server error'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 FarmKart Test Backend Server running on port ${PORT}`);
  console.log(`📋 Available endpoints:`);
  console.log(`  🛒 POST /api/products - Create product`);
  console.log(`  🛒 GET /api/products - Get products`);
  console.log(`  🛒 GET /api/products/:id - Get product by ID`);
  console.log(`  📊 GET /api/users/:userId/selling-history - Get selling history`);
  console.log(`  ⚕️ GET /api/health - Health check`);
});

module.exports = app;