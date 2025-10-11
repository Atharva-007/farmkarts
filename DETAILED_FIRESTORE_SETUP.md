# 🚀 Complete Firestore Setup Guide for FarmKarts

## 📋 **What You'll Achieve**
After following this guide, your FarmKarts app will:
- ✅ Register farmers and vendors successfully
- ✅ Store user profiles in Firestore
- ✅ Upload license images to Firebase Storage
- ✅ Handle login/logout perfectly
- ✅ Show role-based dashboards

---

## 🔥 **STEP 1: Enable Firestore Database**

### 1.1 Open Firebase Console
1. **Go to**: https://console.firebase.google.com/
2. **Login** with your Google account
3. **Click on your project**: `farmkart-9f4f3`

### 1.2 Navigate to Firestore
1. **Look at the left sidebar**
2. **Click on "Firestore Database"**
3. **You'll see a page that says "Cloud Firestore" with a "Create database" button**

### 1.3 Create Database
1. **Click "Create database"**
2. **You'll see two options:**
   - **"Start in production mode"** (more secure but complex)
   - **"Start in test mode"** (easier for development) ← **Choose this one**
3. **Click "Start in test mode"**
4. **Click "Next"**

### 1.4 Choose Location
1. **Select location**: `asia-south1 (Mumbai)` (closest to you)
2. **Click "Done"**
3. **Wait 1-2 minutes** for database creation
4. **You should see**: "Your Cloud Firestore database has been created"

---

## 🛡️ **STEP 2: Configure Security Rules**

### 2.1 Access Rules
1. **In Firestore Database page**
2. **Click on "Rules" tab** (next to "Data" tab)
3. **You'll see default rules that look like this:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### 2.2 Update Rules
1. **Select all the text** in the rules editor
2. **Delete it completely**
3. **Copy and paste this code:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read other user profiles (for public info)
    match /users/{userId} {
      allow read: if request.auth != null;
    }
    
    // Future collections (products, orders, etc.)
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

4. **Click "Publish"**
5. **Confirm by clicking "Publish" again**

---

## 📁 **STEP 3: Enable Firebase Storage**

### 3.1 Navigate to Storage
1. **In left sidebar, click "Storage"**
2. **You'll see "Get started" button**

### 3.2 Enable Storage
1. **Click "Get started"**
2. **You'll see security rules dialog**
3. **Click "Start in test mode"** (we'll secure it later)
4. **Click "Next"**

### 3.3 Choose Location
1. **Select same location**: `asia-south1 (Mumbai)`
2. **Click "Done"**
3. **Wait for storage bucket creation**

### 3.4 Configure Storage Rules
1. **Click on "Rules" tab in Storage**
2. **Replace the default rules with:**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // License images for vendors
    match /licenses/{userId}.jpg {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Profile images (future feature)
    match /profiles/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Product images (future feature)
    match /products/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

3. **Click "Publish"**

---

## 🔐 **STEP 4: Verify Authentication Setup**

### 4.1 Check Authentication
1. **Click "Authentication" in left sidebar**
2. **Click "Sign-in method" tab**
3. **Verify "Email/Password" is enabled**
4. **If not enabled:**
   - Click on "Email/Password"
   - Toggle "Enable"
   - Click "Save"

---

## ✅ **STEP 5: Test Your Setup**

### 5.1 Check Database Status
1. **Go back to "Firestore Database"**
2. **Click "Data" tab**
3. **You should see**: "No documents yet. Create your first document or start your app."

### 5.2 Check Storage Status
1. **Go to "Storage"**
2. **You should see**: Empty storage bucket with your project name

---

## 🚀 **STEP 6: Test Your App**

### 6.1 Restart Your App
1. **Stop your Flutter app** (Ctrl+C in terminal)
2. **Run again**: `flutter run -d chrome` (for web) or `flutter run` (for mobile)

### 6.2 Test Registration
1. **Click "Create Account"**
2. **Select "Farmer"**:
   - Full Name: `Test Farmer`
   - Mobile: `1234567890`
   - Email: `farmer@test.com`
   - Acres: `5.5`
   - Password: `test123456`
3. **Click "Create Account"**

### 6.3 Verify Data Creation
1. **Go back to Firebase Console**
2. **Firestore Database → Data tab**
3. **You should see**:
   - Collection: `users`
   - Document: `{userId}`
   - Fields: `uid`, `email`, `fullName`, `role`, `acresLand`, etc.

### 6.4 Test Vendor Registration
1. **Create another account**
2. **Select "Addat/Vendor"**:
   - Fill details + shop name
   - Upload a test image
   - Register

### 6.5 Verify Storage
1. **Firebase Console → Storage**
2. **You should see**: `licenses/{userId}.jpg` file

---

## 🔧 **Troubleshooting**

### Problem: "Permission denied"
**Solution**: 
- Check security rules are published
- Ensure user is logged in before accessing data

### Problem: "Network error"
**Solution**:
- Check internet connection
- Try different browser
- Clear browser cache

### Problem: "Project not found"
**Solution**:
- Verify you're in correct Firebase project
- Check project ID matches your config

### Problem: App still shows offline errors
**Solution**:
- Hard refresh browser (Ctrl+Shift+R)
- Restart Flutter app completely
- Check Firebase project region matches

---

## 📊 **Expected Database Structure**

After successful setup, your Firestore will look like:

```
farmkart-9f4f3 (Database)
└── users (Collection)
    ├── sYptvV6FgxVT8RdeGhHOX4OSiGR2 (Document - Farmer)
    │   ├── uid: "sYptvV6FgxVT8RdeGhHOX4OSiGR2"
    │   ├── email: "farmer@test.com"
    │   ├── fullName: "Test Farmer"
    │   ├── role: "farmer"
    │   ├── mobileNo: "1234567890"
    │   ├── acresLand: 5.5
    │   ├── createdAt: 1728640511019
    │   └── updatedAt: 1728640511019
    └── xyz123abc456 (Document - Addat)
        ├── uid: "xyz123abc456"
        ├── email: "vendor@test.com"
        ├── fullName: "Test Vendor"
        ├── role: "addat"
        ├── mobileNo: "0987654321"
        ├── dukanName: "Test Shop"
        ├── licenseImageUrl: "https://firebasestorage..."
        ├── isLicenseVerified: false
        ├── createdAt: 1728640611019
        └── updatedAt: 1728640611019
```

---

## 🎉 **Success Indicators**

You'll know setup is successful when:

1. ✅ **App loads without errors**
2. ✅ **Registration creates user in Firestore**
3. ✅ **Login works and shows dashboard**
4. ✅ **Role-based features appear correctly**
5. ✅ **License images upload to Storage**
6. ✅ **No more "offline" error messages**

---

## 📞 **Need Help?**

If you get stuck:
1. **Check each step carefully**
2. **Ensure rules are published**
3. **Verify project ID matches**
4. **Try different browser**
5. **Restart Flutter app**

**Your app will be fully functional after this setup!** 🚀