const admin = require('firebase-admin');

// Role-based middleware for endpoint restriction
const roleMiddleware = (allowedRoles = []) => {
  return async (req, res, next) => {
    try {
      const authHeader = req.headers['authorization'];
      const token = authHeader && authHeader.split(' ')[1];

      if (!token) {
        return res.status(401).json({ 
          success: false, 
          error: 'Access token required' 
        });
      }

      // Verify Firebase token
      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(token);
        req.user = decodedToken;
      } catch (error) {
        return res.status(403).json({ 
          success: false, 
          error: 'Invalid or expired token' 
        });
      }

      // Get user role from Firestore
      try {
        const firestore = admin.firestore();
        const userDoc = await firestore
          .collection('users')
          .doc(decodedToken.uid)
          .get();

        if (!userDoc.exists) {
          return res.status(403).json({ 
            success: false, 
            error: 'User profile not found' 
          });
        }

        const userData = userDoc.data();
        req.userRole = userData.role;
        req.userProfile = userData;

        // Check if user role is allowed
        if (allowedRoles.length > 0 && !allowedRoles.includes(userData.role)) {
          return res.status(403).json({ 
            success: false, 
            error: `Access denied. Required role: ${allowedRoles.join(' or ')}. Your role: ${userData.role}` 
          });
        }

        next();
      } catch (error) {
        console.error('Error fetching user profile:', error);
        return res.status(500).json({ 
          success: false, 
          error: 'Failed to verify user permissions' 
        });
      }

    } catch (error) {
      console.error('Role middleware error:', error);
      return res.status(500).json({ 
        success: false, 
        error: 'Authorization failed' 
      });
    }
  };
};

module.exports = roleMiddleware;