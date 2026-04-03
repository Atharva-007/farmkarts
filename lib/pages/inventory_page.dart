import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/inventory_model.dart';
import '../services/inventory_service.dart';
import '../theme/app_theme.dart';
import '../utils/toast_helper.dart';
import '../widgets/universal_header.dart';
import '../widgets/universal_drawer.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final InventoryService _inventoryService = InventoryService();
  List<InventoryItem> _inventory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // No longer need to call _loadInventory manually as we'll use StreamBuilder
  }

  void _navigateToAddItem({InventoryItem? item}) async {
    final result = await Navigator.pushNamed(
      context,
      '/add-inventory-item',
      arguments: item,
    );

    if (result == true) {
      // StreamBuilder will handle the update
    }
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await _inventoryService.deleteItem(itemId);
      ToastHelper.showSuccess(context, 'Item deleted');
    } catch (e) {
      ToastHelper.showError(context, 'Failed to delete item');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      drawer: const UniversalDrawer(currentPage: 'inventory'),
      body: StreamBuilder<List<InventoryItem>>(
        stream: _inventoryService.getInventoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          _inventory = snapshot.data ?? [];
          
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              _buildInventoryStats(),
              _buildInventoryHeader(),
              _buildInventoryList(),
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          );
        }
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddItem(),
        backgroundColor: AppTheme.getPrimaryAccent(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('ADD ITEM', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return UniversalHeader(
      title: 'My Inventory',
      subtitle: 'Manage your farm stock',
      icon: Icons.inventory_2_rounded,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.white),
          onPressed: () => _navigateToAddItem(),
          tooltip: 'Add New Item',
        ),
        IconButton(
          icon: const Icon(Icons.sync, color: Colors.white),
          onPressed: () async {
            ToastHelper.showInfo(context, 'Syncing marketplace products...');
            await _inventoryService.syncMarketplaceToInventory();
          },
          tooltip: 'Sync with Marketplace',
        ),
      ],
    );
  }

  Widget _buildInventoryStats() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            _buildStatCard(
              'Total Items',
              _inventory.length.toString(),
              Icons.category,
              Colors.blue,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Low Stock',
              _inventory.where((item) => item.quantity < 10).length.toString(),
              Icons.warning_amber_rounded,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                Text(
                  label,
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
    );
  }

  Widget _buildInventoryHeader() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        child: Container(
          color: AppTheme.getBackgroundColor(context),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Stock',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.sort, size: 18),
                label: const Text('Sort'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.getPrimaryAccent(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryList() {
    if (_inventory.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No items in inventory',
                style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _navigateToAddItem(),
                child: const Text('Add Your First Item'),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = _inventory[index];
            return _buildInventoryItem(item);
          },
          childCount: _inventory.length,
        ),
      ),
    );
  }

  Widget _buildInventoryItem(InventoryItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLowStock = item.quantity < 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLowStock 
              ? Colors.orange.withOpacity(0.5) 
              : AppTheme.getBorderColor(context).withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Color indicator based on category
              Container(
                width: 6,
                color: _getCategoryColor(item.category),
              ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextColor(context),
                              ),
                            ),
                          ),
                          _buildCategoryBadge(item.category),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.scale_outlined, size: 16, color: AppTheme.getSecondaryTextColor(context)),
                          const SizedBox(width: 4),
                          Text(
                            '${item.quantity} ${item.unit}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isLowStock ? Colors.orange : AppTheme.getPrimaryAccent(context),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₹${item.price}/${item.unit}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.getSecondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                      if (isLowStock) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              'Low stock warning!',
                              style: TextStyle(fontSize: 12, color: Colors.orange[700], fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Actions
              Container(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: AppTheme.getDividerColor(context))),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: AppTheme.getPrimaryAccent(context), size: 20),
                      onPressed: () => _navigateToAddItem(item: item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _confirmDelete(item),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    final color = _getCategoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables': return Colors.green;
      case 'fruits': return Colors.orange;
      case 'grains': return Colors.amber;
      case 'seeds': return Colors.brown;
      case 'fertilizers': return Colors.blue;
      default: return AppTheme.primaryGreen;
    }
  }

  void _confirmDelete(InventoryItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : null,
        title: Text('Delete Item', style: TextStyle(color: isDark ? Colors.white : null)),
        content: Text('Are you sure you want to delete ${item.name}?', style: TextStyle(color: isDark ? Colors.white70 : null)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(item.id);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({required this.child});
  final Widget child;
  @override double get minExtent => 50;
  @override double get maxExtent => 50;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
