const express = require('express');
const router = express.Router();
const videoController = require('../controllers/videoController');

// GET /api/videos/trending
router.get('/trending', videoController.getTrendingVideos);

// GET /api/videos/category/:category
router.get('/category/:category', videoController.getVideosByCategory);

// POST /api/videos/:videoId/view
router.post('/view/:videoId', videoController.logVideoView);

module.exports = router;
