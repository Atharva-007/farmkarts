import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'services/marketplace_service.dart';
import 'theme/app_theme.dart';
import 'utils/app_constants.dart';
import 'models/product_model.dart';

class AddSellItemPage extends StatefulWidget {
  final Function(String, String, String, String, String, int)? onAddItem;

  const AddSellItemPage({super.key, this.onAddItem});

  @override
  _AddSellItemPageState createState() => _AddSellItemPageState();
}

class _AddSellItemPageState extends State<AddSellItemPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _selectedCategory = 'Vegetables';
  String _selectedUnit = 'kg';
  bool _isOrganic = false;
  bool _isSubmitting = false;
  List<File> _selectedImages = [];
  List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();

  final MarketplaceService _marketplaceService = MarketplaceService();
  final ImagePicker _imagePicker = ImagePicker();

  // Error tracking
  String? _nameError;
  String? _descriptionError;
  String? _priceError;
  String? _quantityError;
  String? _locationError;
  String? _generalError;

  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Grains',
    'Seeds',
    'Pulses',
    'Spices',
    'Equipment',
    'Fertilizers',
    'Dairy',
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
    'bunch',
    'packet'
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
    
    _animationController.forward();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _productNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _loadUserLocation() {
    // Load user's saved location or get current location
    _locationController.text = 'Your Location'; // Placeholder
  }

  void _clearErrors() {
    setState(() {
      _nameError = null;
      _descriptionError = null;
      _priceError = null;
      _quantityError = null;
      _locationError = null;
      _generalError = null;
    });
  }

  void _showSuccessMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: AppTheme.success,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showErrorMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: AppTheme.error,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  bool _validateInputs() {
    _clearErrors();
    bool isValid = true;

    // Validate product name
    if (_productNameController.text.trim().isEmpty) {
      _nameError = 'Product name is required';
      isValid = false;
    } else if (_productNameController.text.trim().length < 3) {
      _nameError = 'Product name must be at least 3 characters';
      isValid = false;
    } else if (_productNameController.text.trim().length > 50) {
      _nameError = 'Product name must be less than 50 characters';
      isValid = false;
    }

    // Validate description
    if (_descriptionController.text.trim().isEmpty) {
      _descriptionError = 'Description is required';
      isValid = false;
    } else if (_descriptionController.text.trim().length < 20) {
      _descriptionError = 'Description must be at least 20 characters';
      isValid = false;
    } else if (_descriptionController.text.trim().length > 500) {
      _descriptionError = 'Description must be less than 500 characters';
      isValid = false;
    }

    // Validate price
    if (_priceController.text.trim().isEmpty) {
      _priceError = 'Price is required';
      isValid = false;
    } else {
      final price = double.tryParse(_priceController.text.trim());
      if (price == null) {
        _priceError = 'Please enter a valid price';
        isValid = false;
      } else if (price <= 0) {
        _priceError = 'Price must be greater than 0';
        isValid = false;
      } else if (price > 100000) {
        _priceError = 'Price must be less than ₹1,00,000';
        isValid = false;
      }
    }

    // Validate quantity
    if (_quantityController.text.trim().isEmpty) {
      _quantityError = 'Quantity is required';
      isValid = false;
    } else {
      final quantity = int.tryParse(_quantityController.text.trim());
      if (quantity == null) {
        _quantityError = 'Please enter a valid quantity';
        isValid = false;
      } else if (quantity <= 0) {
        _quantityError = 'Quantity must be greater than 0';
        isValid = false;
      } else if (quantity > 10000) {
        _quantityError = 'Quantity must be less than 10,000 $_selectedUnit';
        isValid = false;
      }
    }

    // Validate location
    if (_locationController.text.trim().isEmpty) {
      _locationError = 'Location is required';
      isValid = false;
    } else if (_locationController.text.trim().length < 5) {
      _locationError = 'Please provide a more detailed location';
      isValid = false;
    }

    setState(() {}); // Refresh UI to show errors
    return isValid;
  }

  Future<void> _pickImages() async {
    try {
      if (_selectedImages.length >= 5) {
        _showErrorMessage('Maximum 5 images allowed');
        return;
      }

      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxHeight: 1024,
        maxWidth: 1024,
        imageQuality: 80,
      );
      
      if (images.isEmpty) return;
      
      if (images.length + _selectedImages.length > 5) {
        _showErrorMessage('You can only select up to 5 images total');
        return;
      }
      
      // Validate file sizes
      for (final image in images) {
        final file = File(image.path);
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) { // 5MB limit
          _showErrorMessage('Image ${image.name} is too large. Maximum size is 5MB');
          return;
        }
      }
      
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)));
      });
      
      _showSuccessMessage('${images.length} image(s) added successfully');
    } catch (e) {
      _showErrorMessage('Error selecting images: ${e.toString()}');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    _showSuccessMessage('Image removed');
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty) {
      _showErrorMessage('Please enter a tag');
      return;
    }
    
    if (tag.length < 2) {
      _showErrorMessage('Tag must be at least 2 characters');
      return;
    }
    
    if (_tags.contains(tag.toLowerCase())) {
      _showErrorMessage('Tag already added');
      return;
    }
    
    if (_tags.length >= 10) {
      _showErrorMessage('Maximum 10 tags allowed');
      return;
    }
    
    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
    
    _showSuccessMessage('Tag "$tag" added');
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    _showSuccessMessage('Tag removed');
  }

  Future<void> _submitItem() async {
    // Clear any previous errors
    _clearErrors();
    
    // Validate all inputs
    if (!_validateInputs()) {
      _showErrorMessage('Please fix the errors above and try again');
      return;
    }

    // Check if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _generalError = 'Please login to add products';
      });
      _showErrorMessage('Please login to add products');
      return;
    }

    // Show loading state
    setState(() {
      _isSubmitting = true;
      _generalError = null;
    });

    try {
      // Show progress message
      _showSuccessMessage('Creating your product listing...');

      // Create product model
      final product = Product(
        id: '', // Will be set by Firestore
        name: _productNameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        price: double.parse(_priceController.text.trim()),
        unit: _selectedUnit,
        imageUrls: [], // Will be updated after image upload
        sellerId: user.uid,
        sellerName: user.displayName ?? 'Unknown Seller',
        location: _locationController.text.trim(),
        timestamp: DateTime.now(),
        isAvailable: true, // Add this required field
        isOrganic: _isOrganic,
        quantity: int.parse(_quantityController.text.trim()),
        tags: _tags,
      );

      // Add product to marketplace using Firebase directly
      final productId = await _marketplaceService.addProduct(product, user.uid);

      // Call the callback if provided (for backward compatibility)
      if (widget.onAddItem != null) {
        widget.onAddItem!(
          _productNameController.text.trim(),
          _descriptionController.text.trim(),
          _priceController.text.trim(),
          _selectedCategory,
          _selectedUnit,
          int.parse(_quantityController.text.trim()),
        );
      }

      if (mounted) {
        // Show success message
        _showSuccessMessage('🎉 Product listed successfully! Your product is now live on the marketplace.');
        
        // Show success dialog
        _showSuccessDialog(productId);
        
        // Clear form after success
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = _getReadableError(e.toString());
        setState(() {
          _generalError = errorMessage;
        });
        _showErrorMessage(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _getReadableError(String error) {
    // Convert technical errors to user-friendly messages
    if (error.contains('network')) {
      return '🌐 Network error. Please check your internet connection and try again.';
    } else if (error.contains('permission')) {
      return '🔒 Permission denied. Please check your account permissions.';
    } else if (error.contains('quota')) {
      return '📊 Storage quota exceeded. Please contact support.';
    } else if (error.contains('timeout')) {
      return '⏱️ Request timed out. Please try again.';
    } else if (error.contains('firestore')) {
      return '🗄️ Database error. Please try again in a few moments.';
    } else if (error.contains('auth')) {
      return '🔐 Authentication error. Please login again.';
    } else {
      return '❌ Something went wrong. Please try again or contact support if the problem persists.';
    }
  }

  void _showSuccessDialog(String productId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.success, size: 28),
              const SizedBox(width: 12),
              const Text('Success!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your product has been successfully listed on the marketplace!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Details:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('• Name: ${_productNameController.text.trim()}'),
                    Text('• Category: $_selectedCategory'),
                    Text('• Price: ₹${_priceController.text.trim()} per $_selectedUnit'),
                    Text('• Quantity: ${_quantityController.text.trim()} $_selectedUnit'),
                    if (_selectedImages.isNotEmpty)
                      Text('• Images: ${_selectedImages.length} uploaded'),
                    if (_tags.isNotEmpty)
                      Text('• Tags: ${_tags.join(', ')}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '✅ Your product is now visible to buyers\n'
                '📱 You will receive notifications for inquiries\n'
                '💬 Buyers can contact you directly',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('Add Another Product'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _clearForm() {
    _productNameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _quantityController.clear();
    _locationController.clear();
    _tagController.clear();
    setState(() {
      _selectedCategory = 'Vegetables';
      _selectedUnit = 'kg';
      _isOrganic = false;
      _selectedImages.clear();
      _tags.clear();
      _clearErrors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Add Product for Sale'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isSubmitting ? null : _clearForm,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Form',
          ),
        ],
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
                
                // General error display
                if (_generalError != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _generalError!,
                            style: TextStyle(
                              color: AppTheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: AppTheme.error,
                          onPressed: () {
                            setState(() {
                              _generalError = null;
                            });
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                
                _buildProductDetailsCard(),
                const SizedBox(height: 20),
                _buildImageUploadCard(),
                const SizedBox(height: 20),
                _buildPricingCard(),
                const SizedBox(height: 20),
                _buildLocationCard(),
                const SizedBox(height: 20),
                _buildTagsCard(),
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
              AppTheme.primaryGreen.withOpacity(0.1),
              AppTheme.lightGreen.withOpacity(0.1),
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
              child: const Icon(
                Icons.add_box,
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
                    'List Your Product',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  Text(
                    'Fill in the details to sell your agricultural products',
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
            
            // Product Name Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _productNameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name *',
                    hintText: 'e.g., Fresh Tomatoes, Organic Wheat',
                    prefixIcon: const Icon(Icons.agriculture),
                    errorText: _nameError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (value) {
                    if (_nameError != null) {
                      setState(() {
                        _nameError = null;
                      });
                    }
                  },
                ),
                if (_nameError != null) const SizedBox(height: 8),
              ],
            ),
            const SizedBox(height: 16),
            
            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category *',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      _getCategoryIcon(category),
                      const SizedBox(width: 8),
                      Text(category),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Description Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Describe your product quality, origin, farming methods, etc.',
                    prefixIcon: const Icon(Icons.description),
                    errorText: _descriptionError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    if (_descriptionError != null) {
                      setState(() {
                        _descriptionError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Characters: ${_descriptionController.text.length}/500',
                  style: TextStyle(
                    fontSize: 12,
                    color: _descriptionController.text.length > 500 
                      ? AppTheme.error 
                      : AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    switch (category) {
      case 'Vegetables':
        return const Icon(Icons.local_florist, color: Colors.green);
      case 'Fruits':
        return const Icon(Icons.apple, color: Colors.red);
      case 'Grains':
        return const Icon(Icons.grain, color: Colors.orange);
      case 'Seeds':
        return const Icon(Icons.eco, color: Colors.brown);
      case 'Pulses':
        return const Icon(Icons.circle, color: Colors.yellow);
      case 'Spices':
        return const Icon(Icons.local_fire_department, color: Colors.deepOrange);
      case 'Equipment':
        return const Icon(Icons.build, color: Colors.grey);
      case 'Fertilizers':
        return const Icon(Icons.scatter_plot, color: Colors.purple);
      case 'Dairy':
        return const Icon(Icons.local_drink, color: Colors.blue);
      default:
        return const Icon(Icons.category, color: Colors.grey);
    }
  }

  Widget _buildImageUploadCard() {
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
                  'Product Images',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_selectedImages.length}/5',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedImages.isEmpty)
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.primaryGreen,
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 40,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add Product Photos',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Tap to select images',
                          style: TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _selectedImages.length) {
                          return GestureDetector(
                            onTap: _selectedImages.length < 5 ? _pickImages : null,
                            child: Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.add,
                                color: _selectedImages.length < 5 
                                  ? AppTheme.primaryGreen 
                                  : Colors.grey,
                              ),
                            ),
                          );
                        }
                        
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImages[index],
                                  width: 80,
                                  height: 100,
                                  fit: BoxFit.cover,
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
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Text(
              'Add up to 5 high-quality photos of your product. Good photos increase sales!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textGrey,
              ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Price *',
                          hintText: '0',
                          prefixIcon: const Icon(Icons.currency_rupee),
                          prefixText: '₹ ',
                          errorText: _priceError,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixText: 'per $_selectedUnit',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        onChanged: (value) {
                          if (_priceError != null) {
                            setState(() {
                              _priceError = null;
                            });
                          }
                        },
                      ),
                      if (_priceError == null && _priceController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Market competitive price recommended',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Available Quantity *',
                    hintText: '0',
                    prefixIcon: const Icon(Icons.inventory),
                    suffixText: _selectedUnit,
                    errorText: _quantityError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    if (_quantityError != null) {
                      setState(() {
                        _quantityError = null;
                      });
                    }
                  },
                ),
                if (_quantityError == null && _quantityController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Keep this updated to avoid overselling',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Price calculation preview
            if (_priceController.text.isNotEmpty && _quantityController.text.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Value:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    Text(
                      '₹${_calculateTotalValue().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.primaryGreen,
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

  double _calculateTotalValue() {
    final price = double.tryParse(_priceController.text) ?? 0;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    return price * quantity;
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Your Location *',
                    hintText: 'e.g., Village, District, State',
                    prefixIcon: const Icon(Icons.location_on),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: _getCurrentLocation,
                      tooltip: 'Get current location',
                    ),
                    errorText: _locationError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (value) {
                    if (_locationError != null) {
                      setState(() {
                        _locationError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.info, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This helps buyers know where the product is available and calculate delivery costs.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _getCurrentLocation() async {
    try {
      // Show loading
      _showSuccessMessage('Getting your location...');
      
      // In a real implementation, you would use geolocator package
      // For now, we'll show a placeholder
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _locationController.text = 'Current Location, City, State';
        _locationError = null;
      });
      
      _showSuccessMessage('Location updated successfully');
    } catch (e) {
      _showErrorMessage('Could not get location. Please enter manually.');
    }
  }

  Widget _buildTagsCard() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tags (Optional)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: 'Add tags like "fresh", "premium", "farm-direct"',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onFieldSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addTag,
                  icon: Icon(Icons.add, color: AppTheme.primaryGreen),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeTag(tag),
                    side: BorderSide(color: AppTheme.primaryGreen),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Tags help buyers find your product more easily',
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
            const Divider(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.info.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info, color: AppTheme.info, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tips for better sales:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.info,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '• Use clear, descriptive product names\n'
                          '• Add high-quality photos from multiple angles\n'
                          '• Set competitive prices based on market rates\n'
                          '• Provide detailed descriptions about quality\n'
                          '• Keep quantity information updated\n'
                          '• Add relevant tags for better visibility',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
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

  Widget _buildSubmitButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppTheme.primaryGreen.withOpacity(0.3),
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
                      const Icon(Icons.add_shopping_cart, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'List Product for Sale',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _clearForm,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textGrey,
              side: BorderSide(color: AppTheme.textGrey),
            ),
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Clear All Fields'),
          ),
        ),
      ],
    );
  }
}
