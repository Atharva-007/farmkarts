import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../utils/toast_helper.dart';
import 'package:intl/intl.dart';

/// Production-ready Help & Support Page with Security Features
class HelpAndSupportPage extends StatefulWidget {
  const HelpAndSupportPage({super.key});

  @override
  State<HelpAndSupportPage> createState() => _HelpAndSupportPageState();
}

class _HelpAndSupportPageState extends State<HelpAndSupportPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  
  bool _isSubmitting = false;
  String _selectedCategory = 'General';

  final List<String> _categories = [
    'General',
    'Account Issues',
    'Payment Problems',
    'Order Issues',
    'Technical Support',
    'Feature Request',
    'Report Abuse',
    'Security Concern',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'FAQ'),
            Tab(text: 'Contact Us'),
            Tab(text: 'My Tickets'),
            Tab(text: 'Resources'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFAQTab(),
          _buildContactUsTab(),
          _buildMyTicketsTab(),
          _buildResourcesTab(),
        ],
      ),
    );
  }

  // FAQ Tab
  Widget _buildFAQTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Getting Started'),
        _buildFAQItem(
          'How do I create an account?',
          'Tap on "Sign Up" on the login page, fill in your details, and verify your email address.',
        ),
        _buildFAQItem(
          'How do I list a product?',
          'Go to the Marketplace, tap the "+" button, fill in product details, add photos, and submit.',
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Account & Security'),
        _buildFAQItem(
          'How do I reset my password?',
          'Tap "Forgot Password" on the login page and follow the email instructions.',
        ),
        _buildFAQItem(
          'Is my payment information secure?',
          'Yes! We use industry-standard encryption (AES-256) and never store your full card details.',
        ),
        _buildFAQItem(
          'How do I enable two-factor authentication?',
          'Go to Settings > Security > Enable 2FA and follow the setup process.',
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Orders & Payments'),
        _buildFAQItem(
          'How can I track my order?',
          'Go to My Orders, select your order, and view real-time tracking updates.',
        ),
        _buildFAQItem(
          'What payment methods are accepted?',
          'We accept UPI, Credit/Debit Cards, Net Banking, and Cash on Delivery.',
        ),
        _buildFAQItem(
          'How do refunds work?',
          'Refunds are processed within 5-7 business days to your original payment method.',
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Technical Issues'),
        _buildFAQItem(
          'The app is crashing. What should I do?',
          '1. Update to the latest version\n2. Clear app cache\n3. Restart your device\n4. Contact support if issue persists.',
        ),
        _buildFAQItem(
          'I can\'t upload images',
          'Check your internet connection and ensure you\'ve granted camera/storage permissions.',
        ),
      ],
    );
  }

  // Contact Us Tab
  Widget _buildContactUsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickContactCards(),
          const SizedBox(height: 24),
          const Text(
            'Submit a Support Ticket',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactForm(),
        ],
      ),
    );
  }

  Widget _buildQuickContactCards() {
    return Column(
      children: [
        _buildQuickContactCard(
          icon: Icons.phone,
          title: 'Call Us',
          subtitle: '+91 1800-123-4567',
          color: Colors.blue,
          onTap: () => _makePhoneCall('+911800123456 7'),
        ),
        const SizedBox(height: 12),
        _buildQuickContactCard(
          icon: Icons.email,
          title: 'Email Us',
          subtitle: 'support@farmkarts.com',
          color: Colors.orange,
          onTap: () => _sendEmail('support@farmkarts.com'),
        ),
        const SizedBox(height: 12),
        _buildQuickContactCard(
          icon: Icons.chat,
          title: 'Live Chat',
          subtitle: 'Available 24/7',
          color: Colors.green,
          onTap: () => _openLiveChat(),
        ),
        const SizedBox(height: 12),
        _buildQuickContactCard(
          icon: Icons.business,
          title: 'Visit Office',
          subtitle: 'Bangalore, Karnataka',
          color: Colors.purple,
          onTap: () => _openMap(),
        ),
      ],
    );
  }

  Widget _buildQuickContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedCategory = value!);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _subjectController,
          decoration: InputDecoration(
            labelText: 'Subject',
            hintText: 'Brief description of your issue',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _messageController,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: 'Message',
            hintText: 'Describe your issue in detail...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitSupportTicket,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Submit Ticket',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'We typically respond within 24 hours',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // My Tickets Tab
  Widget _buildMyTicketsTab() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text('Please log in to view tickets'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('support_tickets')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final tickets = snapshot.data?.docs ?? [];

        if (tickets.isEmpty) {
          return _buildEmptyTicketsState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh handled by StreamBuilder
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index].data() as Map<String, dynamic>;
              return _buildTicketCard(ticket);
            },
          ),
        );
      },
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final status = ticket['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final createdAt = (ticket['createdAt'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showTicketDetails(ticket),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket['subject'] ?? 'No Subject',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket['category'] ?? 'General',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ticket['message'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    createdAt != null
                        ? DateFormat('MMM dd, yyyy - hh:mm a').format(createdAt)
                        : 'Unknown',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Ticket #${ticket['ticketId'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Resources Tab
  Widget _buildResourcesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildResourceCard(
          title: 'Video Tutorials',
          description: 'Learn through step-by-step video guides',
          icon: Icons.video_library,
          color: Colors.red,
          onTap: () => _openVideoTutorials(),
        ),
        _buildResourceCard(
          title: 'User Guide (PDF)',
          description: 'Download comprehensive user manual',
          icon: Icons.picture_as_pdf,
          color: Colors.orange,
          onTap: () => _downloadUserGuide(),
        ),
        _buildResourceCard(
          title: 'Community Forum',
          description: 'Connect with other users',
          icon: Icons.forum,
          color: Colors.blue,
          onTap: () => _openCommunityForum(),
        ),
        _buildResourceCard(
          title: 'Best Practices',
          description: 'Tips for successful selling',
          icon: Icons.lightbulb,
          color: Colors.yellow.shade700,
          onTap: () => _showBestPractices(),
        ),
        _buildResourceCard(
          title: 'Terms & Conditions',
          description: 'Read our terms of service',
          icon: Icons.description,
          color: Colors.purple,
          onTap: () => _showTermsAndConditions(),
        ),
        _buildResourceCard(
          title: 'Privacy Policy',
          description: 'How we protect your data',
          icon: Icons.privacy_tip,
          color: Colors.teal,
          onTap: () => _showPrivacyPolicy(),
        ),
        const SizedBox(height: 24),
        _buildSecuritySection(),
      ],
    );
  }

  Widget _buildResourceCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Security & Trust',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSecurityFeature(
          icon: Icons.verified_user,
          title: 'Verified Accounts',
          description: 'All sellers go through verification',
        ),
        _buildSecurityFeature(
          icon: Icons.lock,
          title: 'Secure Payments',
          description: 'AES-256 encryption for all transactions',
        ),
        _buildSecurityFeature(
          icon: Icons.shield,
          title: 'Buyer Protection',
          description: '100% refund guarantee on eligible orders',
        ),
        _buildSecurityFeature(
          icon: Icons.privacy_tip,
          title: 'Data Privacy',
          description: 'GDPR & ISO 27001 compliant',
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryGreen.withOpacity(0.1),
                AppTheme.primaryGreen.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.security,
                size: 48,
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(height: 12),
              const Text(
                'Report Security Issue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Found a security vulnerability? Let us know immediately.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _reportSecurityIssue(),
                icon: const Icon(Icons.report),
                label: const Text('Report Issue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTicketsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.support_agent, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No support tickets yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a ticket if you need help',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _tabController.animateTo(1),
            icon: const Icon(Icons.add),
            label: const Text('Create Ticket'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showTicketDetails(Map<String, dynamic> ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket['subject'] ?? 'Ticket Details',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ticket['status'] ?? 'pending')
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(ticket['status'] ?? 'pending'),
                      ),
                    ),
                    child: Text(
                      (ticket['status'] ?? 'pending').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(ticket['status'] ?? 'pending'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Ticket #${ticket['ticketId'] ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ticket['category'] ?? 'General',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Message',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ticket['message'] ?? '',
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
              if (ticket['response'] != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.support_agent, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Support Response',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ticket['response'],
                        style: const TextStyle(fontSize: 14, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitSupportTicket() async {
    if (_subjectController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ToastHelper.showError(context, 'Please fill in all fields');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final ticketId = 'TKT${DateTime.now().millisecondsSinceEpoch}';

      await _firestore.collection('support_tickets').add({
        'ticketId': ticketId,
        'userId': userId,
        'userEmail': _auth.currentUser?.email,
        'category': _selectedCategory,
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ToastHelper.showSuccess(
          context,
          'Ticket submitted successfully! Ticket #$ticketId',
        );
        _subjectController.clear();
        _messageController.clear();
        _tabController.animateTo(2); // Switch to My Tickets tab
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Failed to submit ticket: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ToastHelper.showError(context, 'Cannot make phone call');
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email?subject=Support Request');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ToastHelper.showError(context, 'Cannot open email client');
      }
    }
  }

  void _openLiveChat() {
    ToastHelper.showInfo(context, 'Live chat opening soon');
  }

  void _openMap() {
    ToastHelper.showInfo(context, 'Opening map');
  }

  void _openVideoTutorials() {
    ToastHelper.showInfo(context, 'Opening video tutorials');
  }

  void _downloadUserGuide() {
    ToastHelper.showInfo(context, 'Downloading user guide');
  }

  void _openCommunityForum() {
    ToastHelper.showInfo(context, 'Opening community forum');
  }

  void _showBestPractices() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Best Practices for Selling'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Use high-quality product photos'),
              SizedBox(height: 8),
              Text('2. Write detailed descriptions'),
              SizedBox(height: 8),
              Text('3. Price competitively'),
              SizedBox(height: 8),
              Text('4. Respond to inquiries promptly'),
              SizedBox(height: 8),
              Text('5. Maintain accurate inventory'),
              SizedBox(height: 8),
              Text('6. Package items securely'),
              SizedBox(height: 8),
              Text('7. Ship orders on time'),
              SizedBox(height: 8),
              Text('8. Collect customer feedback'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsAndConditions() {
    ToastHelper.showInfo(context, 'Opening Terms & Conditions');
  }

  void _showPrivacyPolicy() {
    ToastHelper.showInfo(context, 'Opening Privacy Policy');
  }

  void _reportSecurityIssue() {
    setState(() {
      _selectedCategory = 'Security Concern';
      _tabController.animateTo(1);
    });
    ToastHelper.showInfo(context, 'Please describe the security issue');
  }
}
