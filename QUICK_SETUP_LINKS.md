# 🔗 Direct Links for FarmKarts Firebase Setup

## 🚀 **One-Click Setup Links**

### **Your Firebase Project**
- **Main Console**: https://console.firebase.google.com/project/farmkart-9f4f3
- **Firestore Database**: https://console.firebase.google.com/project/farmkart-9f4f3/firestore
- **Storage**: https://console.firebase.google.com/project/farmkart-9f4f3/storage
- **Authentication**: https://console.firebase.google.com/project/farmkart-9f4f3/authentication

---

## 📋 **Quick Copy-Paste Rules**

### **Firestore Security Rules** (Copy & Paste)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null;
    }
    match /products/{productId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    match /orders/{orderId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### **Storage Security Rules** (Copy & Paste)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /licenses/{userId}.jpg {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /profiles/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /products/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

---

## ⚡ **Super Quick Setup (2 minutes)**

1. **Click**: https://console.firebase.google.com/project/farmkart-9f4f3/firestore
2. **If no database**: Click "Create database" → "Test mode" → "asia-south1" → "Done"
3. **Rules tab**: Paste Firestore rules above → "Publish"
4. **Click**: https://console.firebase.google.com/project/farmkart-9f4f3/storage  
5. **If no storage**: Click "Get started" → "Test mode" → "asia-south1" → "Done"
6. **Rules tab**: Paste Storage rules above → "Publish"

**Done! Restart your app and test!** 🎉

---

## 🧪 **Test Data for Registration**

### **Farmer Test Data**
```
Full Name: John Farmer
Mobile: 9876543210
Email: john.farmer@test.com
Password: farmer123
Acres: 10.5
```

### **Addat Test Data**
```
Full Name: Shop Owner
Mobile: 8765432109
Email: shop.owner@test.com
Password: vendor123
Shop Name: Fresh Produce Store
License: Upload any image file
```

---

## 🔍 **Verification Links**

After setup, check these to confirm success:

- **Firestore Data**: https://console.firebase.google.com/project/farmkart-9f4f3/firestore/data
- **Storage Files**: https://console.firebase.google.com/project/farmkart-9f4f3/storage/farmkart-9f4f3.firebasestorage.app/files
- **Auth Users**: https://console.firebase.google.com/project/farmkart-9f4f3/authentication/users

**You should see your registered users and uploaded files there!** ✅