import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory_model.dart';
import '../services/inventory_service.dart';
import '../theme/app_theme.dart';
import '../utils/toast_helper.dart';
import '../widgets/universal_header.dart';
import '../widgets/universal_drawer.dart';
import '../widgets/premium_fab.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  final InventoryService _inventoryService = InventoryService();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToAddItem({InventoryItem? item}) async {
    final result = await Navigator.pushNamed(
      context,
      '/add-inventory-item',
      arguments: item,
    );

    if (result == true) {
      // StreamBuilder handles updates automatically
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
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;
            final inventory = snapshot.data ?? [];

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                UniversalHeader(
                  title: 'My Inventory',
                  subtitle: 'Professional Farm Stock Management',
                  icon: Icons.inventory_2_rounded,
                  showBackButton: true,
                  showProfile: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.sync_rounded, color: Colors.white),
                      onPressed: () async {
                        ToastHelper.showInfo(
                            context, 'Syncing with live marketplace...');
                        await _inventoryService.syncMarketplaceToInventory();
                      },
                      tooltip: 'Sync with Marketplace',
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isLoading
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
                              _buildInventoryStats(inventory),
                              _buildInventoryHeader(),
                              _buildInventoryList(inventory),
                            ],
                          ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 150)),
              ],
            );
          }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: PremiumFAB(
        onPressed: () => _navigateToAddItem(),
        icon: Icons.add_circle_outline_rounded,
        bottomPadding: 70, // Lowered
      ),
    );
  }

  Widget _buildInventoryStats(List<InventoryItem> inventory) {
    double totalValuation = inventory.fold(0,
        (sum, item) => sum + (item.totalValue ?? (item.quantity * item.price)));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard(
                'Total Value',
                '₹${totalValuation.toInt()}',
                Icons.account_balance_wallet_rounded,
                AppTheme.primaryGreen,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Critical Stock',
                inventory.where((item) => item.quantity < 5).length.toString(),
                Icons.report_problem_rounded,
                Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                'Inventory Items',
                inventory.length.toString(),
                Icons.inventory_rounded,
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Low Stock',
                inventory
                    .where((item) => item.quantity >= 5 && item.quantity < 15)
                    .length
                    .toString(),
                Icons.warning_amber_rounded,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: AppTheme.getBorderColor(context)
                  .withValues(alpha: isDark ? 0.1 : 0.5)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.getTextColor(context),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryHeader() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Stock Inventory',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list_rounded,
                    size: 16, color: AppTheme.getPrimaryAccent(context)),
                const SizedBox(width: 4),
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getPrimaryAccent(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList(List<InventoryItem> inventory) {
    if (inventory.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.inventory_2_outlined,
                    size: 80, color: Colors.grey.withValues(alpha: 0.3)),
              ),
              const SizedBox(height: 24),
              Text(
                'No items in inventory',
                style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.getSecondaryTextColor(context),
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _navigateToAddItem(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Your First Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getPrimaryAccent(context),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: inventory.length,
      itemBuilder: (context, index) {
        final item = inventory[index];
        return FadeTransition(
          opacity: _animationController,
          child: _buildInventoryItem(item),
        );
      },
    );
  }

  Widget _buildInventoryItem(InventoryItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isCritical = item.quantity < 5;
    final bool isLow = item.quantity >= 5 && item.quantity < 15;

    final Color statusColor =
        isCritical ? Colors.red : (isLow ? Colors.orange : Colors.green);
    final String statusText =
        isCritical ? 'CRITICAL' : (isLow ? 'LOW STOCK' : 'OPTIMAL');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: (isCritical || isLow) ? 1.5 : 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: InkWell(
        onTap: () => _navigateToAddItem(item: item),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon/Image Section
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(item.category)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(_getCategoryIcon(item.category),
                        color: _getCategoryColor(item.category), size: 28),
                  ),
                  const SizedBox(width: 16),

                  // Content Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextColor(context),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: statusColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Category: ${item.category}',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.getSecondaryTextColor(context)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoMini(
                                'Qty', '${item.quantity} ${item.unit}'),
                            _buildInfoMini('Value',
                                '₹${(item.totalValue ?? (item.quantity * item.price)).toInt()}'),
                            if (item.expiryDate != null)
                              _buildInfoMini('Expiry',
                                  DateFormat('MMM yy').format(item.expiryDate!))
                            else
                              const SizedBox.shrink(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.getLayerColor(context).withValues(alpha: 0.3),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  if (item.batchNumber != null && item.batchNumber!.isNotEmpty)
                    Text(
                      'Batch: ${item.batchNumber}',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.getSecondaryTextColor(context),
                          fontWeight: FontWeight.bold),
                    )
                  else
                    const Spacer(),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/add-product', arguments: {
                        'name': item.name,
                        'price': item.price,
                        'quantity': item.quantity.toInt(),
                        'unit': item.unit,
                        'category': item.category,
                      });
                    },
                    icon: const Icon(Icons.sell_rounded, size: 14),
                    label: const Text('SELL ON MARKET',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w900)),
                    style: TextButton.styleFrom(
                        foregroundColor: AppTheme.accentOrange),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 18),
                    onPressed: () => _confirmDelete(item),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoMini(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppTheme.getTextColor(context))),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return Icons.eco_rounded;
      case 'fruits':
        return Icons.apple_rounded;
      case 'grains':
        return Icons.grass_rounded;
      case 'seeds':
        return Icons.grain_rounded;
      case 'fertilizers':
        return Icons.science_rounded;
      case 'equipment':
        return Icons.handyman_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return Colors.green;
      case 'fruits':
        return Colors.orange;
      case 'grains':
        return Colors.amber;
      case 'seeds':
        return Colors.brown;
      case 'fertilizers':
        return Colors.blue;
      case 'equipment':
        return Colors.purple;
      default:
        return AppTheme.primaryGreen;
    }
  }

  void _confirmDelete(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Item',
            style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontWeight: FontWeight.bold)),
        content: Text('Remove ${item.name} from your inventory?',
            style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL',
                style:
                    TextStyle(color: AppTheme.getSecondaryTextColor(context))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(item.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
