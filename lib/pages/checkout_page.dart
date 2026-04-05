import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/payment_service.dart';
import '../services/order_tracking_service.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../widgets/universal_header.dart';
import 'order_success_page.dart';

class CheckoutPage extends StatefulWidget {
  final Product product;
  final int quantity;

  const CheckoutPage({
    super.key,
    required this.product,
    required this.quantity,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _selectedDeliveryType = 'standard';
  bool _isProcessing = false;
  double _deliveryCharges = 0.0;

  final PaymentService _paymentService = PaymentService();
  final OrderTrackingService _orderService = OrderTrackingService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);

    _paymentService.initialize();
    _loadUserInfo();
    _calculateDeliveryCharges();
    _setupPaymentCallbacks();

    _animationController.forward();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
    }
  }

  void _calculateDeliveryCharges() {
    setState(() {
      _deliveryCharges = _selectedDeliveryType == 'express' ? 50.0 : 20.0;
    });
  }

  void _setupPaymentCallbacks() {
    _paymentService.onPaymentSuccess = (paymentId) {
      _handlePaymentSuccess(paymentId);
    };

    _paymentService.onPaymentError = (error) {
      _handlePaymentError(error.message ?? 'Payment failed');
    };
  }

  Future<void> _handlePaymentSuccess(String paymentId) async {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderSuccessPage(
            paymentId: paymentId,
            product: widget.product,
            quantity: widget.quantity,
          ),
        ),
      );
    }
  }

  void _handlePaymentError(String error) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: $error'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Please login to continue');

      await _paymentService.createOrderWithPayment(
        productId: widget.product.id,
        productName: widget.product.name,
        sellerId: widget.product.sellerId,
        sellerName: widget.product.sellerName,
        buyerId: user.uid,
        buyerName: _nameController.text,
        buyerEmail: _emailController.text,
        buyerPhone: _phoneController.text,
        buyerAddress: _addressController.text,
        price: widget.product.price,
        quantity: widget.quantity,
        unit: widget.product.unit,
        notes: _notesController.text,
        deliveryType: _selectedDeliveryType,
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  double get _subtotal => widget.product.price * widget.quantity;
  double get _total => _subtotal + _deliveryCharges;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            UniversalHeader(
              title: 'Secure Checkout',
              subtitle: 'Finalize your order',
              icon: Icons.lock_rounded,
              showBackButton: true,
              showProfile: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildOrderSummarySection(),
                      const SizedBox(height: 20),
                      _buildBuyerInfoSection(),
                      const SizedBox(height: 20),
                      _buildDeliverySection(),
                      const SizedBox(height: 20),
                      _buildPaymentSummarySection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionBottomBar(),
    );
  }

  Widget _buildOrderSummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.getPremiumShadow(context),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: widget.product.imageUrls.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(widget.product.imageUrls.first),
                          fit: BoxFit.cover)
                      : null,
                  color: AppTheme.getLayerColor(context),
                ),
                child: widget.product.imageUrls.isEmpty
                    ? const Icon(Icons.agriculture_rounded)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.product.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Seller: ${widget.product.sellerName}',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getSecondaryTextColor(context))),
                    const SizedBox(height: 8),
                    Text(
                        '${widget.quantity} ${widget.product.unit} x ₹${widget.product.price.toInt()}',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.getPrimaryAccent(context))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.getPremiumShadow(context),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Delivery Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildField(_nameController, 'Full Name', Icons.person_rounded),
          const SizedBox(height: 16),
          _buildField(_phoneController, 'Phone Number', Icons.phone_rounded,
              isPhone: true),
          const SizedBox(height: 16),
          _buildField(_addressController, 'Full Delivery Address',
              Icons.location_on_rounded,
              maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller, String label, IconData icon,
      {bool isPhone = false, int maxLines = 1}) {
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
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          decoration: InputDecoration(
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

  Widget _buildDeliverySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.getPremiumShadow(context),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Delivery Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildDeliveryOption(
              'standard', 'Standard Delivery', '5-7 Business Days', '₹20'),
          const SizedBox(height: 8),
          _buildDeliveryOption(
              'express', 'Express Delivery', '2-3 Business Days', '₹50'),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption(
      String id, String title, String time, String price) {
    final isSelected = _selectedDeliveryType == id;
    return InkWell(
      onTap: () {
        setState(() => _selectedDeliveryType = id);
        _calculateDeliveryCharges();
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.getPrimaryAccent(context).withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected
                  ? AppTheme.getPrimaryAccent(context)
                  : AppTheme.getBorderColor(context).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected
                    ? AppTheme.getPrimaryAccent(context)
                    : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(time,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getSecondaryTextColor(context))),
                ],
              ),
            ),
            Text(price,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummarySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildPriceRow('Subtotal', _subtotal),
          const SizedBox(height: 12),
          _buildPriceRow('Delivery Charges', _deliveryCharges),
          const Divider(height: 32),
          _buildPriceRow('TOTAL AMOUNT', _total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: isTotal ? 15 : 13,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
                color: isTotal
                    ? AppTheme.getTextColor(context)
                    : AppTheme.getSecondaryTextColor(context))),
        Text('₹${amount.toInt()}',
            style: TextStyle(
                fontSize: isTotal ? 22 : 15,
                fontWeight: FontWeight.w900,
                color: isTotal
                    ? AppTheme.getPrimaryAccent(context)
                    : AppTheme.getTextColor(context))),
      ],
    );
  }

  Widget _buildActionBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
            onPressed: _isProcessing ? null : _processOrder,
            icon: const Icon(Icons.verified_user_rounded),
            label: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3))
                : Text('PAY ₹${_total.toInt()} SECURELY',
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
