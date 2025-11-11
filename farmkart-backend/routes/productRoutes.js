const express = require('express');
const multer = require('multer');
const ProductController = require('../controllers/productController');
const roleMiddleware = require('../middleware/roleMiddleware');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
    files: 5 // Maximum 5 files
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only JPEG, PNG and GIF are allowed.'), false);
    }
  }
});

// Product Routes

// POST /api/products - Create new product (only addats/vendors)
router.post('/', 
  roleMiddleware(['addat']), 
  upload.array('images', 5), 
  ProductController.createProduct
);

// GET /api/products - Get all products with filtering
router.get('/', ProductController.getProducts);

// GET /api/products/:id - Get product by ID
router.get('/:id', ProductController.getProductById);

// PUT /api/products/:id - Update product (only owner)
router.put('/:id', 
  roleMiddleware(['addat']), 
  upload.array('images', 5), 
  ProductController.updateProduct
);

// DELETE /api/products/:id - Delete product (only owner)
router.delete('/:id', 
  roleMiddleware(['addat']), 
  ProductController.deleteProduct
);

module.exports = router;