import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';

/// Reusable product card component for lists and grids
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool showFavoriteButton;
  final bool isCompact;
  final VoidCallback? onFavoriteToggle;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.showFavoriteButton = true,
    this.isCompact = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: isCompact ? 2 : 3,
              child: _buildProductImage(),
            ),
            Expanded(
              flex: isCompact ? 1 : 2,
              child: _buildProductInfo(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: product.imageUrls.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product.imageUrls.first,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
        ),
        if (showFavoriteButton)
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.8),
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 16,
                onPressed: onFavoriteToggle,
                icon: const Icon(Icons.favorite_border, color: Colors.red),
              ),
            ),
          ),
        if (product.isOrganic)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Organic',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(product.category),
            size: isCompact ? 24 : 32,
            color: AppTheme.primaryGreen,
          ),
          if (!isCompact) ...[
            const SizedBox(height: 4),
            Text(
              product.category,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 12 : 14,
            ),
          ),
          if (!isCompact) ...[
            const SizedBox(height: 4),
            Text(
              product.category,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  '₹${product.price.toInt()}/${product.unit}',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 12 : 14,
                  ),
                ),
              ),
              Icon(
                product.quantity > 0 ? Icons.check_circle : Icons.error,
                size: 14,
                color: product.quantity > 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.local_florist;
      case 'grains':
        return Icons.grain;
      case 'seeds':
        return Icons.scatter_plot;
      case 'equipment':
        return Icons.agriculture;
      case 'dairy':
        return Icons.local_drink;
      case 'spices':
        return Icons.local_pizza;
      case 'fertilizers':
        return Icons.science;
      default:
        return Icons.category;
    }
  }
}

/// Product price display component
class ProductPriceDisplay extends StatelessWidget {
  final double price;
  final String unit;
  final bool showCurrency;
  final TextStyle? textStyle;

  const ProductPriceDisplay({
    super.key,
    required this.price,
    required this.unit,
    this.showCurrency = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          if (showCurrency)
            const TextSpan(
              text: '₹',
              style: TextStyle(color: AppTheme.primaryGreen),
            ),
          TextSpan(
            text: price.toInt().toString(),
            style: textStyle ?? const TextStyle(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          TextSpan(
            text: '/$unit',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: (textStyle?.fontSize ?? 16) * 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Product availability indicator
class ProductAvailabilityIndicator extends StatelessWidget {
  final int quantity;
  final String unit;
  final bool showQuantity;

  const ProductAvailabilityIndicator({
    super.key,
    required this.quantity,
    required this.unit,
    this.showQuantity = true,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = quantity > 0;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isAvailable ? Icons.check_circle : Icons.error,
          size: 16,
          color: isAvailable ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 4),
        Text(
          isAvailable
              ? showQuantity 
                  ? 'Available: $quantity $unit'
                  : 'Available'
              : 'Out of Stock',
          style: TextStyle(
            color: isAvailable ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Category chip component
class CategoryChip extends StatelessWidget {
  final String category;
  final bool isOrganic;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.category,
    this.isOrganic = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGreen
                : AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryGreen.withOpacity(0.3),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: 16,
                  color: isSelected ? Colors.white : AppTheme.primaryGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isOrganic) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco, size: 12, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Organic',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.local_florist;
      case 'grains':
        return Icons.grain;
      case 'seeds':
        return Icons.scatter_plot;
      case 'equipment':
        return Icons.agriculture;
      case 'dairy':
        return Icons.local_drink;
      case 'spices':
        return Icons.local_pizza;
      case 'fertilizers':
        return Icons.science;
      default:
        return Icons.category;
    }
  }
}

/// Seller information component
class SellerInfoCard extends StatelessWidget {
  final String sellerName;
  final String? sellerLocation;
  final double? rating;
  final int? reviewCount;
  final VoidCallback? onContactSeller;
  final bool isLoading;

  const SellerInfoCard({
    super.key,
    required this.sellerName,
    this.sellerLocation,
    this.rating,
    this.reviewCount,
    this.onContactSeller,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
            child: Text(
              sellerName.isNotEmpty ? sellerName[0].toUpperCase() : 'S',
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sellerName.isNotEmpty ? sellerName : 'Farm Fresh Vendor',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                const Row(
                  children: [
                    Icon(Icons.verified, size: 14, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Verified Seller',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (rating != null && reviewCount != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                      const SizedBox(width: 2),
                      Text(
                        '$rating ($reviewCount reviews)',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onContactSeller != null)
            isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : ElevatedButton(
                    onPressed: onContactSeller,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(
                      'Contact',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
        ],
      ),
    );
  }
}

/// Quantity selector component
class QuantitySelector extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final String unit;
  final double unitPrice;
  final ValueChanged<int> onQuantityChanged;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.maxQuantity,
    required this.unit,
    required this.unitPrice,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quantity',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildQuantityButton(
                icon: Icons.remove,
                onPressed: quantity > 1 
                    ? () => onQuantityChanged(quantity - 1) 
                    : null,
              ),
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  quantity.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add,
                onPressed: quantity < maxQuantity 
                    ? () => onQuantityChanged(quantity + 1) 
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Total: ₹${(unitPrice * quantity).toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null 
            ? AppTheme.primaryGreen.withOpacity(0.1) 
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: onPressed != null 
              ? AppTheme.primaryGreen.withOpacity(0.3) 
              : Colors.grey.shade300,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: onPressed != null ? AppTheme.primaryGreen : Colors.grey,
        iconSize: 20,
      ),
    );
  }
}

/// Action buttons for product detail
class ProductActionButtons extends StatelessWidget {
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;
  final bool isLoading;
  final bool isAvailable;

  const ProductActionButtons({
    super.key,
    this.onAddToCart,
    this.onBuyNow,
    this.isLoading = false,
    this.isAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isAvailable ? onAddToCart : null,
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text('Add to Cart'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryGreen),
              foregroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isAvailable ? onBuyNow : null,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.flash_on),
            label: Text(isLoading ? 'Processing...' : 'Buy Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}