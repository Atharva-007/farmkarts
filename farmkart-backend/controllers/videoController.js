const admin = require('firebase-admin');

/**
 * Get trending agriculture videos
 * In a real production system, this would fetch from YouTube API v3 
 * or a curated list in a database with ranking algorithms.
 */
exports.getTrendingVideos = async (req, res) => {
  try {
    const db = admin.firestore();
    const videosRef = db.collection('trending_videos');
    
    // Sort by viewCount or publishedDate
    const snapshot = await videosRef.orderBy('viewCount', 'desc').limit(10).get();
    
    if (snapshot.empty) {
      // Return mock data if collection is empty
      return res.status(200).json({
        success: true,
        data: getMockVideos(),
        source: 'mock'
      });
    }

    const videos = [];
    snapshot.forEach(doc => {
      videos.push({ id: doc.id, ...doc.data() });
    });

    res.status(200).json({
      success: true,
      count: videos.length,
      data: videos,
      source: 'firestore'
    });
  } catch (error) {
    console.error('Error fetching trending videos:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch trending videos',
      error: error.message
    });
  }
};

/**
 * Get videos by category
 */
exports.getVideosByCategory = async (req, res) => {
  try {
    const { category } = req.params;
    const db = admin.firestore();
    const snapshot = await db.collection('trending_videos')
      .where('category', '==', category)
      .get();

    const videos = [];
    snapshot.forEach(doc => {
      videos.push({ id: doc.id, ...doc.data() });
    });

    res.status(200).json({
      success: true,
      count: videos.length,
      data: videos
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch videos by category',
      error: error.message
    });
  }
};

/**
 * Log video view (for ranking algorithm)
 */
exports.logVideoView = async (req, res) => {
  try {
    const { videoId } = req.params;
    const db = admin.firestore();
    
    await db.collection('trending_videos').doc(videoId).update({
      viewCount: admin.firestore.FieldValue.increment(1)
    });

    res.status(200).json({
      success: true,
      message: 'View logged successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to log view',
      error: error.message
    });
  }
};

// Helper for initial data seed/fallback
function getMockVideos() {
  return [
    {
      youtubeId: 'q7Spx_ZIn_I',
      title: 'Modern Organic Farming Techniques 2024',
      thumbnail: 'https://img.youtube.com/vi/q7Spx_ZIn_I/maxresdefault.jpg',
      duration: '12:45',
      category: 'Education',
      publishedDate: new Date().toISOString(),
      viewCount: 15000,
    },
    {
      youtubeId: 'B_XAnZ_vbeM',
      title: 'How to increase Wheat Yield by 30%',
      thumbnail: 'https://img.youtube.com/vi/B_XAnZ_vbeM/maxresdefault.jpg',
      duration: '08:20',
      category: 'Farming Guide',
      publishedDate: new Date().toISOString(),
      viewCount: 25000,
    },
    {
      youtubeId: '6X_ZIn_Iq7S',
      title: 'New Smart Irrigation Systems',
      thumbnail: 'https://img.youtube.com/vi/6X_ZIn_Iq7S/maxresdefault.jpg',
      duration: '15:10',
      category: 'Technology',
      publishedDate: new Date().toISOString(),
      viewCount: 18000,
    }
  ];
}
