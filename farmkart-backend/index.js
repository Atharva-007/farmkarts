const express = require('express');
const bodyParser = require('body-parser');
const admin = require('firebase-admin');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// CORS middleware
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
  } else {
    next();
  }
});

// Initialize Firebase Admin SDK
// Note: You need to add your service account key file
try {
  // For development, you can use the Firebase project credentials
  // In production, use service account key
  if (!admin.apps.length) {
    admin.initializeApp({
      // You'll need to add your service account key here
      // credential: admin.credential.cert(require('./path/to/serviceAccountKey.json')),
      databaseURL: 'https://farmkart-9f4f3-default-rtdb.firebaseio.com/',
    });
  }
} catch (error) {
  console.log('Firebase admin initialization error:', error.message);
}

// Get a reference to the Firebase Realtime Database
const db = admin.database();

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'FarmKart Backend API is running!' });
});

// Get all items for sale
app.get('/api/items', async (req, res) => {
  try {
    const ref = db.ref('itemsForSale');
    const snapshot = await ref.once('value');
    const data = snapshot.val();
    res.json({ success: true, data: data || {} });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Add new item for sale
app.post('/api/items', async (req, res) => {
  try {
    const { productName, description, price, farmerName, location } = req.body;
    
    if (!productName || !price) {
      return res.status(400).json({ success: false, error: 'Product name and price are required' });
    }

    const ref = db.ref('itemsForSale');
    const newItemRef = ref.push();
    
    const itemData = {
      productName,
      description: description || '',
      price,
      farmerName: farmerName || '',
      location: location || '',
      createdAt: admin.database.ServerValue.TIMESTAMP,
      id: newItemRef.key
    };

    await newItemRef.set(itemData);
    
    res.json({ success: true, data: itemData });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Update item
app.put('/api/items/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    const ref = db.ref(`itemsForSale/${id}`);
    await ref.update(updates);
    
    res.json({ success: true, message: 'Item updated successfully' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Delete item
app.delete('/api/items/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const ref = db.ref(`itemsForSale/${id}`);
    await ref.remove();
    
    res.json({ success: true, message: 'Item deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime() 
  });
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Error:', error);
  res.status(500).json({ success: false, error: 'Internal server error' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, error: 'Route not found' });
});

// Start server
app.listen(PORT, () => {
  console.log(`FarmKart Backend Server is running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/api/health`);
});

module.exports = app;