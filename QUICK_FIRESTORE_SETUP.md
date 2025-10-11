# 🔥 Quick Firestore Setup for FarmKarts

## Your Project Details
- **Project ID**: `farmkart-9f4f3`
- **Region**: `asia-south1` (detected from your MongoDB string)
- **Domain**: `farmkart-9f4f3.firebaseapp.com`

## ⚡ 5-Minute Setup

### Step 1: Enable Firestore
1. **Open**: https://console.firebase.google.com/project/farmkart-9f4f3/firestore
2. **Click**: "Create database"
3. **Select**: "Start in test mode"
4. **Location**: `asia-south1` 
5. **Click**: "Done"

### Step 2: Set Rules
1. **Go to Rules tab**
2. **Replace content**:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```
3. **Click**: "Publish"

### Step 3: Enable Storage
1. **Open**: https://console.firebase.google.com/project/farmkart-9f4f3/storage
2. **Click**: "Get started"
3. **Select**: "Start in test mode"
4. **Location**: `asia-south1`
5. **Click**: "Done"

## ✅ Done!
Your app will now work perfectly with Firestore instead of needing MongoDB.

**Restart your app and try registering a user!** 🚀