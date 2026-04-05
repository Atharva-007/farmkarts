import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/universal_header.dart';

class HelpAndSupportPage extends StatefulWidget {
  const HelpAndSupportPage({super.key});

  @override
  State<HelpAndSupportPage> createState() => _HelpAndSupportPageState();
}

class _HelpAndSupportPageState extends State<HelpAndSupportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  final bool _isSubmitting = false;
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
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          UniversalHeader(
            title: 'Help & Support',
            subtitle: 'We\'re here to help',
            icon: Icons.support_agent_rounded,
            showBackButton: true,
            showProfile: true,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              isScrollable: true,
              tabs: const [
                Tab(text: 'FAQ'),
                Tab(text: 'Contact Us'),
                Tab(text: 'My Tickets'),
                Tab(text: 'Resources'),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFAQTab(),
                _buildContactTab(),
                _buildTicketsTab(),
                _buildResourcesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFAQItem('How to list a product?',
            'Go to the Marketplace tab and click the "+" button or "Sell" button on the dashboard.'),
        _buildFAQItem('Is my payment secure?',
            'Yes, we use industry-standard encrypted payment gateways like Razorpay and UPI.'),
        _buildFAQItem('How to contact a seller?',
            'You can chat with sellers directly through the product page inquiry button.'),
        _buildFAQItem('What is AI Expert?',
            'AI Expert is our intelligent assistant that helps you with farming advice, weather, and crop diseases.'),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title:
            Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Need more help?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Fill out the form below and we will get back to you soon.',
              style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
          const SizedBox(height: 24),
          _buildContactForm(),
        ],
      ),
    );
  }

  Widget _buildContactForm() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(
              labelText: 'Category', border: OutlineInputBorder()),
          items: _categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _subjectController,
          decoration: const InputDecoration(
              labelText: 'Subject', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _messageController,
          maxLines: 5,
          decoration: const InputDecoration(
              labelText: 'Message', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitTicket,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('SUBMIT TICKET'),
          ),
        ),
      ],
    );
  }

  Future<void> _submitTicket() async {
    // Implementation
  }

  Widget _buildTicketsTab() {
    return const Center(child: Text('Your support tickets will appear here'));
  }

  Widget _buildResourcesTab() {
    return const Center(
        child: Text('Helpful resources and guides coming soon'));
  }
}
