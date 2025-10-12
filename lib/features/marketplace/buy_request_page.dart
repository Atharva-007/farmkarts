import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';

class BuyRequestPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final int quantity;

  const BuyRequestPage({
    super.key,
    required this.product,
    this.quantity = 1,
  });

  @override
  State<BuyRequestPage> createState() => _BuyRequestPageState();
}

class _BuyRequestPageState extends State<BuyRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  String _deliveryOption = 'pickup';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = (double.tryParse(widget.product['price'] ?? '0') ?? 0) * widget.quantity;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Buy Request'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppConstants.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderSummary(totalPrice),
              const SizedBox(height: 20),
              _buildContactInfo(),
              const SizedBox(height: 20),
              _buildDeliveryOptions(),
              const SizedBox(height: 20),
              _buildAdditionalMessage(),
              const SizedBox(height: 30),
              _buildSubmitButton(totalPrice),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(double totalPrice) {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.agriculture,
                    color: AppTheme.primaryGreen,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product['productName'] ?? 'Product',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Seller: ${widget.product['sellerName'] ?? 'Unknown'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textGrey,
                        ),
                      ),
                      Text(
                        '₹${widget.product['price']} / ${widget.product['unit'] ?? 'kg'}',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Quantity:', style: Theme.of(context).textTheme.bodyMedium),
                Text('${widget.quantity} ${widget.product['unit'] ?? 'kg'}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Unit Price:', style: Theme.of(context).textTheme.bodyMedium),
                Text('₹${widget.product['price']}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${totalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: Icon(Icons.phone),
                hintText: 'Enter your phone number',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                if (value.trim().length < 10) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                prefixIcon: Icon(Icons.location_on),
                hintText: 'Enter your address (required for delivery)',
              ),
              maxLines: 3,
              validator: (value) {
                if (_deliveryOption == 'delivery' && (value == null || value.trim().isEmpty)) {
                  return 'Address is required for delivery';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryOptions() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RadioListTile(
              title: const Text('Pickup from Seller'),
              subtitle: const Text('Collect directly from seller location'),
              value: 'pickup',
              groupValue: _deliveryOption,
              onChanged: (value) {
                setState(() {
                  _deliveryOption = value!;
                });
              },
              activeColor: AppTheme.primaryGreen,
            ),
            RadioListTile(
              title: const Text('Home Delivery'),
              subtitle: const Text('Get it delivered to your address'),
              value: 'delivery',
              groupValue: _deliveryOption,
              onChanged: (value) {
                setState(() {
                  _deliveryOption = value!;
                });
              },
              activeColor: AppTheme.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalMessage() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Message',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message to Seller (Optional)',
                hintText: 'Any specific requirements or questions...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(double totalPrice) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitBuyRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.send),
        label: Text(
          _isSubmitting ? 'Sending Request...' : 'Send Buy Request',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _submitBuyRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to send buy request')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final buyRequest = {
        'productId': widget.product['key'],
        'productName': widget.product['productName'],
        'sellerId': widget.product['sellerId'],
        'sellerName': widget.product['sellerName'],
        'buyerId': user.uid,
        'buyerName': user.displayName ?? user.email?.split('@')[0] ?? 'Buyer',
        'quantity': widget.quantity,
        'unit': widget.product['unit'],
        'unitPrice': widget.product['price'],
        'totalAmount': (double.tryParse(widget.product['price'] ?? '0') ?? 0) * widget.quantity,
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'deliveryOption': _deliveryOption,
        'message': _messageController.text.trim(),
        'status': 'pending',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Save to buyer's requests
      await FirebaseDatabase.instance
          .ref('buyRequests')
          .child(user.uid)
          .push()
          .set(buyRequest);

      // Save to seller's inbox
      await FirebaseDatabase.instance
          .ref('sellerInbox')
          .child(widget.product['sellerId'] ?? '')
          .push()
          .set(buyRequest);

      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Request Sent Successfully!'),
            content: const Text(
              'Your buy request has been sent to the seller. They will contact you soon.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to product list
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send request: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}