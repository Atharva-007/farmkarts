import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'add_sell_item_page.dart';
import 'features/marketplace/marketplace_home.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  _SellPageState createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://farmkart-9f4f3-default-rtdb.firebaseio.com/',
  ).ref().child('itemsForSale');

  final List<Map<String, dynamic>> _itemsForSale = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _listenToDatabase();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _listenToDatabase() {
    _dbRef.orderByChild('timestamp').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final List<Map<String, dynamic>> loadedItems = [];
        data.forEach((key, value) {
          // Only show items from current user
          final user = FirebaseAuth.instance.currentUser;
          if (user != null && value['sellerId'] == user.uid) {
            loadedItems.add({
              'key': key,
              'productName': value['productName'],
              'description': value['description'],
              'price': value['price'],
              'category': value['category'] ?? 'Other',
              'unit': value['unit'] ?? 'kg',
              'quantity': value['quantity'] ?? 0,
              'sellerId': value['sellerId'],
              'sellerName': value['sellerName'],
              'timestamp': value['timestamp'],
              'status': value['status'] ?? 'active',
              'views': value['views'] ?? 0,
              'inquiries': value['inquiries'] ?? 0,
            });
          }
        });

        loadedItems.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

        setState(() {
          _itemsForSale
            ..clear()
            ..addAll(loadedItems);
          _isLoading = false;
        });
      } else {
        setState(() {
          _itemsForSale.clear();
          _isLoading = false;
        });
      }
    });
  }

  void _addItemToDatabase(String productName, String description, String price, 
                         String category, String unit, int quantity) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to sell products')),
      );
      return;
    }

    final newItem = {
      'productName': productName,
      'description': description,
      'price': price,
      'category': category,
      'unit': unit,
      'quantity': quantity,
      'sellerId': user.uid,
      'sellerName': user.displayName ?? user.email?.split('@')[0] ?? 'Seller',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'status': 'active',
      'views': 0,
      'inquiries': 0,
    };

    _dbRef.push().set(newItem).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product listed successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to list product: $error'),
          backgroundColor: AppTheme.error,
        ),
      );
    });
  }

  void _navigateToAddSellItemPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSellItemPage(
          onAddItem: _addItemToDatabase,
        ),
      ),
    );
  }

  void _editItem(Map<String, dynamic> item) {
    // Navigate to edit page (can reuse AddSellItemPage with edit mode)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit feature coming soon!')),
    );
  }

  void _deleteItem(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${item['productName']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _dbRef.child(item['key']).remove().then((_) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product deleted successfully'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }).catchError((error) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete: $error'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              });
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _toggleStatus(Map<String, dynamic> item) {
    final newStatus = item['status'] == 'active' ? 'inactive' : 'active';
    _dbRef.child(item['key']).update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Sell Products'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MarketplaceHome(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showAnalytics,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: user == null ? _buildLoginPrompt() : _buildSellerDashboard(),
      ),
      floatingActionButton: user != null ? FloatingActionButton.extended(
        onPressed: _navigateToAddSellItemPage,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ) : null,
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login,
              size: 80,
              color: AppTheme.textGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'Login Required',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please login to start selling your products',
              style: TextStyle(color: AppTheme.textGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerDashboard() {
    return Column(
      children: [
        _buildSellerStats(),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                )
              : _itemsForSale.isEmpty
                  ? _buildEmptyState()
                  : _buildProductsList(),
        ),
      ],
    );
  }

  Widget _buildSellerStats() {
    final activeItems = _itemsForSale.where((item) => item['status'] == 'active').length;
    final totalViews = _itemsForSale.fold<int>(0, (sum, item) => sum + (item['views'] as int));
    final totalInquiries = _itemsForSale.fold<int>(0, (sum, item) => sum + (item['inquiries'] as int));

    return Container(
      padding: AppConstants.defaultPadding,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seller Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Active Products',
                  activeItems.toString(),
                  Icons.inventory,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Views',
                  totalViews.toString(),
                  Icons.visibility,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Inquiries',
                  totalInquiries.toString(),
                  Icons.message,
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_box_outlined,
              size: 80,
              color: AppTheme.textGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Products Listed',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start selling by adding your first product',
              style: TextStyle(color: AppTheme.textGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddSellItemPage,
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh will be handled by the database listener
        await Future.delayed(const Duration(seconds: 1));
      },
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: AppConstants.defaultPadding,
        itemCount: _itemsForSale.length,
        itemBuilder: (context, index) {
          final item = _itemsForSale[index];
          return _buildProductCard(item);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    final isActive = item['status'] == 'active';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: isActive ? AppTheme.success : AppTheme.textGrey,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: AppConstants.defaultPadding,
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.agriculture,
                  size: 30,
                  color: AppTheme.primaryGreen,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item['productName'] ?? 'No Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.success : AppTheme.textGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    item['description'] ?? 'No Description',
                    style: TextStyle(color: AppTheme.textGrey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₹${item['price'] ?? '0'} / ${item['unit'] ?? 'kg'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Qty: ${item['quantity'] ?? 0} ${item['unit'] ?? 'kg'}',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 16, color: AppTheme.textGrey),
                      const SizedBox(width: 4),
                      Text('${item['views']} views', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                      const SizedBox(width: 16),
                      Icon(Icons.message, size: 16, color: AppTheme.textGrey),
                      const SizedBox(width: 4),
                      Text('${item['inquiries']} inquiries', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        const Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Row(
                      children: [
                        Icon(
                          isActive ? Icons.pause : Icons.play_arrow,
                          color: isActive ? AppTheme.warning : AppTheme.success,
                        ),
                        const SizedBox(width: 8),
                        Text(isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppTheme.error),
                        const SizedBox(width: 8),
                        const Text('Delete'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editItem(item);
                      break;
                    case 'toggle_status':
                      _toggleStatus(item);
                      break;
                    case 'delete':
                      _deleteItem(item);
                      break;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnalytics() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.borderGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sales Analytics',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Detailed analytics coming soon!'),
            const SizedBox(height: 20),
            _buildAnalyticsCard('Total Revenue', '₹12,500', Icons.account_balance_wallet, AppTheme.success),
            const SizedBox(height: 12),
            _buildAnalyticsCard('Total Orders', '25', Icons.shopping_bag, AppTheme.accentOrange),
            const SizedBox(height: 12),
            _buildAnalyticsCard('Average Rating', '4.6 ⭐', Icons.star, AppTheme.sunshine),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: AppConstants.defaultPadding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
      }
    });
  }

  void _addItemToDatabase(String productName, String description, String price) {
    final newItem = {
      'productName': productName,
      'description': description,
      'price': price,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    _dbRef.push().set(newItem);
  }

  void _navigateToAddSellItemPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSellItemPage(
          onAddItem: _addItemToDatabase,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'No items added yet!',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell Items'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Items for Sale',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _itemsForSale.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                itemCount: _itemsForSale.length,
                itemBuilder: (context, index) {
                  final item = _itemsForSale[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        item['productName'] ?? 'No Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            item['description'] ?? 'No Description',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Price: ₹${item['price'] ?? '0.00'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddSellItemPage,
        tooltip: 'Add New Item',
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
