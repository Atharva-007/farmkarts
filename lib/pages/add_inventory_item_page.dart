import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/inventory_model.dart';
import '../services/inventory_service.dart';
import '../theme/app_theme.dart';
import '../utils/toast_helper.dart';

class AddInventoryItemPage extends StatefulWidget {
  final InventoryItem? item;

  const AddInventoryItemPage({super.key, this.item});

  @override
  State<AddInventoryItemPage> createState() => _AddInventoryItemPageState();
}

class _AddInventoryItemPageState extends State<AddInventoryItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryService = InventoryService();
  
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  String _category = 'Vegetables';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _quantityController = TextEditingController(text: widget.item?.quantity.toString() ?? '');
    _unitController = TextEditingController(text: widget.item?.unit ?? 'kg');
    _priceController = TextEditingController(text: widget.item?.price.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.item?.description ?? '');
    if (widget.item != null) {
      _category = widget.item!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (widget.item == null) {
        final item = InventoryItem(
          id: '',
          ownerId: user.uid,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          quantity: double.parse(_quantityController.text),
          unit: _unitController.text.trim(),
          category: _category,
          type: InventoryType.good, // Default to good for manual entry
          price: double.parse(_priceController.text),
          imageUrls: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _inventoryService.addItem(item);
        ToastHelper.showSuccess(context, 'Item added successfully');
      } else {
        final updates = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'quantity': double.parse(_quantityController.text),
          'unit': _unitController.text.trim(),
          'category': _category,
          'price': double.parse(_priceController.text),
        };
        await _inventoryService.updateItem(widget.item!.id, updates);
        ToastHelper.showSuccess(context, 'Item updated successfully');
      }
      Navigator.pop(context, true);
    } catch (e) {
      ToastHelper.showError(context, 'Failed to save item');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add Item' : 'Edit Item'),
        backgroundColor: AppTheme.getPrimaryAccent(context),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Basic Information'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Item Name',
                      hint: 'e.g. Organic Wheat',
                      icon: Icons.eco_outlined,
                      validator: (v) => v!.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      value: _category,
                      label: 'Category',
                      icon: Icons.category_outlined,
                      items: ['Vegetables', 'Fruits', 'Grains', 'Seeds', 'Fertilizers', 'Other'],
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Optional details about the item',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Stock & Pricing'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _quantityController,
                            label: 'Quantity',
                            hint: '0',
                            icon: Icons.scale_outlined,
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Enter qty' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _unitController,
                            label: 'Unit',
                            hint: 'kg',
                            icon: Icons.straighten_outlined,
                            validator: (v) => v!.isEmpty ? 'Enter unit' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _priceController,
                      label: 'Price per Unit',
                      hint: '₹ 0.00',
                      icon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      prefixText: '₹ ',
                      validator: (v) => v!.isEmpty ? 'Enter price' : null,
                    ),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.getPrimaryAccent(context),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Icon(
            widget.item == null ? Icons.add_business_rounded : Icons.edit_note_rounded,
            size: 64,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(height: 12),
          Text(
            widget.item == null ? 'Inventory Management' : 'Update Your Stock',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Keep your farm stock details accurate',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.getPrimaryAccent(context),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        style: TextStyle(color: AppTheme.getTextColor(context)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5)),
          prefixIcon: Icon(icon, color: AppTheme.getPrimaryAccent(context)),
          prefixText: prefixText,
          prefixStyle: TextStyle(color: AppTheme.getTextColor(context), fontWeight: FontWeight.bold),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((e) => DropdownMenuItem(
          value: e, 
          child: Text(e, style: TextStyle(color: AppTheme.getTextColor(context)))
        )).toList(),
        onChanged: onChanged,
        dropdownColor: AppTheme.getCardColor(context),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
          prefixIcon: Icon(icon, color: AppTheme.getPrimaryAccent(context)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveItem,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.getPrimaryAccent(context),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: AppTheme.getPrimaryAccent(context).withOpacity(0.4),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_rounded),
                  const SizedBox(width: 12),
                  Text(
                    widget.item == null ? 'ADD TO INVENTORY' : 'UPDATE ITEM',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ],
              ),
      ),
    );
  }
}
