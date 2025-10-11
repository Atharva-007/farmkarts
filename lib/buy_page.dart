import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'theme/app_theme.dart';
import 'features/marketplace/marketplace_home.dart';

class BuyPage extends StatefulWidget {
  const BuyPage({super.key});

  @override
  State<BuyPage> createState() => _BuyPageState();
}

class _BuyPageState extends State<BuyPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final DatabaseReference _productsRef = FirebaseDatabase.instance.ref('marketplace/products');
  
  // Enhanced sample products with more details
  final List<Map<String, dynamic>> products = [
    {
      'name': 'Fresh Tomatoes',
      'description': 'High-quality red tomatoes, perfect for cooking and salads. Grown organically without pesticides.',
      'price': '40',
      'unit': 'kg',
      'category': 'Vegetables',
      'location': 'Punjab, India',
      'seller': 'Rajesh Kumar',
      'rating': 4.8,
      'isOrganic': true,
      'image': 'tomato',
      'stock': 50,
    },
    {
      'name': 'Organic Wheat',
      'description': 'Premium quality wheat grains, ideal for making flour and bread.',
      'price': '30',
      'unit': 'kg',
      'category': 'Grains',
      'location': 'Haryana, India',
      'seller': 'Mukesh Singh',
      'rating': 4.6,
      'isOrganic': true,
      'image': 'wheat',
      'stock': 200,
    },
    {
      'name': 'Basmati Rice',
      'description': 'Aromatic long-grain basmati rice, perfect for biryani and pulao.',
      'price': '60',
      'unit': 'kg',
      'category': 'Grains',
      'location': 'Uttar Pradesh, India',
      'seller': 'Ramesh Patel',
      'rating': 4.9,
      'isOrganic': false,
      'image': 'rice',
      'stock': 150,
    },
    {
      'name': 'Fresh Potatoes',
      'description': 'Farm-fresh potatoes, ideal for cooking various dishes.',
      'price': '25',
      'unit': 'kg',
      'category': 'Vegetables',
      'location': 'West Bengal, India',
      'seller': 'Suresh Mondal',
      'rating': 4.5,
      'isOrganic': false,
      'image': 'potato',
      'stock': 100,
    },
    {
      'name': 'Green Capsicum',
      'description': 'Fresh bell peppers, rich in vitamins and perfect for cooking.',
      'price': '50',
      'unit': 'kg',
      'category': 'Vegetables',
      'location': 'Maharashtra, India',
      'seller': 'Anil Deshmukh',
      'rating': 4.7,
      'isOrganic': true,
      'image': 'capsicum',
      'stock': 30,
    },
    {
      'name': 'Red Onions',
      'description': 'Quality red onions with strong flavor, essential for Indian cooking.',
      'price': '35',
      'unit': 'kg',
      'category': 'Vegetables',
      'location': 'Karnataka, India',
      'seller': 'Venkatesh Rao',
      'rating': 4.4,
      'isOrganic': false,
      'image': 'onion',
      'stock': 80,
    },
  ];

  String _selectedCategory = 'All';
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredProducts = [];

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
    
    _filteredProducts = products;
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = products.where((product) {
        final matchesCategory = _selectedCategory == 'All' || 
                               product['category'] == _selectedCategory;
        final matchesSearch = _searchQuery.isEmpty ||
                            product['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            product['description'].toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Buy Products'),
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
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cart feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildSearchAndFilter(),
            _buildCategoryTabs(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Simulate refresh
                  await Future.delayed(const Duration(seconds: 1));
                },
                color: AppTheme.primaryGreen,
                child: _filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : _buildProductGrid(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: AppConstants.defaultPadding,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              onChanged: (value) {
                _searchQuery = value;
                _filterProducts();
              },
              decoration: const InputDecoration(
                hintText: 'Search products, sellers, or locations...',
                border: InputBorder.none,
                icon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.filter_list, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_filteredProducts.length} products found',
                style: const TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showSortOptions,
                icon: const Icon(Icons.sort, color: Colors.white),
                label: const Text('Sort', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = ['All', 'Vegetables', 'Fruits', 'Grains', 'Seeds'];
    
    return Container(
      height: 50,
      color: AppTheme.surfaceWhite,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;
          
          return Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = category;
                });
                _filterProducts();
              },
              selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryGreen,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      padding: AppConstants.defaultPadding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: () => _showProductDetails(product),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppConstants.borderRadius),
                      ),
                    ),
                    child: Icon(
                      Icons.agriculture,
                      size: 60,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  if (product['isOrganic'])
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Organic',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.favorite_border),
                      color: AppTheme.textGrey,
                      onPressed: () => _toggleFavorite(product),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'],
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: AppTheme.textGrey,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                product['location'],
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textGrey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ...List.generate(5, (index) {
                              return Icon(
                                index < product['rating'].floor()
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 12,
                                color: AppTheme.sunshine,
                              );
                            }),
                            const SizedBox(width: 4),
                            Text(
                              product['rating'].toString(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${product['price']}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'per ${product['unit']}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.shopping_cart_outlined),
                          color: AppTheme.primaryGreen,
                          onPressed: () => _addToCart(product),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppTheme.textGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or category filter',
            style: TextStyle(color: AppTheme.textGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showProductDetails(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
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
                product['name'],
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '₹${product['price']}/${product['unit']}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (product['isOrganic'])
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Organic',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product['description'],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.person, size: 20, color: AppTheme.textGrey),
                  const SizedBox(width: 8),
                  Text('Seller: ${product['seller']}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 20, color: AppTheme.textGrey),
                  const SizedBox(width: 8),
                  Text('Location: ${product['location']}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.inventory, size: 20, color: AppTheme.textGrey),
                  const SizedBox(width: 8),
                  Text('Available: ${product['stock']} ${product['unit']}'),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _contactSeller(product),
                      icon: const Icon(Icons.phone),
                      label: const Text('Contact Seller'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.skyBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _addToCart(product),
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Add to Cart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: AppConstants.defaultPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort by',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.trending_down),
              title: const Text('Price: Low to High'),
              onTap: () => _sortProducts('price_asc'),
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Price: High to Low'),
              onTap: () => _sortProducts('price_desc'),
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Rating'),
              onTap: () => _sortProducts('rating'),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Newest First'),
              onTap: () => _sortProducts('newest'),
            ),
          ],
        ),
      ),
    );
  }

  void _sortProducts(String sortBy) {
    Navigator.pop(context);
    setState(() {
      switch (sortBy) {
        case 'price_asc':
          _filteredProducts.sort((a, b) => 
              int.parse(a['price']).compareTo(int.parse(b['price'])));
          break;
        case 'price_desc':
          _filteredProducts.sort((a, b) => 
              int.parse(b['price']).compareTo(int.parse(a['price'])));
          break;
        case 'rating':
          _filteredProducts.sort((a, b) => 
              b['rating'].compareTo(a['rating']));
          break;
        case 'newest':
          // Keep original order for newest
          _filteredProducts = products.where((product) {
            final matchesCategory = _selectedCategory == 'All' || 
                                   product['category'] == _selectedCategory;
            final matchesSearch = _searchQuery.isEmpty ||
                                product['name'].toLowerCase().contains(_searchQuery.toLowerCase());
            return matchesCategory && matchesSearch;
          }).toList();
          break;
      }
    });
  }

  void _toggleFavorite(Map<String, dynamic> product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product['name']} added to favorites')),
    );
  }

  void _addToCart(Map<String, dynamic> product) {
    Navigator.pop(context); // Close modal if open
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} added to cart'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            // Navigate to cart
          },
        ),
      ),
    );
  }

  void _contactSeller(Map<String, dynamic> product) {
    Navigator.pop(context); // Close modal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact ${product['seller']}'),
        content: const Text('Would you like to contact the seller for this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Seller contacted successfully!')),
              );
            },
            child: const Text('Contact'),
          ),
        ],
      ),
    );
  }
}
