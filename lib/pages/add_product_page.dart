import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../utils/toast_helper.dart';
import 'dart:typed_data';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';
import '../models/product_model.dart';
import '../services/marketplace_service.dart';
import '../services/product_service.dart';
import 'package:intl/intl.dart';
import '../widgets/universal_header.dart';
import '../widgets/universal_drawer.dart';

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
      drawer: const UniversalDrawer(currentPage: 'marketplace'),
      body: CustomScrollView(
        slivers: [
          UniversalHeader(
            title: widget.product == null ? 'List New Product' : 'Edit Product',
            subtitle: widget.product == null 
                ? 'Reach thousands of buyers today'
                : 'Keep your product details up to date',
            icon: widget.product == null ? Icons.add_shopping_cart : Icons.edit_note,
            showBackButton: true,
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: AppConstants.defaultPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: AppConstants.defaultPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Product Name *',
              hintText: 'e.g., Organic Red Onions',
              prefixIcon: const Icon(Icons.shopping_bag_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Category *',
              prefixIcon: const Icon(Icons.category_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description *',
              hintText: 'Describe quality, grade, and origin...',
              prefixIcon: const Icon(Icons.description_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            validator: (v) => v == null || v.trim().length < 10 ? 'Detailed description required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: AppConstants.defaultPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payments_outlined, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Pricing & Inventory',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price *',
                    prefixIcon: const Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) => setState(() => _selectedUnit = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Available Quantity *',
              prefixIcon: const Icon(Icons.inventory_2_outlined),
              suffixText: _selectedUnit,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildImagesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: AppConstants.defaultPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: AppTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Product Images',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Selected Images Grid
          if (_selectedImages.isNotEmpty) ...[
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length + (_selectedImages.length < 5 ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length) {
                    return _buildAddMoreImageButton();
                  }
                  return _buildImageThumbnail(index);
                },
              ),
            ),
          ] else ...[
            _buildImagePlaceholder(),
          ],
          const SizedBox(height: 12),
          Text(
            'High-quality images help you sell faster. Add up to 5 photos.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(int index) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: kIsWeb 
              ? Image.network(
                  _selectedImages[index].path,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
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
                    }
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  },
                ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMoreImageButton() {
    return InkWell(
      onTap: _selectImages,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: AppTheme.primaryGreen, size: 24),
            SizedBox(height: 4),
            Text('Add', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return InkWell(
      onTap: _selectImages,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, color: AppTheme.primaryGreen.withOpacity(0.5), size: 40),
            const SizedBox(height: 12),
            const Text(
              'Upload Product Photos',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to browse gallery',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: AppConstants.defaultPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.assignment_outlined, color: AppTheme.success, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Product Specifics',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Organic Certified', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Check if grown without chemicals'),
            value: _isOrganic,
            onChanged: (v) => setState(() => _isOrganic = v),
            activeColor: AppTheme.primaryGreen,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDateSelector('Harvest Date', _harvestDate, true)),
              const SizedBox(width: 12),
              Expanded(child: _buildDateSelector('Expiry Date', _expiryDate, false)),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Pickup Location',
              hintText: 'City, State',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime? date, bool isHarvest) {
    return InkWell(
      onTap: () => _selectDate(isHarvest),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: AppTheme.textGrey)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  date != null ? DateFormat('dd/MM/yy').format(date) : 'Select',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: AppConstants.defaultPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.tag, color: Colors.teal, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Search Tags',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _addTag,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) => Chip(
                label: Text(tag, style: const TextStyle(fontSize: 12)),
                onDeleted: () => _removeTag(tag),
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                deleteIconColor: AppTheme.error,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              )).toList(),
            )
          else
            Text(
              'Add keywords like "Fresh", "Grade A" to help buyers find you.',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 12, fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.product == null ? Icons.publish : Icons.check_circle_outline, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    widget.product == null ? 'PUBLISH PRODUCT' : 'SAVE CHANGES',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
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
