# 🎯 **Quick Setup & Testing Guide**

## 🚀 **Start the Enhanced Backend**

```bash
cd farmkart-backend
npm install
npm start
```

**Expected Output:**
```
FarmKart Enhanced Backend Server is running on port 3000
Health check: http://localhost:3000/api/health
Available endpoints:
  Products: /api/products
  Orders: /api/orders
  Conversations: /api/conversations
  Search: /api/search/products
  User Stats: /api/users/:id/stats
```

## ✅ **Test Backend APIs**

```bash
# In project root directory
node test_backend.js
```

**Expected Output:**
```
🚀 Testing FarmKart Enhanced Backend APIs...

1. Testing Health Check...
✅ Health Check: healthy

2. Testing Product Management...
✅ Product Created: true
✅ Products Retrieved: 1 products

3. Testing Order Management...
✅ Order Created: true
✅ Order Status Updated: true

4. Testing Search...
✅ Search Results: 1 products found

5. Testing User Statistics...
✅ Seller Stats: { totalOrders: 1, ... }
✅ Buyer Stats: { totalOrders: 1, ... }

6. Testing Conversation Management...
✅ Conversation endpoints ready

🎉 All Backend API Tests Completed Successfully!
```

## 📱 **Run Flutter App**

```bash
flutter pub get
flutter run
```

## 🔍 **Test Key Features**

### **1. Login & Role-Based Navigation**
- ✅ Sign up as Farmer or Addat
- ✅ Role-based dashboard access
- ✅ Seller vs Buyer product views

### **2. Product Management**
- ✅ Add products (Sellers only)
- ✅ View all products (Buyers see others' products)
- ✅ Product filtering and search

### **3. Chat System**
- ✅ Contact seller from product page
- ✅ Real-time conversations
- ✅ Unread message badges
- ✅ Chat access from app bar

### **4. Order Management**
- ✅ Place orders from product details
- ✅ Order tracking for buyers
- ✅ Order management for sellers
- ✅ Status progression tracking

### **5. Enhanced Navigation**
- ✅ Chat icon with unread count
- ✅ Orders quick access
- ✅ Role-based interfaces

## 🐛 **Troubleshooting**

### **Backend Not Starting**
```bash
cd farmkart-backend
npm install
# If Firebase issues, ensure project is properly configured
```

### **Flutter Build Issues**
```bash
flutter clean
flutter pub get
flutter run
```

### **Chat/Orders Not Working**
- Ensure Firestore is properly configured
- Check Firebase authentication
- Verify Firestore security rules are updated

## 📚 **API Documentation**

### **Products**
- `GET /api/products` - List products with filters
- `POST /api/products` - Create new product
- `PUT /api/products/:id` - Update product
- `DELETE /api/products/:id` - Delete product

### **Orders**
- `GET /api/orders` - List orders with filters
- `POST /api/orders` - Create new order
- `PUT /api/orders/:id/status` - Update order status

### **Search**
- `GET /api/search/products?q=query` - Search products

### **Statistics**
- `GET /api/users/:id/stats?type=seller` - Seller stats
- `GET /api/users/:id/stats?type=buyer` - Buyer stats

## 🎉 **All Features Working!**

The FarmKarts application now includes:
- ✅ Complete marketplace functionality
- ✅ Real-time chat system
- ✅ Full order management
- ✅ Role-based access control
- ✅ Enhanced user experience
- ✅ Robust backend API
- ✅ Security & error handling