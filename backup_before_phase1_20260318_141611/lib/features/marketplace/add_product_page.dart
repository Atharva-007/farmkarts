import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../../utils/toast_helper.dart';
import 'dart:typed_data';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../models/product_model.dart';
import '../../services/marketplace_service.dart';
import '../../services/product_service.dart';

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
  final TextEditingController _certificationController = TextEditingController();

  String _selectedCategory = 'Vegetables';
  String _selectedUnit = 'kg';
  bool _isOrganic = false;
  bool _isSubmitting = false;
  List<XFile> _selectedImages = []; // Changed from List<File> to List<XFile> for web compatibility
  List<String> _tags = [];
  DateTime? _harvestDate;
  DateTime? _expiryDate;
  
  final MarketplaceService _marketplaceService = MarketplaceService();
  final ProductService _productService = ProductService();
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Grains',
    'Seeds',
    'Pulses',
    'Spices',
    'Equipment',
    'Dairy',
    'Fertilizers',
    'Organic',
    'Other'
  ];

  final List<String> _units = [
    'kg',
    'g',
    'ton',
    'piece',
    'dozen',
    'bundle',
    'bag',
    'liter',
    'ml'
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
    _tags = List<String>.from(product.tags);
    // Note: Existing images would need to be handled separately for updates
  }

  Future<void> _selectImages() async {
    try {
      final List<XFile>? selectedImages = await _imagePicker.pickMultiImage();
      
      if (selectedImages != null && selectedImages.isNotEmpty) {
        setState(() {
          _selectedImages = selectedImages;
          if (_selectedImages.length > 5) {
            _selectedImages = _selectedImages.take(5).toList();
          }
        });
        
        if (selectedImages.length > 5) {
          _showErrorSnackBar('Maximum 5 images allowed. First 5 images selected.');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _selectDate(bool isHarvestDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isHarvestDate) {
          _harvestDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  void _addTag() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Tag'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter tag name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final tag = controller.text.trim();
                if (tag.isNotEmpty && !_tags.contains(tag)) {
                  setState(() {
                    _tags.add(tag);
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ToastHelper.showSuccess(context, message);
  }

  void _showErrorMessage(String message) {
    ToastHelper.showError(context, message);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _certificationController.dispose();
    super.dispose();
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorMessage('Please login to add products');
      return;
    }
    
    setState(() => _isSubmitting = true);

    try {
      // Create product object
      final product = Product(
        id: widget.product?.id ?? '', // Will be set by Firestore for new products
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        price: double.parse(_priceController.text.trim()),
        unit: _selectedUnit,
        imageUrls: [], // Will be updated after image upload
        sellerId: user.uid,
        sellerName: user.displayName ?? user.email ?? 'Unknown Seller',
        location: _locationController.text.trim().isEmpty 
                  ? 'Location not specified'
                  : _locationController.text.trim(),
        timestamp: DateTime.now(),
        isOrganic: _isOrganic,
        isAvailable: true,
        quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
        tags: _tags,
      );

      if (widget.product != null) {
        // Update existing product
        final updates = product.toMap();
        updates.remove('id'); // Don't update ID
        updates['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
        
        await _marketplaceService.updateProduct(widget.product!.id, updates);
        
        if (mounted) {
          _showSuccessMessage('Product updated successfully!');
        }
      } else {
        // Add new product using ProductService (Firebase)
        print('AddProductPage: Creating product using ProductService...');
        final productId = await _productService.createProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          price: double.parse(_priceController.text.trim()),
          unit: _selectedUnit,
          quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
          location: _locationController.text.trim().isEmpty 
                    ? 'Location not specified'
                    : _locationController.text.trim(),
          tags: _tags,
          isOrganic: _isOrganic,
          harvestDate: _harvestDate,
          expiryDate: _expiryDate,
          certificationDetails: _certificationController.text.trim().isNotEmpty 
                               ? _certificationController.text.trim() 
                               : null,
          imageFiles: _selectedImages,
        );
        
        if (mounted) {
          _showSuccessMessage('🎉 Product added successfully! Your product is now live on the marketplace.');
        }
      }

      if (widget.onProductAdded != null) {
        widget.onProductAdded!();
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error submitting product: $e');
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('XMLHttpRequest error')) {
          errorMessage = '🌐 Network connection failed. Please check your internet connection and try again.';
        } else if (errorMessage.contains('permission-denied')) {
          errorMessage = '🔒 Permission denied. Please check your authentication and try again.';
        } else if (errorMessage.contains('network')) {
          errorMessage = '🌐 Network error. Please check your internet connection.';
        }
        
        _showErrorMessage(errorMessage);
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
                _buildImagesCard(),
                const SizedBox(height: 20),
                _buildProductDetailsCard(),
                const SizedBox(height: 20),
                _buildPricingCard(),
                const SizedBox(height: 20),
                _buildAdditionalInfoCard(),
                const SizedBox(height: 20),
                _buildTagsCard(),
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

  Widget _buildImagesCard() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Images',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Selected Images Grid
            if (_selectedImages.isNotEmpty) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb 
                          ? Image.network(
                              _selectedImages[index].path,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, color: Colors.grey),
                                );
                              },
                            )
                          : FutureBuilder<Uint8List>(
                              future: _selectedImages[index].readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  );
                                } else {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(child: CircularProgressIndicator()),
                                  );
                                }
                              },
                            ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // Add Images Button
            OutlinedButton.icon(
              onPressed: _selectedImages.length < 5 ? _selectImages : null,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(_selectedImages.isEmpty 
                  ? 'Add Product Images' 
                  : 'Add More Images (${_selectedImages.length}/5)'),
            ),
            const SizedBox(height: 8),
            Text(
              'Add up to 5 high-quality images of your product',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textGrey,
              ),
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
            const SizedBox(height: 16),
            
            // Date Fields
            Row(
              children: [
                // Harvest Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Harvest Date',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _selectDate(true),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _harvestDate != null 
                              ? '${_harvestDate!.day}/${_harvestDate!.month}/${_harvestDate!.year}'
                              : 'Select Date',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Expiry Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expiry Date',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _selectDate(false),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _expiryDate != null 
                              ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                              : 'Select Date',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Certification Details
            if (_isOrganic) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _certificationController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Organic Certification Details',
                  hintText: 'Enter certification information',
                  prefixIcon: Icon(Icons.verified),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTagsCard() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tags',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Tag'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            if (_tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeTag(tag),
                    backgroundColor: AppTheme.lightGreen.withAlpha(100),
                  );
                }).toList(),
              ),
            ] else ...[
              Text(
                'No tags added. Tags help buyers find your product easily.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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
