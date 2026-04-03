import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../widgets/universal_header.dart';
import '../widgets/universal_drawer.dart';
import '../utils/responsive_helper.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Product> _wishlistProducts = [];
  Map<String, List<Product>> _folders = {'All Items': []};
  String _currentFolder = 'All Items';
  bool _isSelectionMode = false;
  Set<String> _selectedProducts = {};

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get wishlist items
      final wishlistSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .get();

      List<Product> products = [];
      
      for (var doc in wishlistSnapshot.docs) {
        final productId = doc.id;
        
        // Get product details
        final productDoc = await _firestore
            .collection('products')
            .doc(productId)
            .get();
        
        if (productDoc.exists) {
          final data = productDoc.data();
          if (data != null) {
            products.add(Product.fromMap(productDoc.id, data));
          }
        }
      }

      // Load folders
      final foldersDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist_folders')
          .doc('folders')
          .get();

      Map<String, List<Product>> folders = {'All Items': products};
      
      if (foldersDoc.exists) {
        final foldersData = foldersDoc.data() as Map<String, dynamic>;
        foldersData.forEach((folderName, productIds) {
          folders[folderName] = products
              .where((p) => (productIds as List).contains(p.id))
              .toList();
        });
      }

      setState(() {
        _wishlistProducts = products;
        _folders = folders;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading wishlist: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final folderName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (folderName != null && folderName.isNotEmpty && folderName != 'All Items') {
      setState(() {
        _folders[folderName] = [];
      });
      await _saveFolders();
    }
  }

  Future<void> _saveFolders() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      Map<String, List<String>> foldersData = {};
      _folders.forEach((name, products) {
        if (name != 'All Items') {
          foldersData[name] = products.map((p) => p.id).toList();
        }
      });

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist_folders')
          .doc('folders')
          .set(foldersData);
    } catch (e) {
      print('Error saving folders: $e');
    }
  }

  void _moveToFolder(String folderName) async {
    if (_selectedProducts.isEmpty) return;

    final productsToMove = _wishlistProducts
        .where((p) => _selectedProducts.contains(p.id))
        .toList();

    setState(() {
      _folders[folderName]!.addAll(productsToMove);
      _selectedProducts.clear();
      _isSelectionMode = false;
    });

    await _saveFolders();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moved ${productsToMove.length} items to $folderName'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  Future<void> _removeFromWishlist(String productId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(productId)
          .delete();

      setState(() {
        _wishlistProducts.removeWhere((p) => p.id == productId);
        _folders.forEach((_, products) {
          products.removeWhere((p) => p.id == productId);
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from wishlist'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      print('Error removing from wishlist: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFolderProducts = _folders[_currentFolder] ?? [];
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          UniversalHeader(
            title: 'Wishlist',
            subtitle: '${_wishlistProducts.length} items',
            icon: Icons.favorite,
            showBackButton: true,
            actions: [
              if (_wishlistProducts.isNotEmpty && !_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.checklist, color: Colors.white),
                  onPressed: () => setState(() => _isSelectionMode = true),
                  tooltip: 'Select Items',
                ),
              if (_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() {
                    _isSelectionMode = false;
                    _selectedProducts.clear();
                  }),
                  tooltip: 'Cancel',
                ),
              if (_wishlistProducts.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.create_new_folder, color: Colors.white),
                  onPressed: _createFolder,
                  tooltip: 'New Folder',
                ),
            ],
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _wishlistProducts.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: [
                      _buildFolderTabs(),
                      if (_isSelectionMode) _buildSelectionActions(),
                      Expanded(
                        child: currentFolderProducts.isEmpty
                            ? _buildEmptyFolder()
                            : GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: ResponsiveHelper.isMobile(context) ? 2 : 4,
                                  childAspectRatio: 0.7,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: currentFolderProducts.length,
                                itemBuilder: (context, index) {
                                  return _buildWishlistItem(currentFolderProducts[index]);
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildFolderTabs() {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: _folders.keys.map((folderName) {
          final isSelected = folderName == _currentFolder;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                '$folderName (${_folders[folderName]!.length})',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.primaryGreen,
              onSelected: (selected) {
                setState(() => _currentFolder = folderName);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectionActions() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppTheme.primaryGreen.withOpacity(0.1),
      child: Row(
        children: [
          Text(
            '${_selectedProducts.length} selected',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _selectedProducts.isEmpty
                ? null
                : () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Move to Folder',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._folders.keys
                                .where((f) => f != 'All Items')
                                .map((folderName) => ListTile(
                                      leading: const Icon(Icons.folder),
                                      title: Text(folderName),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _moveToFolder(folderName);
                                      },
                                    )),
                          ],
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.drive_file_move),
            label: const Text('Move'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFolder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No items in this folder',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Your wishlist is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add products you love to your wishlist',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Browse Products'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistItem(Product product) {
    final isSelected = _selectedProducts.contains(product.id);
    
    return Card(
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedProducts.remove(product.id);
              } else {
                _selectedProducts.add(product.id);
              }
            });
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
              _selectedProducts.add(product.id);
            });
          }
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      image: product.imageUrls.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(product.imageUrls.first),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: product.imageUrls.isEmpty
                        ? Icon(Icons.image, size: 50, color: Colors.grey[400])
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${product.price}/${product.unit}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isSelectionMode)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryGreen : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryGreen : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isSelected ? Icons.check : null,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(4),
                ),
              ),
            if (!_isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => _removeFromWishlist(product.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearWishlist() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Wishlist'),
        content: const Text('Remove all items from wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final userId = _auth.currentUser?.uid;
        if (userId == null) return;

        final batch = _firestore.batch();
        for (var product in _wishlistProducts) {
          batch.delete(_firestore
              .collection('users')
              .doc(userId)
              .collection('wishlist')
              .doc(product.id));
        }
        await batch.commit();

        setState(() {
          _wishlistProducts.clear();
          _folders = {'All Items': []};
        });
      } catch (e) {
        print('Error clearing wishlist: $e');
      }
    }
  }
}

