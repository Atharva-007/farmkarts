import 'package:flutter/material.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';

/// Dialog showing buyer profile with rating functionality
class BuyerProfileDialog extends StatefulWidget {
  final String buyerId;
  final Function(double rating, String review) onRateUser;

  const BuyerProfileDialog({
    super.key,
    required this.buyerId,
    required this.onRateUser,
  });

  @override
  State<BuyerProfileDialog> createState() => _BuyerProfileDialogState();
}

class _BuyerProfileDialogState extends State<BuyerProfileDialog> {
  final ChatService _chatService = ChatService();
  final TextEditingController _reviewController = TextEditingController();
  
  Map<String, dynamic>? _buyerDetails;
  bool _isLoading = true;
  bool _showRatingForm = false;
  double _selectedRating = 5.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadBuyerDetails();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadBuyerDetails() async {
    try {
      final details = await _chatService.getBuyerDetails(widget.buyerId);
      setState(() {
        _buyerDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _isLoading
                    ? _buildLoadingState()
                    : _showRatingForm
                        ? _buildRatingForm()
                        : _buildProfileContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              _buyerDetails?['name']?.isNotEmpty == true
                  ? _buyerDetails!['name'][0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _showRatingForm ? 'Rate User' : 'User Profile',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_showRatingForm && _buyerDetails != null)
                  Text(
                    _buyerDetails!['name'] ?? 'Unknown User',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_buyerDetails == null) {
      return _buildErrorState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Info
        _buildUserInfoSection(),
        
        const SizedBox(height: 24),
        
        // Rating Section
        _buildRatingSection(),
        
        const SizedBox(height: 24),
        
        // Action Buttons
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load user profile',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          
          if (_buyerDetails!['email']?.isNotEmpty == true)
            _buildInfoRow(Icons.email, 'Email', _buyerDetails!['email']),
          
          if (_buyerDetails!['phone']?.isNotEmpty == true)
            _buildInfoRow(Icons.phone, 'Phone', _buyerDetails!['phone']),
          
          if (_buyerDetails!['location']?.isNotEmpty == true)
            _buildInfoRow(Icons.location_on, 'Location', _buyerDetails!['location']),
          
          _buildInfoRow(
            Icons.calendar_today,
            'Member Since',
            _formatDate(_buyerDetails!['joinDate']),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    final rating = _buyerDetails!['rating'] ?? 0.0;
    final totalRatings = _buyerDetails!['totalRatings'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Rating',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          
          if (totalRatings > 0) ...[
            Row(
              children: [
                _buildStarRating(rating, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${rating.toStringAsFixed(1)} (${totalRatings} reviews)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'No ratings yet',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showRatingForm = true;
              });
            },
            icon: const Icon(Icons.star),
            label: const Text('Rate This User'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryGreen),
              foregroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Close'),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rate Your Experience',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Star Rating
        const Text(
          'Rating',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1.0;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRating = starValue;
                });
              },
              child: Icon(
                Icons.star,
                size: 36,
                color: starValue <= _selectedRating
                    ? Colors.amber
                    : Colors.grey.shade300,
              ),
            );
          }),
        ),
        
        const SizedBox(height: 8),
        Text(
          _getRatingText(_selectedRating),
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Review Text
        const Text(
          'Review (Optional)',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        
        TextField(
          controller: _reviewController,
          decoration: InputDecoration(
            hintText: 'Share your experience with this user...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
        ),
        
        const SizedBox(height: 24),
        
        // Submit Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _showRatingForm = false;
                  });
                },
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStarRating(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        return Icon(
          starValue <= rating
              ? Icons.star
              : starValue - 0.5 <= rating
                  ? Icons.star_half
                  : Icons.star_border,
          size: size,
          color: Colors.amber,
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getRatingText(double rating) {
    if (rating <= 1) return 'Poor';
    if (rating <= 2) return 'Fair';
    if (rating <= 3) return 'Good';
    if (rating <= 4) return 'Very Good';
    return 'Excellent';
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);

    try {
      await widget.onRateUser(_selectedRating, _reviewController.text.trim());
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit rating: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}