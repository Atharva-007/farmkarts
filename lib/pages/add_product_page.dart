import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../utils/toast_helper.dart';
import '../widgets/universal_header.dart';

class AddProductPage extends StatefulWidget {
  final Product? product;

  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _locationController;

  String _category = 'Vegetables';
  String _unit = 'kg';
  bool _isOrganic = false;
  bool _isLoading = false;
  final List<XFile> _imageFiles = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);

    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.product?.description ?? '');
    _priceController =
        TextEditingController(text: widget.product?.price.toString() ?? '');
    _quantityController =
        TextEditingController(text: widget.product?.quantity.toString() ?? '');
    _locationController =
        TextEditingController(text: widget.product?.location ?? '');

    if (widget.product != null) {
      _category = widget.product!.category;
      _unit = widget.product!.unit;
      _isOrganic = widget.product!.isOrganic;
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await picker.pickMultiImage();
        if (images.isNotEmpty) {
          setState(() => _imageFiles.addAll(images));
        }
      } else {
        final XFile? image = await picker.pickImage(source: source);
        if (image != null) {
          setState(() => _imageFiles.add(image));
        }
      }
    } catch (e) {
      ToastHelper.showError(context, 'Failed to pick image: $e');
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.getSurfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('Add Product Photos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child:
                    const Icon(Icons.photo_library_rounded, color: Colors.blue),
              ),
              title: const Text('Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child:
                    const Icon(Icons.camera_alt_rounded, color: Colors.green),
              ),
              title: const Text('Take Photo',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (widget.product == null) {
        await _productService.createProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category,
          price: double.parse(_priceController.text),
          unit: _unit,
          quantity: int.parse(_quantityController.text),
          location: _locationController.text.trim(),
          isOrganic: _isOrganic,
          imageFiles: _imageFiles,
        );
        if (mounted)
          ToastHelper.showSuccess(context, 'Product listed successfully');
      } else {
        final updates = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _category,
          'price': double.parse(_priceController.text),
          'unit': _unit,
          'quantity': int.parse(_quantityController.text),
          'location': _locationController.text.trim(),
          'isOrganic': _isOrganic,
          'timestamp': FieldValue.serverTimestamp(),
        };
        await _productService.updateProduct(widget.product!.id, updates);
        if (mounted)
          ToastHelper.showSuccess(context, 'Product details updated');
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ToastHelper.showError(context, 'Failed to save product');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            UniversalHeader(
              title:
                  widget.product == null ? 'List New Product' : 'Edit Product',
              subtitle: 'Connect your harvest to buyers nationwide',
              icon: Icons.add_photo_alternate_rounded,
              showBackButton: true,
              showProfile: false,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                child: Column(
                  children: [
                    _buildImagePickerSection(isDark),
                    const SizedBox(height: 24),
                    _buildMainForm(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtonBar(isDark),
    );
  }

  Widget _buildImagePickerSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Product Photos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${_imageFiles.length} selected',
                style: TextStyle(
                    color: AppTheme.getPrimaryAccent(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _imageFiles.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: _showImageSourceSheet,
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.getPrimaryAccent(context)
                          .withValues(alpha: isDark ? 0.1 : 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: AppTheme.getPrimaryAccent(context)
                              .withValues(alpha: isDark ? 0.3 : 0.2),
                          width: 2,
                          style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_rounded,
                            color: AppTheme.getPrimaryAccent(context),
                            size: 32),
                        const SizedBox(height: 8),
                        const Text('Add Image',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }
              final file = _imageFiles[index - 1];
              return Stack(
                children: [
                  Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      image: DecorationImage(
                          image: FileImage(File(file.path)), fit: BoxFit.cover),
                      border: Border.all(
                          color: AppTheme.getBorderColor(context)
                              .withValues(alpha: 0.3)),
                    ),
                  ),
                  // Primary Badge
                  if (index == 1)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('PRIMARY',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  // Remove Button
                  Positioned(
                    top: 8,
                    right: 20,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _imageFiles.removeAt(index - 1)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: isDark ? [] : AppTheme.getPremiumShadow(context),
        border: Border.all(
            color: AppTheme.getBorderColor(context)
                .withValues(alpha: isDark ? 0.1 : 0.5)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                )),
            const SizedBox(height: 24),
            _buildField(_nameController, 'Product Name', Icons.eco_rounded,
                hint: 'e.g. Organic Alphonso Mangoes'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: _buildDropdown(
                        'Category',
                        _category,
                        _productService.getCategories(),
                        (v) => setState(() => _category = v!))),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildDropdown(
                        'Unit',
                        _unit,
                        Future.value(_productService.getUnits()),
                        (v) => setState(() => _unit = v!))),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: _buildField(_priceController, 'Price per Unit',
                        Icons.payments_rounded,
                        isNumber: true, prefix: '₹ ')),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildField(_quantityController, 'Total Stock',
                        Icons.inventory_2_rounded,
                        isNumber: true)),
              ],
            ),
            const SizedBox(height: 20),
            _buildField(
                _locationController, 'Farm Location', Icons.location_on_rounded,
                hint: 'e.g. Nashik, Maharashtra'),
            const SizedBox(height: 20),
            _buildField(_descriptionController, 'Detailed Description',
                Icons.description_rounded,
                maxLines: 4,
                hint: 'Describe quality, variety, and harvest info...'),
            const SizedBox(height: 20),
            _buildOrganicSwitch(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false, int maxLines = 1, String? hint, String? prefix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppTheme.getSecondaryTextColor(context),
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppTheme.getTextColor(context)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: AppTheme.getSecondaryTextColor(context)
                    .withValues(alpha: 0.4)),
            prefixText: prefix,
            prefixStyle: TextStyle(
                color: AppTheme.getPrimaryAccent(context),
                fontWeight: FontWeight.bold),
            prefixIcon:
                Icon(icon, size: 20, color: AppTheme.getPrimaryAccent(context)),
            filled: true,
            fillColor: AppTheme.getLayerColor(context).withValues(alpha: 0.3),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Field required' : null,
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value,
      Future<List<String>> itemsFuture, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppTheme.getSecondaryTextColor(context),
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        FutureBuilder<List<String>>(
            future: itemsFuture,
            builder: (context, snapshot) {
              final items = snapshot.data ?? [value];
              return DropdownButtonFormField<String>(
                value: items.contains(value) ? value : items.first,
                dropdownColor: AppTheme.getCardColor(context),
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.getTextColor(context)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor:
                      AppTheme.getLayerColor(context).withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                items: items
                    .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e,
                            style: TextStyle(
                                color: AppTheme.getTextColor(context)))))
                    .toList(),
                onChanged: onChanged,
              );
            }),
      ],
    );
  }

  Widget _buildOrganicSwitch(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isOrganic
            ? Colors.green.withValues(alpha: isDark ? 0.1 : 0.05)
            : AppTheme.getLayerColor(context).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _isOrganic
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.transparent),
      ),
      child: Row(
        children: [
          Icon(Icons.eco_rounded,
              color: _isOrganic ? Colors.green : Colors.grey, size: 24),
          const SizedBox(width: 12),
          Expanded(
              child: Text('This is Organic Produce',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ))),
          Switch.adaptive(
            value: _isOrganic,
            onChanged: (v) => setState(() => _isOrganic = v),
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, -10))
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveProduct,
            icon: const Icon(Icons.rocket_launch_rounded),
            label: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3))
                : Text(
                    widget.product == null
                        ? 'LAUNCH ON MARKETPLACE'
                        : 'UPDATE LISTING',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 1)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.getPrimaryAccent(context),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              elevation: 4,
              shadowColor:
                  AppTheme.getPrimaryAccent(context).withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
