// Buyer Interests Page
// Shows all buyers who have shown interest in a specific product

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/marketplace_models.dart';
import '../../services/enhanced_marketplace_service.dart';

class BuyerInterestsPage extends StatefulWidget {
  final String productId;

  const BuyerInterestsPage({
    super.key,
    required this.productId,
  });

  @override
  State<BuyerInterestsPage> createState() => _BuyerInterestsPageState();
}

class _BuyerInterestsPageState extends State<BuyerInterestsPage> {
  final EnhancedMarketplaceService _marketplaceService =
      EnhancedMarketplaceService();

  List<BuyerInterest> _interests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInterests();
  }

  Future<void> _loadInterests() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final interests =
          await _marketplaceService.getProductInterests(widget.productId);
      if (mounted) {
        setState(() {
          _interests = interests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Interested Buyers',
          style: TextStyle(
            color: AppTheme.getAppBarTextColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.getAppBarColor(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.getAppBarTextColor(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInterests,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(
              color: AppTheme.getPrimaryAccent(context)));
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_interests.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadInterests,
      color: AppTheme.getPrimaryAccent(context),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _interests.length,
        itemBuilder: (context, index) {
          return _buildInterestCard(_interests[index]);
        },
      ),
    );
  }

  Widget _buildInterestCard(BuyerInterest interest) {
    final statusColor = _getStatusColor(interest.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isDark ? 0 : 2,
      color: AppTheme.getCardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with buyer name and status
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      AppTheme.getPrimaryAccent(context).withValues(alpha: 0.1),
                  child: Text(
                    interest.buyerName.isNotEmpty
                        ? interest.buyerName[0].toUpperCase()
                        : 'B',
                    style: TextStyle(
                      color: AppTheme.getPrimaryAccent(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        interest.buyerName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      Text(
                        interest.buyerEmail,
                        style: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    interest.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Interest details
            if (interest.message.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.getBorderColor(context)
                          .withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      interest.message,
                      style: TextStyle(
                          fontSize: 14, color: AppTheme.getTextColor(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Quantity and preferences
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Quantity',
                    value: '${interest.interestedQuantity} units',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    icon: _getContactIcon(interest.contactPreference),
                    label: 'Contact',
                    value: interest.contactPreference,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Timestamp
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14,
                    color: AppTheme.getSecondaryTextColor(context)
                        .withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Text(
                  'Interested ${_formatDateTime(interest.createdAt)}',
                  style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context)
                        .withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactBuyer(interest),
                    icon: Icon(_getContactIcon(interest.contactPreference),
                        size: 18),
                    label: Text(
                        'Contact ${interest.contactPreference == 'email' ? 'Email' : 'Phone'}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.getPrimaryAccent(context),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side:
                          BorderSide(color: AppTheme.getPrimaryAccent(context)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _viewBuyerDetails(interest),
                  icon: const Icon(Icons.person_search_rounded, size: 18),
                  label: const Text('Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.getPrimaryAccent(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.getErrorColor(context).withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            const Text(
              'Error loading interests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInterests,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.getPrimaryAccent(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 80,
              color: AppTheme.getSecondaryTextColor(context)
                  .withValues(alpha: 0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'No interested buyers yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'When buyers show interest in your product, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'contacted':
        return Colors.blue;
      case 'converted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getContactIcon(String contactPreference) {
    switch (contactPreference.toLowerCase()) {
      case 'email':
        return Icons.email_outlined;
      case 'phone':
        return Icons.phone_outlined;
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.contact_mail_outlined;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _contactBuyer(BuyerInterest interest) async {
    try {
      if (interest.contactPreference == 'email') {
        final Uri emailUri = Uri(
          scheme: 'mailto',
          path: interest.buyerEmail,
          queryParameters: {
            'subject': 'Regarding your interest in my product',
            'body':
                'Hi ${interest.buyerName},\n\nI received your inquiry about my product. I would like to discuss further.\n\nBest regards',
          },
        );

        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
        } else {
          _showErrorSnackBar('Could not launch email client');
        }
      } else {
        _showInfoDialog(
          'Contact Information',
          'Contact ${interest.buyerName} via ${interest.contactPreference}:\n${interest.buyerEmail}',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to contact buyer: $e');
    }
  }

  void _viewBuyerDetails(BuyerInterest interest) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBuyerDetailsBottomSheet(interest),
    );
  }

  Widget _buildBuyerDetailsBottomSheet(BuyerInterest interest) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Buyer Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Name', interest.buyerName),
            _buildDetailRow('Email', interest.buyerEmail),
            _buildDetailRow('Quantity', '${interest.interestedQuantity} units'),
            _buildDetailRow('Preference', interest.contactPreference),
            _buildDetailRow('Status', interest.status),
            _buildDetailRow('Date', _formatDateTime(interest.createdAt)),
            if (interest.message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Message:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.getBorderColor(context)
                          .withValues(alpha: 0.3)),
                ),
                child: Text(interest.message,
                    style: TextStyle(color: AppTheme.getTextColor(context))),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _contactBuyer(interest);
                },
                icon: Icon(_getContactIcon(interest.contactPreference)),
                label: const Text('Contact Buyer',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getPrimaryAccent(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.getTextColor(context),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.getErrorColor(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontWeight: FontWeight.bold)),
        content: Text(message,
            style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
