import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../widgets/universal_header.dart';
import '../utils/responsive_helper.dart';
import '../services/product_service.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ProductService _productService = ProductService();

  bool _isLoading = true;
  List<Product> _wishlistProducts = [];
  Map<String, List<Product>> _folders = {'All Items': []};
  String _currentFolder = 'All Items';
  bool _isSelectionMode = false;
  final Set<String> _selectedProducts = {};

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadWishlist();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWishlist() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Get wishlist items
      final wishlistSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .orderBy('addedAt', descending: true)
          .get();

      // Fetch all products in parallel
      final productFutures = wishlistSnapshot.docs
          .map((doc) => _productService.getProductById(doc.id));
      final products =
          (await Future.wait(productFutures)).whereType<Product>().toList();

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
          final folderProducts = products
              .where((p) => (productIds as List).contains(p.id))
              .toList();
          if (folderName != 'All Items') {
            folders[folderName] = folderProducts;
          }
        });
      }

      if (mounted) {
        setState(() {
          _wishlistProducts = products;
          _folders = folders;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final folderName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: Text('Create Folder',
            style: TextStyle(color: isDark ? Colors.white : null)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : null),
          decoration: InputDecoration(
            labelText: 'Folder Name',
            labelStyle: TextStyle(color: isDark ? Colors.white70 : null),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: isDark ? Colors.white24 : Colors.grey),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (folderName != null &&
        folderName.isNotEmpty &&
        folderName != 'All Items') {
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
      debugPrint('Error saving folders: $e');
    }
  }

  void _moveToFolder(String folderName) async {
    if (_selectedProducts.isEmpty) return;

    final productsToMove = _wishlistProducts
        .where((p) => _selectedProducts.contains(p.id))
        .toList();

    setState(() {
      final currentInFolder = _folders[folderName] ?? [];
      for (var p in productsToMove) {
        if (!currentInFolder.any((existing) => existing.id == p.id)) {
          currentInFolder.add(p);
        }
      }
      _folders[folderName] = currentInFolder;
      _selectedProducts.clear();
      _isSelectionMode = false;
    });

    await _saveFolders();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Items moved to $folderName'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
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
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error removing from wishlist: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFolderProducts = _folders[_currentFolder] ?? [];

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          UniversalHeader(
            title: 'My Wishlist',
            subtitle: '${_wishlistProducts.length} items collected',
            icon: Icons.favorite_rounded,
            showBackButton: true,
            showProfile: true,
            actions: [
              if (_wishlistProducts.isNotEmpty && !_isSelectionMode)
                IconButton(
                  icon:
                      const Icon(Icons.checklist_rounded, color: Colors.white),
                  onPressed: () => setState(() => _isSelectionMode = true),
                  tooltip: 'Select Items',
                ),
              if (_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => setState(() {
                    _isSelectionMode = false;
                    _selectedProducts.clear();
                  }),
                  tooltip: 'Cancel',
                ),
              if (_wishlistProducts.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.create_new_folder_rounded,
                      color: Colors.white),
                  onPressed: _createFolder,
                  tooltip: 'New Folder',
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Center(
                          key: const ValueKey('loading'),
                          child: CircularProgressIndicator(
                              color: AppTheme.getPrimaryAccent(context))),
                    )
                  : Column(
                      key: const ValueKey('content'),
                      children: [
                        _buildFolderTabs(),
                        if (_isSelectionMode) _buildSelectionActions(),
                        currentFolderProducts.isEmpty
                            ? _buildEmptyFolder()
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      ResponsiveHelper.isMobile(context)
                                          ? 2
                                          : 4,
                                  childAspectRatio: 0.72,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                ),
                                itemCount: currentFolderProducts.length,
                                itemBuilder: (context, index) {
                                  return _buildWishlistItem(
                                      currentFolderProducts[index], index);
                                },
                              ),
                      ],
                    ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildFolderTabs() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: _folders.keys.map((folderName) {
          final isSelected = folderName == _currentFolder;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(
                folderName,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppTheme.getSecondaryTextColor(context),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.getPrimaryAccent(context),
              backgroundColor: AppTheme.getSurfaceColor(context),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              onSelected: (selected) {
                if (selected) setState(() => _currentFolder = folderName);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectionActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.1),
      child: Row(
        children: [
          Text(
            '${_selectedProducts.length} items selected',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.getPrimaryAccent(context),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _selectedProducts.isEmpty
                ? null
                : () => _showMoveToFolderSheet(),
            icon: const Icon(Icons.folder_shared_rounded),
            label: const Text('Move To'),
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.getPrimaryAccent(context)),
          ),
          IconButton(
            onPressed: _selectedProducts.isEmpty ? null : _deleteSelected,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showMoveToFolderSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Move to Folder',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _folders.keys
                    .where((f) => f != 'All Items' && f != _currentFolder)
                    .map((folderName) => ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.getPrimaryAccent(context)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.folder_rounded,
                                color: AppTheme.getPrimaryAccent(context)),
                          ),
                          title: Text(folderName,
                              style: TextStyle(
                                  color: AppTheme.getTextColor(context),
                                  fontWeight: FontWeight.w500)),
                          trailing:
                              const Icon(Icons.chevron_right_rounded, size: 20),
                          onTap: () {
                            Navigator.pop(context);
                            _moveToFolder(folderName);
                          },
                        ))
                    .toList(),
              ),
            ),
            if (_folders.length <= 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No other folders available.\nCreate one first!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Items?'),
        content: Text(
            'Remove ${_selectedProducts.length} items from your wishlist?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ids = _selectedProducts.toList();
      setState(() => _isLoading = true);
      for (var id in ids) {
        await _removeFromWishlist(id);
      }
      setState(() {
        _isSelectionMode = false;
        _selectedProducts.clear();
        _isLoading = false;
      });
    }
  }

  Widget _buildEmptyFolder() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 80,
              color: AppTheme.getSecondaryTextColor(context)
                  .withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Empty folder',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistItem(Product product, int index) {
    final isSelected = _selectedProducts.contains(product.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = (index * 0.05).clamp(0.0, 1.0);
        final animation = CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0),
              curve: Curves.easeOut),
        );

        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 20),
            child: child,
          ),
        );
      },
      child: Card(
        elevation: isDark ? 0 : 2,
        color: AppTheme.getCardColor(context),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected
                ? AppTheme.getPrimaryAccent(context)
                : AppTheme.getBorderColor(context)
                    .withValues(alpha: isDark ? 0.1 : 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
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
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey[50],
                      ),
                      child: product.imageUrls.isNotEmpty
                          ? Image.network(
                              product.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.broken_image_outlined,
                                      color: AppTheme.getSecondaryTextColor(
                                          context)),
                            )
                          : Icon(Icons.agriculture_rounded,
                              size: 40,
                              color: AppTheme.getPrimaryAccent(context)
                                  .withValues(alpha: 0.2)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextColor(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '₹${product.price}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.getPrimaryAccent(context),
                              ),
                            ),
                            Text(
                              '/${product.unit}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.getSecondaryTextColor(context),
                              ),
                            ),
                          ],
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
                      color: isSelected
                          ? AppTheme.getPrimaryAccent(context)
                          : Colors.black26,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              if (!_isSelectionMode)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.black : Colors.white)
                              .withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 14,
                            color: AppTheme.getSecondaryTextColor(context)),
                      ),
                      onPressed: () => _removeFromWishlist(product.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
