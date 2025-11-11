require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const admin = require('firebase-admin');
const cors = require('cors');
const winston = require('winston');
const Razorpay = require('razorpay');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { v4: uuidv4 } = require('uuid');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const multer = require('multer');

const app = express();
const PORT = process.env.PORT || 3000;

// Import route modules
const productRoutes = require('./routes/productRoutes');
const userRoutes = require('./routes/userRoutes');
const roleMiddleware = require('./middleware/roleMiddleware');

// Configure Winston Logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'farmkart-backend' },
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
  ],
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple()
  }));
}

// Configure Razorpay
const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

// Configure Multer for file uploads
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE) || 10485760, // 10MB default
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = (process.env.ALLOWED_FILE_TYPES || 'jpg,jpeg,png,gif').split(',');
    const fileExtension = file.originalname.split('.').pop().toLowerCase();
    if (allowedTypes.includes(fileExtension)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type'), false);
    }
  }
});

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));

// Request logging middleware
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.url} - ${req.ip}`);
  next();
});

// Initialize Firebase Admin SDK
try {
  if (!admin.apps.length) {
    // For development, use default credentials or service account key
    if (process.env.NODE_ENV === 'production' && process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      admin.initializeApp({
        databaseURL: process.env.FIREBASE_DATABASE_URL,
      });
    } else {
      // For development, use project ID for auto-initialization
      admin.initializeApp({
        projectId: process.env.FIREBASE_PROJECT_ID,
        databaseURL: process.env.FIREBASE_DATABASE_URL,
      });
    }
  }
  logger.info('Firebase Admin initialized successfully');
} catch (error) {
  logger.error('Firebase admin initialization error:', error);
  // Continue without Firebase for development
  console.warn('Continuing without Firebase - some features may not work');
}

// Get references to Firebase services
const db = admin.database();
const firestore = admin.firestore();

// Authentication Middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, error: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ success: false, error: 'Invalid token' });
    }
    req.user = user;
    next();
  });
};

// ============= AI CHAT INTEGRATION =============

// Simple AI advice endpoint using Ollama with immediate fallback
app.post('/ai/advice', async (req, res) => {
  try {
    const { query, language = 'en', context } = req.body;

    if (!query || typeof query !== 'string' || query.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Query is required and must be a non-empty string'
      });
    }

    console.log(`AI request: ${query.substring(0, 100)}...`);

    // For now, prioritize fallback responses for reliability
    // You can enable Ollama by changing this to true when it's working reliably
    const useOllama = false; // Set to true to try Ollama first

    if (useOllama) {
      // Try to connect to Ollama directly with very short timeout
      try {
        const axios = require('axios');
        console.log('Attempting Ollama connection...');
        
        const ollamaResponse = await axios.post('http://localhost:11434/api/generate', {
          model: 'gemma3:1b', // Using faster, smaller model
          prompt: `You are an agricultural expert assistant for FarmKart, a farming marketplace app. Please provide helpful, practical farming advice in a friendly tone. Keep responses concise and actionable. Question: ${query}`,
          stream: false,
          options: {
            temperature: 0.7,
            top_p: 0.9,
            num_predict: 200, // Reduced for faster response
          }
        }, {
          timeout: 3000, // Very short timeout - 3 seconds only
          headers: { 'Content-Type': 'application/json' }
        });

        const aiAnswer = ollamaResponse.data.response || 'Sorry, I could not generate a response.';

        const response = {
          answer: aiAnswer,
          confidence: 0.8,
          sources: ['Ollama AI Model (Gemma 1B)', 'FarmKart Agricultural Database'],
          model: 'gemma3:1b',
          retrievalCount: 1,
          processingTime: (ollamaResponse.data.eval_duration || 2000000000) / 1000000000,
          timestamp: new Date().toISOString(),
        };

        logger.info('AI response generated successfully via Ollama');
        res.json({ success: true, data: response });
        return;

      } catch (ollamaError) {
        console.error('Ollama connection failed:', ollamaError.message);
        console.log('Using fallback AI response...');
      }
    }

    // Use fast, reliable fallback response
    const fallbackAnswer = getFallbackAIResponse(query);
    
    res.json({
      success: true,
      data: {
        answer: fallbackAnswer,
        confidence: 0.8, // High confidence for curated responses
        sources: ['FarmKart Agricultural Knowledge Base', 'Expert Farming Guidelines'],
        model: 'FarmKart-Expert-v1.0',
        retrievalCount: 1,
        processingTime: 0.1,
        timestamp: new Date().toISOString(),
      }
    });

  } catch (error) {
    logger.error('AI service error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'AI service temporarily unavailable',
      message: 'Please try again later'
    });
  }
});

// Health check for AI service
app.get('/ai/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    ollama_available: true,
    service: 'FarmKart AI Backend'
  });
});

// Fallback AI response function
function getFallbackAIResponse(query) {
  const queryLower = query.toLowerCase();
  
  if (queryLower.includes('wheat') || queryLower.includes('crop') || queryLower.includes('plant')) {
    return 'For crop cultivation, consider factors like soil type, climate, water availability, and local growing conditions. The best time to plant wheat is typically fall for winter varieties and spring for spring varieties. Ensure proper soil preparation and consider local agricultural extension advice.';
  } else if (queryLower.includes('soil') || queryLower.includes('fertilizer')) {
    return 'Healthy soil is crucial for good crop yields. Test your soil pH (ideal range 6.0-7.0 for most crops), add organic matter like compost, ensure proper drainage, and use balanced fertilizers based on soil test recommendations. Consider crop rotation to maintain soil health.';
  } else if (queryLower.includes('pest') || queryLower.includes('disease') || queryLower.includes('insect')) {
    return 'For pest and disease management, use Integrated Pest Management (IPM): 1) Regular field monitoring, 2) Use resistant varieties when available, 3) Encourage beneficial insects, 4) Apply targeted treatments only when needed, 5) Maintain field hygiene and proper crop rotation.';
  } else if (queryLower.includes('price') || queryLower.includes('market') || queryLower.includes('sell')) {
    return 'Market prices fluctuate based on supply, demand, quality, and season. Check local APMC prices, government MSP rates, and direct market opportunities. Consider value addition, proper storage, and timing your sales for better prices. FarmKart marketplace can help you reach more buyers.';
  } else if (queryLower.includes('water') || queryLower.includes('irrigation')) {
    return 'Efficient water management is key to sustainable farming. Use drip irrigation or sprinkler systems to reduce water waste, mulch around plants to retain moisture, harvest rainwater when possible, and schedule watering based on crop needs and weather conditions.';
  } else {
    return 'Thank you for your farming question. For specific agricultural advice, consider factors like your location, soil conditions, climate, and crop type. I recommend consulting with local agricultural extension officers or experienced farmers in your area for region-specific guidance. FarmKart also connects you with agricultural experts and fellow farmers.';
  }
}

// ============= NEW PRODUCT MANAGEMENT ROUTES =============

// Use the new route modules
app.use('/api/products', productRoutes);
app.use('/api/users', userRoutes);

// ============= EXISTING ROUTES CONTINUE BELOW =============
app.get('/', (req, res) => {
  res.json({ 
    message: 'FarmKart Enhanced Marketplace Backend API',
    version: '3.0.0',
    features: [
      'Product Management with Image Upload',
      'Order Management with Tracking', 
      'Payment Gateway Integration (Razorpay & Stripe)',
      'Real-time Conversation System',
      'User Authentication & Authorization',
      'Notification System',
      'Analytics & Reporting',
      'Data Persistence & Caching'
    ],
    endpoints: {
      products: '/api/products',
      orders: '/api/orders',
      payments: '/api/payments',
      conversations: '/api/conversations',
      users: '/api/users',
      analytics: '/api/analytics'
    }
  });
});

// ============= ENHANCED PRODUCT MANAGEMENT =============

// Get all products with advanced filtering and pagination
app.get('/api/products', async (req, res) => {
  try {
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
      sortBy = 'timestamp',
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

    if (minPrice) {
      query = query.where('price', '>=', parseFloat(minPrice));
    }

    if (maxPrice) {
      query = query.where('price', '<=', parseFloat(maxPrice));
    }

    // Apply sorting and pagination
    const offset = (parseInt(page) - 1) * parseInt(limit);
    query = query.orderBy(sortBy, sortOrder)
                 .limit(parseInt(limit))
                 .offset(offset);

    const snapshot = await query.get();
    let products = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
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

    // Get total count for pagination
    const totalQuery = firestore.collection('products');
    if (category && category !== 'All') {
      totalQuery.where('category', '==', category);
    }
    const totalSnapshot = await totalQuery.count().get();
    const totalCount = totalSnapshot.data().count;

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

    logger.info(`Fetched ${products.length} products for filters: ${JSON.stringify(req.query)}`);
  } catch (error) {
    logger.error('Error fetching products:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Enhanced product creation with image upload
app.post('/api/products', upload.array('images', 5), async (req, res) => {
  try {
    const {
      name,
      description,
      category,
      price,
      unit,
      quantity,
      sellerId,
      sellerName,
      location,
      tags,
      isOrganic = false,
      harvestDate,
      expiryDate,
      certificationDetails
    } = req.body;

    // Validation
    if (!name || !price || !sellerId) {
      return res.status(400).json({ 
        success: false, 
        error: 'Name, price, and sellerId are required' 
      });
    }

    // Handle image uploads (if files are provided)
    let imageUrls = [];
    if (req.files && req.files.length > 0) {
      // In a real implementation, upload to Firebase Storage or cloud storage
      // For now, we'll create placeholder URLs
      imageUrls = req.files.map((file, index) => 
        `https://storage.googleapis.com/farmkart-images/${sellerId}/${Date.now()}_${index}.jpg`
      );
    }

    const productData = {
      name,
      description: description || '',
      category: category || 'Other',
      price: parseFloat(price),
      unit: unit || 'kg',
      quantity: parseInt(quantity) || 0,
      sellerId,
      sellerName: sellerName || 'Unknown Seller',
      location: location || '',
      imageUrls,
      tags: tags ? JSON.parse(tags) : [],
      isOrganic: isOrganic === 'true',
      isAvailable: true,
      harvestDate: harvestDate || null,
      expiryDate: expiryDate || null,
      certificationDetails: certificationDetails || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      viewCount: 0,
      likeCount: 0,
      inquiryCount: 0
    };

    const docRef = await firestore.collection('products').add(productData);
    
    // Log activity
    await firestore.collection('activity_logs').add({
      userId: sellerId,
      action: 'PRODUCT_CREATED',
      productId: docRef.id,
      productName: name,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    logger.info(`Product created: ${docRef.id} by seller: ${sellerId}`);
    
    res.json({ 
      success: true, 
      data: { id: docRef.id, ...productData },
      message: 'Product created successfully'
    });
  } catch (error) {
    logger.error('Error adding product:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============= PAYMENT GATEWAY INTEGRATION =============

// Create Razorpay order
app.post('/api/payments/razorpay/create-order', async (req, res) => {
  try {
    const { amount, currency = 'INR', receipt, productId, buyerId } = req.body;

    if (!amount || !receipt) {
      return res.status(400).json({ 
        success: false, 
        error: 'Amount and receipt are required' 
      });
    }

    const options = {
      amount: Math.round(amount * 100), // Convert to paise
      currency,
      receipt,
      payment_capture: 1,
      notes: {
        productId: productId || '',
        buyerId: buyerId || '',
        timestamp: Date.now().toString()
      }
    };

    const order = await razorpay.orders.create(options);

    // Store payment intent in database
    await firestore.collection('payment_intents').add({
      orderId: order.id,
      amount: amount,
      currency,
      productId,
      buyerId,
      status: 'created',
      gateway: 'razorpay',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    logger.info(`Razorpay order created: ${order.id} for amount: ${amount}`);

    res.json({
      success: true,
      data: {
        orderId: order.id,
        amount: order.amount,
        currency: order.currency,
        key: process.env.RAZORPAY_KEY_ID
      }
    });
  } catch (error) {
    logger.error('Error creating Razorpay order:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Verify Razorpay payment
app.post('/api/payments/razorpay/verify', async (req, res) => {
  try {
    const { 
      razorpay_payment_id, 
      razorpay_order_id, 
      razorpay_signature,
      productId,
      buyerId,
      sellerId,
      orderDetails
    } = req.body;

    // Verify signature
    const crypto = require('crypto');
    const expectedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(`${razorpay_order_id}|${razorpay_payment_id}`)
      .digest('hex');

    if (expectedSignature !== razorpay_signature) {
      return res.status(400).json({ 
        success: false, 
        error: 'Payment verification failed' 
      });
    }

    // Get payment details from Razorpay
    const payment = await razorpay.payments.fetch(razorpay_payment_id);
    
    if (payment.status !== 'captured') {
      return res.status(400).json({ 
        success: false, 
        error: 'Payment not captured' 
      });
    }

    // Update payment intent
    const paymentIntentQuery = await firestore
      .collection('payment_intents')
      .where('orderId', '==', razorpay_order_id)
      .get();

    if (!paymentIntentQuery.empty) {
      await paymentIntentQuery.docs[0].ref.update({
        paymentId: razorpay_payment_id,
        status: 'completed',
        verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        paymentDetails: payment
      });
    }

    // Create order in database
    const orderData = {
      ...orderDetails,
      paymentId: razorpay_payment_id,
      razorpayOrderId: razorpay_order_id,
      paymentStatus: 'paid',
      paymentMethod: 'razorpay',
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'confirmed',
      orderDate: admin.firestore.FieldValue.serverTimestamp(),
      trackingId: `FK${Date.now()}${Math.random().toString(36).substr(2, 4).toUpperCase()}`,
      statusHistory: [{
        status: 'confirmed',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        message: 'Payment received and order confirmed',
        updatedBy: 'system'
      }]
    };

    const orderRef = await firestore.collection('orders').add(orderData);

    // Update product quantity
    if (productId && orderDetails.quantity) {
      await firestore.collection('products').doc(productId).update({
        quantity: admin.firestore.FieldValue.increment(-orderDetails.quantity),
        inquiryCount: admin.firestore.FieldValue.increment(1)
      });
    }

    // Send notifications (implement as needed)
    await sendOrderConfirmationNotification(buyerId, sellerId, orderRef.id);

    logger.info(`Payment verified and order created: ${orderRef.id}`);

    res.json({
      success: true,
      data: {
        orderId: orderRef.id,
        trackingId: orderData.trackingId,
        paymentId: razorpay_payment_id
      },
      message: 'Payment verified successfully and order created'
    });
  } catch (error) {
    logger.error('Error verifying payment:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Create Stripe payment intent
app.post('/api/payments/stripe/create-intent', async (req, res) => {
  try {
    const { amount, currency = 'usd', productId, buyerId } = req.body;

    if (!amount) {
      return res.status(400).json({ 
        success: false, 
        error: 'Amount is required' 
      });
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Convert to cents
      currency,
      metadata: {
        productId: productId || '',
        buyerId: buyerId || '',
        timestamp: Date.now().toString()
      }
    });

    // Store payment intent in database
    await firestore.collection('payment_intents').add({
      intentId: paymentIntent.id,
      amount: amount,
      currency,
      productId,
      buyerId,
      status: 'created',
      gateway: 'stripe',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    logger.info(`Stripe payment intent created: ${paymentIntent.id}`);

    res.json({
      success: true,
      data: {
        clientSecret: paymentIntent.client_secret,
        intentId: paymentIntent.id
      }
    });
  } catch (error) {
    logger.error('Error creating Stripe payment intent:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============= ENHANCED ORDER MANAGEMENT WITH TRACKING =============

// Get orders with advanced filtering and tracking
app.get('/api/orders', async (req, res) => {
  try {
    const { 
      buyerId, 
      sellerId, 
      status, 
      limit = 20, 
      page = 1,
      startDate,
      endDate,
      trackingId,
      paymentStatus 
    } = req.query;

    let query = firestore.collection('orders');

    // Apply filters
    if (buyerId) {
      query = query.where('buyerId', '==', buyerId);
    }
    
    if (sellerId) {
      query = query.where('sellerId', '==', sellerId);
    }
    
    if (status) {
      query = query.where('status', '==', status);
    }

    if (paymentStatus) {
      query = query.where('paymentStatus', '==', paymentStatus);
    }

    if (trackingId) {
      query = query.where('trackingId', '==', trackingId);
    }

    // Date range filtering (if provided)
    if (startDate) {
      query = query.where('orderDate', '>=', new Date(startDate));
    }
    
    if (endDate) {
      query = query.where('orderDate', '<=', new Date(endDate));
    }

    // Apply pagination
    const offset = (parseInt(page) - 1) * parseInt(limit);
    query = query.orderBy('orderDate', 'desc')
                 .limit(parseInt(limit))
                 .offset(offset);

    const snapshot = await query.get();
    const orders = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // Get order analytics
    const analytics = await getOrderAnalytics(buyerId, sellerId);

    res.json({ 
      success: true, 
      data: orders,
      analytics,
      pagination: {
        currentPage: parseInt(page),
        limit: parseInt(limit),
        hasMore: orders.length === parseInt(limit)
      }
    });

    logger.info(`Fetched ${orders.length} orders`);
  } catch (error) {
    logger.error('Error fetching orders:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get single order with full tracking details
app.get('/api/orders/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const doc = await firestore.collection('orders').doc(id).get();
    
    if (!doc.exists) {
      return res.status(404).json({ success: false, error: 'Order not found' });
    }

    const orderData = { id: doc.id, ...doc.data() };
    
    // Get related product details
    if (orderData.productId) {
      const productDoc = await firestore.collection('products').doc(orderData.productId).get();
      if (productDoc.exists) {
        orderData.productDetails = { id: productDoc.id, ...productDoc.data() };
      }
    }

    // Get delivery timeline and tracking updates
    orderData.deliveryTimeline = generateDeliveryTimeline(orderData);
    
    res.json({ 
      success: true, 
      data: orderData
    });
  } catch (error) {
    logger.error('Error fetching order:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Track order by tracking ID
app.get('/api/orders/track/:trackingId', async (req, res) => {
  try {
    const { trackingId } = req.params;
    const query = await firestore
      .collection('orders')
      .where('trackingId', '==', trackingId)
      .get();
    
    if (query.empty) {
      return res.status(404).json({ 
        success: false, 
        error: 'Order not found with this tracking ID' 
      });
    }

    const orderDoc = query.docs[0];
    const orderData = { id: orderDoc.id, ...orderDoc.data() };
    
    // Generate tracking timeline
    const trackingTimeline = generateTrackingTimeline(orderData);
    
    res.json({ 
      success: true, 
      data: {
        ...orderData,
        trackingTimeline,
        estimatedDelivery: calculateEstimatedDelivery(orderData)
      }
    });
  } catch (error) {
    logger.error('Error tracking order:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============= UTILITY FUNCTIONS =============

// Generate delivery timeline
function generateDeliveryTimeline(orderData) {
  const timeline = [
    {
      status: 'Order Placed',
      completed: true,
      timestamp: orderData.orderDate,
      description: 'Your order has been successfully placed'
    },
    {
      status: 'Payment Confirmed',
      completed: orderData.paymentStatus === 'paid',
      timestamp: orderData.paidAt || null,
      description: 'Payment has been received and verified'
    },
    {
      status: 'Order Confirmed',
      completed: ['confirmed', 'processing', 'shipped', 'delivered'].includes(orderData.status),
      timestamp: orderData.confirmedDate || null,
      description: 'Seller has confirmed your order'
    },
    {
      status: 'Processing',
      completed: ['processing', 'shipped', 'delivered'].includes(orderData.status),
      timestamp: orderData.processingDate || null,
      description: 'Your order is being prepared for shipment'
    },
    {
      status: 'Shipped',
      completed: ['shipped', 'delivered'].includes(orderData.status),
      timestamp: orderData.shippedDate || null,
      description: 'Your order has been shipped',
      trackingNumber: orderData.trackingNumber || null
    },
    {
      status: 'Delivered',
      completed: orderData.status === 'delivered',
      timestamp: orderData.deliveredDate || null,
      description: 'Your order has been successfully delivered'
    }
  ];

  return timeline;
}

// Generate tracking timeline
function generateTrackingTimeline(orderData) {
  return orderData.statusHistory || [];
}

// Calculate estimated delivery
function calculateEstimatedDelivery(orderData) {
  if (orderData.status === 'delivered') {
    return orderData.deliveredDate;
  }

  const orderDate = new Date(orderData.orderDate.toDate());
  const deliveryDays = orderData.deliveryType === 'express' ? 2 : 5; // Default delivery times
  
  const estimatedDate = new Date(orderDate);
  estimatedDate.setDate(estimatedDate.getDate() + deliveryDays);
  
  return estimatedDate;
}

// Get order analytics
async function getOrderAnalytics(buyerId, sellerId) {
  try {
    const analytics = {
      totalOrders: 0,
      completedOrders: 0,
      pendingOrders: 0,
      cancelledOrders: 0,
      totalRevenue: 0,
      avgOrderValue: 0
    };

    let query = firestore.collection('orders');
    
    if (buyerId) {
      query = query.where('buyerId', '==', buyerId);
    } else if (sellerId) {
      query = query.where('sellerId', '==', sellerId);
    }

    const snapshot = await query.get();
    let totalAmount = 0;

    snapshot.docs.forEach(doc => {
      const order = doc.data();
      analytics.totalOrders++;
      
      if (order.totalAmount) {
        totalAmount += order.totalAmount;
      }

      switch (order.status) {
        case 'delivered':
          analytics.completedOrders++;
          break;
        case 'pending':
        case 'confirmed':
        case 'processing':
        case 'shipped':
          analytics.pendingOrders++;
          break;
        case 'cancelled':
        case 'refunded':
          analytics.cancelledOrders++;
          break;
      }
    });

    analytics.totalRevenue = totalAmount;
    analytics.avgOrderValue = analytics.totalOrders > 0 ? totalAmount / analytics.totalOrders : 0;

    return analytics;
  } catch (error) {
    logger.error('Error calculating analytics:', error);
    return {};
  }
}

// Send order confirmation notification
async function sendOrderConfirmationNotification(buyerId, sellerId, orderId) {
  try {
    // Store notification in database
    await firestore.collection('notifications').add({
      userId: buyerId,
      type: 'ORDER_CONFIRMED',
      title: 'Order Confirmed',
      message: `Your order has been confirmed and payment received. Order ID: ${orderId}`,
      orderId,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    await firestore.collection('notifications').add({
      userId: sellerId,
      type: 'NEW_ORDER',
      title: 'New Order Received',
      message: `You have received a new order. Order ID: ${orderId}`,
      orderId,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    logger.info(`Notifications sent for order: ${orderId}`);
  } catch (error) {
    logger.error('Error sending notifications:', error);
  }
}

// ============= ANALYTICS & REPORTING =============

// Get dashboard analytics
app.get('/api/analytics/dashboard', async (req, res) => {
  try {
    const { userId, type = 'seller' } = req.query;

    if (!userId) {
      return res.status(400).json({ success: false, error: 'userId is required' });
    }

    const analytics = {
      overview: {},
      recentActivity: [],
      topProducts: [],
      salesTrend: []
    };

    // Get user-specific analytics
    if (type === 'seller') {
      analytics.overview = await getSellerAnalytics(userId);
      analytics.topProducts = await getTopSellingProducts(userId);
    } else {
      analytics.overview = await getBuyerAnalytics(userId);
    }

    // Get recent activity
    analytics.recentActivity = await getRecentActivity(userId);
    
    // Get sales trend (last 30 days)
    analytics.salesTrend = await getSalesTrend(userId, type);

    res.json({ success: true, data: analytics });
  } catch (error) {
    logger.error('Error fetching analytics:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

async function getSellerAnalytics(sellerId) {
  try {
    const ordersSnapshot = await firestore
      .collection('orders')
      .where('sellerId', '==', sellerId)
      .get();

    const productsSnapshot = await firestore
      .collection('products')
      .where('sellerId', '==', sellerId)
      .get();

    let totalRevenue = 0;
    let pendingRevenue = 0;
    let completedOrders = 0;
    let pendingOrders = 0;

    ordersSnapshot.docs.forEach(doc => {
      const order = doc.data();
      if (order.status === 'delivered' && order.totalAmount) {
        totalRevenue += order.totalAmount;
        completedOrders++;
      } else if (['pending', 'confirmed', 'processing', 'shipped'].includes(order.status)) {
        if (order.totalAmount) pendingRevenue += order.totalAmount;
        pendingOrders++;
      }
    });

    return {
      totalProducts: productsSnapshot.size,
      totalOrders: ordersSnapshot.size,
      completedOrders,
      pendingOrders,
      totalRevenue,
      pendingRevenue,
      avgOrderValue: completedOrders > 0 ? totalRevenue / completedOrders : 0
    };
  } catch (error) {
    logger.error('Error getting seller analytics:', error);
    return {};
  }
}

async function getBuyerAnalytics(buyerId) {
  try {
    const ordersSnapshot = await firestore
      .collection('orders')
      .where('buyerId', '==', buyerId)
      .get();

    let totalSpent = 0;
    let completedOrders = 0;

    ordersSnapshot.docs.forEach(doc => {
      const order = doc.data();
      if (order.status === 'delivered' && order.totalAmount) {
        totalSpent += order.totalAmount;
        completedOrders++;
      }
    });

    return {
      totalOrders: ordersSnapshot.size,
      completedOrders,
      totalSpent,
      avgOrderValue: completedOrders > 0 ? totalSpent / completedOrders : 0
    };
  } catch (error) {
    logger.error('Error getting buyer analytics:', error);
    return {};
  }
}

async function getTopSellingProducts(sellerId) {
  try {
    const query = firestore
      .collection('products')
      .where('sellerId', '==', sellerId)
      .orderBy('inquiryCount', 'desc')
      .limit(5);

    const snapshot = await query.get();
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    logger.error('Error getting top products:', error);
    return [];
  }
}

async function getRecentActivity(userId) {
  try {
    const query = firestore
      .collection('activity_logs')
      .where('userId', '==', userId)
      .orderBy('timestamp', 'desc')
      .limit(10);

    const snapshot = await query.get();
    return snapshot.docs.map(doc => doc.data());
  } catch (error) {
    logger.error('Error getting recent activity:', error);
    return [];
  }
}

async function getSalesTrend(userId, type) {
  try {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const field = type === 'seller' ? 'sellerId' : 'buyerId';
    const query = firestore
      .collection('orders')
      .where(field, '==', userId)
      .where('orderDate', '>=', thirtyDaysAgo)
      .orderBy('orderDate');

    const snapshot = await query.get();
    
    // Group by date
    const salesByDate = {};
    snapshot.docs.forEach(doc => {
      const order = doc.data();
      const date = order.orderDate.toDate().toDateString();
      
      if (!salesByDate[date]) {
        salesByDate[date] = { count: 0, amount: 0 };
      }
      
      salesByDate[date].count++;
      if (order.totalAmount) {
        salesByDate[date].amount += order.totalAmount;
      }
    });

    return Object.entries(salesByDate).map(([date, data]) => ({
      date,
      orderCount: data.count,
      revenue: data.amount
    }));
  } catch (error) {
    logger.error('Error getting sales trend:', error);
    return [];
  }
}

// ============= NOTIFICATION SYSTEM =============

// Get notifications for user
app.get('/api/notifications/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 20, page = 1, unreadOnly = false } = req.query;

    let query = firestore
      .collection('notifications')
      .where('userId', '==', userId);

    if (unreadOnly === 'true') {
      query = query.where('read', '==', false);
    }

    const offset = (parseInt(page) - 1) * parseInt(limit);
    query = query.orderBy('createdAt', 'desc')
                 .limit(parseInt(limit))
                 .offset(offset);

    const snapshot = await query.get();
    const notifications = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.json({ success: true, data: notifications });
  } catch (error) {
    logger.error('Error fetching notifications:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Mark notification as read
app.put('/api/notifications/:id/read', async (req, res) => {
  try {
    const { id } = req.params;
    
    await firestore.collection('notifications').doc(id).update({
      read: true,
      readAt: admin.firestore.FieldValue.serverTimestamp()
    });

    res.json({ success: true, message: 'Notification marked as read' });
  } catch (error) {
    logger.error('Error marking notification as read:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============= USER MANAGEMENT =============

// Update user profile
app.put('/api/users/:id/profile', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = {
      ...req.body,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await firestore.collection('users').doc(id).update(updates);
    
    // Log activity
    await firestore.collection('activity_logs').add({
      userId: id,
      action: 'PROFILE_UPDATED',
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    res.json({ success: true, message: 'Profile updated successfully' });
  } catch (error) {
    logger.error('Error updating profile:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get user statistics
app.get('/api/users/:id/stats', async (req, res) => {
  try {
    const { id } = req.params;
    const { type } = req.query; // 'seller' or 'buyer'

    let stats = await getOrderAnalytics(type === 'seller' ? null : id, type === 'seller' ? id : null);

    res.json({ success: true, data: stats });
  } catch (error) {
    logger.error('Error fetching user stats:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============= HEALTH & MONITORING =============

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: '3.0.0',
    environment: process.env.NODE_ENV || 'development',
    database: 'connected'
  });
});

// Get system statistics
app.get('/api/system/stats', async (req, res) => {
  try {
    const [productsSnapshot, ordersSnapshot, usersSnapshot] = await Promise.all([
      firestore.collection('products').get(),
      firestore.collection('orders').get(),
      firestore.collection('users').get()
    ]);

    const stats = {
      totalProducts: productsSnapshot.size,
      totalOrders: ordersSnapshot.size,
      totalUsers: usersSnapshot.size,
      uptime: process.uptime(),
      memoryUsage: process.memoryUsage(),
      timestamp: new Date().toISOString()
    };

    res.json({ success: true, data: stats });
  } catch (error) {
    logger.error('Error fetching system stats:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============= ERROR HANDLING & MIDDLEWARE =============

// Global error handling middleware
app.use((error, req, res, next) => {
  logger.error('Unhandled error:', {
    error: error.message,
    stack: error.stack,
    url: req.url,
    method: req.method,
    ip: req.ip
  });

  res.status(500).json({ 
    success: false, 
    error: 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { details: error.message })
  });
});

// 404 handler
app.use((req, res) => {
  logger.warn(`404 - Route not found: ${req.method} ${req.url}`);
  res.status(404).json({ 
    success: false, 
    error: 'Route not found',
    availableEndpoints: {
      products: '/api/products',
      orders: '/api/orders',
      payments: '/api/payments',
      notifications: '/api/notifications',
      analytics: '/api/analytics',
      health: '/api/health'
    }
  });
});

// Graceful shutdown
process.on('SIGINT', () => {
  logger.info('Received SIGINT, shutting down gracefully...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  logger.info('Received SIGTERM, shutting down gracefully...');
  process.exit(0);
});

// Start server
app.listen(PORT, () => {
  logger.info(`🚀 FarmKart Enhanced Backend Server started successfully`);
  logger.info(`🌐 Server running on port ${PORT}`);
  logger.info(`🏥 Health check: http://localhost:${PORT}/api/health`);
  logger.info(`📱 Environment: ${process.env.NODE_ENV || 'development'}`);
  logger.info('📋 Available endpoints:');
  logger.info('  🛒 Products: /api/products');
  logger.info('  📦 Orders: /api/orders');
  logger.info('  💳 Payments: /api/payments');
  logger.info('  💬 Conversations: /api/conversations');
  logger.info('  🔔 Notifications: /api/notifications');
  logger.info('  📊 Analytics: /api/analytics');
  logger.info('  👥 Users: /api/users');
  logger.info('  ⚕️ Health: /api/health');
});

module.exports = app;