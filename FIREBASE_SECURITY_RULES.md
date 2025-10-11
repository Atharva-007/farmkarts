// Firestore Security Rules for FarmKarts
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection rules
    match /users/{userId} {
      // Allow read and write for authenticated users on their own documents
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow read access to all authenticated users (for public profile info)
      allow read: if request.auth != null;
    }
    
    // Products collection rules (for future use)
    match /products/{productId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == resource.data.sellerId;
    }
    
    // Orders collection rules (for future use)
    match /orders/{orderId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.buyerId || request.auth.uid == resource.data.sellerId);
    }
  }
}

// Firebase Storage Security Rules for FarmKarts
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // License images for Addat users
    match /licenses/{userId}.jpg {
      // Only allow authenticated users to upload their own license
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Product images (for future use)
    match /products/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Profile images (for future use)
    match /profiles/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}