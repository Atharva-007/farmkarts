import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/inventory_model.dart';
import '../services/inventory_service.dart';
import '../theme/app_theme.dart';
import '../utils/toast_helper.dart';
import '../widgets/universal_header.dart';

class AddInventoryItemPage extends StatefulWidget {
  final InventoryItem? item;

  const AddInventoryItemPage({super.key, this.item});

  @override
  State<AddInventoryItemPage> createState() => _AddInventoryItemPageState();
}

class _AddInventoryItemPageState extends State<AddInventoryItemPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _inventoryService = InventoryService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _supplierController;
  late TextEditingController _batchController;

  String _category = 'Vegetables';
  DateTime? _expiryDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);

    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _quantityController =
        TextEditingController(text: widget.item?.quantity.toString() ?? '');
    _unitController = TextEditingController(text: widget.item?.unit ?? 'kg');
    _priceController =
        TextEditingController(text: widget.item?.price.toString() ?? '');
    _descriptionController =
        TextEditingController(text: widget.item?.description ?? '');
    _supplierController =
        TextEditingController(text: widget.item?.supplier ?? '');
    _batchController =
        TextEditingController(text: widget.item?.batchNumber ?? '');

    if (widget.item != null) {
      _category = widget.item!.category;
      _expiryDate = widget.item!.expiryDate;
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _supplierController.dispose();
    _batchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: AppTheme.primaryGreen,
                    onPrimary: Colors.white,
                    surface: AppTheme.darkCard,
                    onSurface: Colors.white,
                  ),
                  dialogTheme:
                      DialogThemeData(backgroundColor: AppTheme.darkBackground),
                )
              : Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: AppTheme.primaryGreen,
                    onPrimary: Colors.white,
                    onSurface: AppTheme.getTextColor(context),
                  ),
                ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _expiryDate) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final double qty = double.parse(_quantityController.text);
      final double price = double.parse(_priceController.text);
      final String status =
          qty < 5 ? 'Critical' : (qty < 15 ? 'Low' : 'Optimal');

      if (widget.item == null) {
        final item = InventoryItem(
          id: '',
          userId: user.uid,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          quantity: qty,
          unit: _unitController.text.trim(),
          category: _category,
          type: InventoryType.good,
          price: price,
          imageUrls: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          expiryDate: _expiryDate,
          supplier: _supplierController.text.trim(),
          batchNumber: _batchController.text.trim(),
          stockStatus: status,
          totalValue: qty * price,
        );
        await _inventoryService.addItem(item);
        if (mounted)
          ToastHelper.showSuccess(context, 'Item added to inventory');
      } else {
        final updates = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'quantity': qty,
          'unit': _unitController.text.trim(),
          'category': _category,
          'price': price,
          'expiryDate':
              _expiryDate != null ? Timestamp.fromDate(_expiryDate!) : null,
          'supplier': _supplierController.text.trim(),
          'batchNumber': _batchController.text.trim(),
          'stockStatus': status,
          'totalValue': qty * price,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await _inventoryService.updateItem(widget.item!.id, updates);
        if (mounted) ToastHelper.showSuccess(context, 'Inventory item updated');
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('AddInventoryItem Error: $e');
      if (mounted)
        ToastHelper.showError(context, 'Database error: ${e.toString()}');
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
                  widget.item == null ? 'Add to Inventory' : 'Edit Inventory',
              subtitle: widget.item == null
                  ? 'Record your new farm stock'
                  : 'Update existing stock details',
              icon: Icons.add_business_rounded,
              showBackButton: true,
              showProfile: false,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: _buildForm(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: AppTheme.getBorderColor(context)
                .withValues(alpha: isDark ? 0.1 : 0.5)),
        boxShadow: isDark ? [] : AppTheme.getPremiumShadow(context),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock Details',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.getTextColor(context)),
            ),
            const SizedBox(height: 24),
            _buildTextField(
                _nameController, 'Item Name', Icons.inventory_2_rounded),
            const SizedBox(height: 20),
            _buildCategoryDropdown(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: _buildTextField(
                        _quantityController, 'Quantity', Icons.balance_rounded,
                        isNumber: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildTextField(
                        _unitController, 'Unit', Icons.straighten_rounded,
                        hint: 'kg, tons, etc')),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(
                _priceController, 'Unit Cost / Value', Icons.payments_rounded,
                isNumber: true, prefix: '₹ '),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(),
            ),
            Text(
              'Management Data (Optional)',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.getPrimaryAccent(context)),
            ),
            const SizedBox(height: 20),
            _buildTextField(_supplierController, 'Supplier Name',
                Icons.local_shipping_rounded,
                hint: 'Where did you buy this?'),
            const SizedBox(height: 20),
            _buildTextField(_batchController, 'Batch / Lot Number',
                Icons.qr_code_scanner_rounded),
            const SizedBox(height: 20),
            _buildDatePicker(),
            const SizedBox(height: 20),
            _buildTextField(
                _descriptionController, 'Internal Notes', Icons.notes_rounded,
                maxLines: 3),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getPrimaryAccent(context),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3))
                    : Text(
                        widget.item == null
                            ? 'SAVE TO INVENTORY'
                            : 'UPDATE STOCK',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expiry Date',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppTheme.getSecondaryTextColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectExpiryDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.getLayerColor(context).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: AppTheme.getPrimaryAccent(context), size: 20),
                const SizedBox(width: 12),
                Text(
                  _expiryDate == null
                      ? 'Not specified'
                      : DateFormat('dd MMM, yyyy').format(_expiryDate!),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _expiryDate == null
                        ? AppTheme.getSecondaryTextColor(context)
                        : AppTheme.getTextColor(context),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
    String? hint,
    String? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppTheme.getSecondaryTextColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          maxLines: maxLines,
          style: TextStyle(
              color: AppTheme.getTextColor(context),
              fontWeight: FontWeight.w600),
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
                Icon(icon, color: AppTheme.getPrimaryAccent(context), size: 20),
            filled: true,
            fillColor: AppTheme.getLayerColor(context).withValues(alpha: 0.3),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: AppTheme.getPrimaryAccent(context), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              if (label.contains('Optional') ||
                  label.contains('Supplier') ||
                  label.contains('Batch') ||
                  label.contains('Internal Notes') ||
                  label.contains('Notes')) {
                return null;
              }
              return 'Please enter $label';
            }
            if (isNumber && double.tryParse(v) == null)
              return 'Enter a valid number';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = [
      'Vegetables',
      'Fruits',
      'Grains',
      'Seeds',
      'Fertilizers',
      'Pesticides',
      'Equipment',
      'Other'
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppTheme.getSecondaryTextColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _category,
          dropdownColor: AppTheme.getCardColor(context),
          style: TextStyle(
              color: AppTheme.getTextColor(context),
              fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.category_rounded,
                color: AppTheme.getPrimaryAccent(context), size: 20),
            filled: true,
            fillColor: AppTheme.getLayerColor(context).withValues(alpha: 0.3),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: AppTheme.getPrimaryAccent(context), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          items: categories
              .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c,
                      style: TextStyle(color: AppTheme.getTextColor(context)))))
              .toList(),
          onChanged: (v) => setState(() => _category = v!),
        ),
      ],
    );
  }
}
