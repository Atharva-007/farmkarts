import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../widgets/universal_header.dart';
import '../utils/app_logger.dart';
import '../services/cart_service.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;
  List<CartItem> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _loadCart();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final cartSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      List<CartItem> items = [];

      if (cartSnapshot.docs.isEmpty) {
        setState(() {
          _cartItems = items;
          _isLoading = false;
        });
        _animationController.forward();
        return;
      }

      final productIds = cartSnapshot.docs.map((d) => d.id).toList();
      final batches = <Future<QuerySnapshot>>[];
      for (int i = 0; i < productIds.length; i += 10) {
        final batch = productIds.skip(i).take(10).toList();
        batches.add(_firestore
            .collection('products')
            .where(FieldPath.documentId, whereIn: batch)
            .get());
      }

      final results = await Future.wait(batches);
      final products = <String, Product>{};
      for (var snapshot in results) {
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            products[doc.id] = Product.fromMap(doc.id, data);
          }
        }
      }

      for (var doc in cartSnapshot.docs) {
        final product = products[doc.id];
        if (product != null) {
          final quantity = doc.data()['quantity'] as int? ?? 1;
          items.add(CartItem(product: product, quantity: quantity));
        }
      }

      setState(() {
        _cartItems = items;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      AppLogger.error('Error loading cart', error: e, tag: 'CartPage');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeItem(item);
      return;
    }

    final success =
        await CartService.updateQuantity(item.product.id, newQuantity);
    if (success) {
      setState(() {
        item.quantity = newQuantity;
      });
    }
  }

  Future<void> _removeItem(CartItem item) async {
    final success = await CartService.removeFromCart(item.product.id);
    if (success) {
      setState(() {
        _cartItems.remove(item);
      });
      _showMessage('${item.product.name} removed from cart');
    }
  }

  Future<void> _clearCart() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear Cart',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to remove all items from your basket?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL',
                style:
                    TextStyle(color: AppTheme.getSecondaryTextColor(context))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0),
            child: const Text('CLEAR ALL'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await CartService.clearCart();
      if (success) {
        setState(() {
          _cartItems.clear();
        });
        _showMessage('Cart cleared');
      }
    }
  }

  double get _subtotal {
    return _cartItems.fold(
        0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.getPrimaryAccent(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            UniversalHeader(
              title: 'My Cart',
              subtitle: '${_cartItems.length} essential items',
              icon: Icons.shopping_basket_rounded,
              showBackButton: true,
              showProfile: true,
              actions: [
                if (_cartItems.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded,
                        color: Colors.white),
                    onPressed: _clearCart,
                    tooltip: 'Clear Cart',
                  ),
              ],
            ),
            if (_isLoading)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
            else if (_cartItems.isEmpty)
              SliverFillRemaining(child: _buildEmptyCart())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildCartItem(_cartItems[index]),
                    childCount: _cartItems.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _cartItems.isNotEmpty ? _buildCheckoutBar() : null,
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_cart_outlined,
                size: 100,
                color:
                    AppTheme.getPrimaryAccent(context).withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 32),
          const Text('Your cart is empty',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Stock up your farm with fresh produce',
              style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.getSecondaryTextColor(context))),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.storefront_rounded),
            label: const Text('BROWSE MARKETPLACE',
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.getPrimaryAccent(context),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.getPremiumShadow(context),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.getLayerColor(context),
                borderRadius: BorderRadius.circular(16),
                image: item.product.imageUrls.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(item.product.imageUrls.first),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: item.product.imageUrls.isEmpty
                  ? Icon(Icons.image_rounded,
                      color: AppTheme.getPrimaryAccent(context)
                          .withValues(alpha: 0.2),
                      size: 32)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.product.price.toStringAsFixed(0)}/${item.product.unit}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getPrimaryAccent(context)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildQtyBtn(Icons.remove_rounded,
                          () => _updateQuantity(item, item.quantity - 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('${item.quantity}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w900)),
                      ),
                      _buildQtyBtn(Icons.add_rounded,
                          () => _updateQuantity(item, item.quantity + 1)),
                      const Spacer(),
                      Text('₹${(item.product.price * item.quantity).toInt()}',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.getTextColor(context))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.getLayerColor(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppTheme.getPrimaryAccent(context)),
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -10))
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600)),
                Text('₹${_subtotal.toInt()}',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.getPrimaryAccent(context))),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_cartItems.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutPage(
                          product: _cartItems.first.product,
                          quantity: _cartItems.first.quantity,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getPrimaryAccent(context),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('PROCEED TO CHECKOUT',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, required this.quantity});
}
