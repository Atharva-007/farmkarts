# Firebase Firestore Setup Guide for FarmKarts

## Step 1: Enable Firestore in Firebase Console

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: `farmkart-9f4f3` (based on your firebase_options.dart)
3. **Navigate to Firestore Database**:
   - Click on "Firestore Database" in the left sidebar
   - Click "Create database"

## Step 2: Choose Firestore Mode

You'll see two options:

### Option A: Production Mode (Recommended for Learning)
- Click "Start in production mode"
- Click "Next"
- Choose your location (select closest to your users):
  - `us-central1` (Iowa) - Good for US/Americas
  - `europe-west1` (Belgium) - Good for Europe
  - `asia-southeast1` (Singapore) - Good for Asia
- Click "Done"

### Option B: Test Mode (Easier for Development)
- Click "Start in test mode"
- Click "Next" 
- Choose location and click "Done"

## Step 3: Set Up Security Rules

After database creation, you need to set security rules:

1. **Go to "Rules" tab** in Firestore
2. **Replace the default rules** with this:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to all authenticated users
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

3. **Click "Publish"**

## Step 4: Enable Firebase Storage

1. **Navigate to Storage** in Firebase Console
2. **Click "Get started"**
3. **Choose "Start in production mode"** or "Start in test mode"
4. **Select same location** as Firestore
5. **Set Storage Rules**:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Step 5: Verify Setup

1. **Check Authentication** is enabled:
   - Go to "Authentication" → "Sign-in method"
   - Enable "Email/Password" if not already enabled

2. **Test Connection**:
   - Your app should now connect to Firestore
   - Check console for successful connection messages

## Database Structure That Will Be Created

Your app will automatically create this structure:

```
farmkart-9f4f3 (Firestore Database)
└── users (Collection)
    └── {userId} (Document)
        ├── uid: string
        ├── email: string
        ├── role: "farmer" | "addat"
        ├── fullName: string
        ├── mobileNo: string
        ├── createdAt: timestamp
        ├── updatedAt: timestamp
        ├── acresLand: number (for farmers)
        ├── dukanName: string (for addat)
        ├── licenseImageUrl: string (for addat)
        └── isLicenseVerified: boolean (for addat)
```

## Quick Setup Commands

If you have Firebase CLI installed:

```bash
# Login to Firebase
firebase login

# Initialize Firestore (run in your project directory)
firebase init firestore

# Deploy security rules
firebase deploy --only firestore:rules
```

## Troubleshooting

**If you get "Permission denied" errors:**
- Make sure Security Rules are published
- Verify user is authenticated before accessing Firestore

**If you get "Quota exceeded" errors:**
- Check your Firestore usage in Console
- You might need to upgrade to paid plan for heavy usage

**If connection still fails:**
- Check your internet connection
- Verify Firebase project configuration
- Make sure you're using the correct project ID

## Next Steps After Setup

1. Run your app again
2. Try registering a new user
3. Check Firestore Console to see the user document created
4. Test both Farmer and Addat registration flows

The app will automatically create the database structure when users register!