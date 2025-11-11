const express = require('express');
const ProductController = require('../controllers/productController');
const roleMiddleware = require('../middleware/roleMiddleware');

const router = express.Router();

// User-specific routes

// GET /api/users/:userId/selling-history - Get user's selling history
router.get('/:userId/selling-history', 
  roleMiddleware(['addat']), 
  ProductController.getSellingHistoryByUser
);

// GET /api/users/:userId/products - Get products by user (alias for selling history)
router.get('/:userId/products', 
  roleMiddleware(['addat']), 
  async (req, res) => {
    // Redirect to get products with sellerId filter
    try {
      req.query.sellerId = req.params.userId;
      await ProductController.getProducts(req, res);
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message || 'Failed to fetch user products'
      });
    }
  }
);

module.exports = router;