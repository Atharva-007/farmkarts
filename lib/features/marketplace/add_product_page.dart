import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../models/product_model.dart';
import '../../services/marketplace_service.dart';
import '../../services/user_state_service.dart';

class AddProductPage extends StatefulWidget {
  final Function? onProductAdded;
  final Product? product;

  const AddProductPage({super.key, this.onProductAdded, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _selectedCategory = 'Vegetables';
  String _selectedUnit = 'kg';
  bool _isOrganic = false;
  bool _isSubmitting = false;
  
  final MarketplaceService _marketplaceService = MarketplaceService();

  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Grains',
    'Seeds',
    'Pulses',
    'Spices',
    'Equipment',
    'Other'
  ];

  final List<String> _units = [
    'kg',
    'gram',
    'quintal',
    'ton',
    'piece',
    'dozen',
    'liter',
    'bunch'
  ];

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
    
    if (widget.product != null) {
      _populateFields();
    }
    
    _animationController.forward();
  }

  void _populateFields() {
    final product = widget.product!;
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _quantityController.text = product.quantity.toString();
    _locationController.text = product.location;
    _selectedCategory = product.category;
    _selectedUnit = product.unit;
    _isOrganic = product.isOrganic;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add products')),
      );
      return;
    }

    final userStateService = Provider.of<UserStateService>(context, listen: false);
    
    setState(() => _isSubmitting = true);

    try {
      final product = Product(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        price: double.parse(_priceController.text.trim()),
        unit: _selectedUnit,
        imageUrls: widget.product?.imageUrls ?? [], // Keep existing images or empty for new
        sellerId: user.uid,
        sellerName: userStateService.currentUser?.fullName ?? 
                   user.displayName ?? 
                   user.email?.split('@')[0] ?? 
                   'Seller',
        location: _locationController.text.trim().isEmpty 
                  ? 'Location not specified'
                  : _locationController.text.trim(),
        timestamp: DateTime.now(),
        isOrganic: _isOrganic,
        quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
        tags: _generateTags(),
      );

      if (widget.product != null) {
        // Update existing product
        print('Updating product with ID: ${widget.product!.id}');
        await _marketplaceService.updateProduct(
          widget.product!.id,
          product.toMap(),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully!'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } else {
        // Add new product
        print('Adding new product: ${product.name}');
        final productId = await _marketplaceService.addProduct(product, user.uid);
        print('Product added with ID: $productId');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product added successfully!'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }

      if (widget.onProductAdded != null) {
        widget.onProductAdded!();
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate successful addition
      }
    } catch (e) {
      print('Error submitting product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  List<String> _generateTags() {
    final tags = <String>[];
    
    // Add category as tag
    tags.add(_selectedCategory.toLowerCase());
    
    // Add organic tag if applicable
    if (_isOrganic) {
      tags.add('organic');
    }
    
    // Add name words as tags
    final nameWords = _nameController.text.toLowerCase().split(' ');
    for (final word in nameWords) {
      if (word.isNotEmpty && word.length > 2) {
        tags.add(word);
      }
    }
    
    return tags.toSet().toList(); // Remove duplicates
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: AppConstants.defaultPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 20),
                _buildProductDetailsCard(),
                const SizedBox(height: 20),
                _buildPricingCard(),
                const SizedBox(height: 20),
                _buildAdditionalInfoCard(),
                const SizedBox(height: 30),
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Container(
        padding: AppConstants.defaultPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryGreen.withValues(alpha: 0.1),
              AppTheme.lightGreen.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.product == null ? Icons.add_box : Icons.edit,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product == null ? 'Add New Product' : 'Edit Product',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  Text(
                    widget.product == null 
                        ? 'Fill in the details to list your product'
                        : 'Update your product information',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetailsCard() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                hintText: 'e.g., Fresh Tomatoes, Organic Wheat',
                prefixIcon: Icon(Icons.agriculture),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Product name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe your product quality, origin, etc.',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                if (value.trim().length < 10) {
                  return 'Description should be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., Village, District, State',
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                // Location is optional, will use user's default location if empty
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing & Quantity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price *',
                      hintText: '0',
                      prefixIcon: Icon(Icons.currency_rupee),
                      prefixText: '₹ ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Price is required';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Enter valid price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUnit = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Available Quantity *',
                hintText: '0',
                prefixIcon: const Icon(Icons.inventory),
                suffixText: _selectedUnit,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Quantity is required';
                }
                final quantity = int.tryParse(value);
                if (quantity == null || quantity <= 0) {
                  return 'Enter valid quantity';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Organic Product'),
              subtitle: const Text('Mark if your product is organically grown'),
              value: _isOrganic,
              onChanged: (value) {
                setState(() {
                  _isOrganic = value;
                });
              },
              activeColor: AppTheme.success,
              secondary: Icon(
                Icons.eco,
                color: _isOrganic ? AppTheme.success : AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.product == null ? Icons.add_shopping_cart : Icons.update,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.product == null ? 'Add Product' : 'Update Product',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class BuyRequestPage extends StatelessWidget {
  final dynamic product;
  final int? quantity;

  const BuyRequestPage({super.key, required this.product, this.quantity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Request'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Buy request feature coming soon!'),
      ),
    );
  }
}