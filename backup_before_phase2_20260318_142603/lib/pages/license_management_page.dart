import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/universal_header.dart';
import '../widgets/universal_drawer.dart';

class LicenseManagementPage extends StatefulWidget {
  const LicenseManagementPage({super.key});

  @override
  State<LicenseManagementPage> createState() => _LicenseManagementPageState();
}

class _LicenseManagementPageState extends State<LicenseManagementPage> {
  final List<LicenseItem> _licenses = [
    LicenseItem(
      name: 'Organic Farming Certificate',
      issueDate: DateTime(2024, 1, 15),
      expiryDate: DateTime(2026, 1, 15),
      status: 'Active',
      licenseNumber: 'OF-2024-1234',
    ),
    LicenseItem(
      name: 'Pesticide Application License',
      issueDate: DateTime(2023, 6, 10),
      expiryDate: DateTime(2025, 6, 10),
      status: 'Active',
      licenseNumber: 'PA-2023-5678',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      drawer: const UniversalDrawer(currentPage: 'license'),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const UniversalHeader(
            title: 'License Management',
            subtitle: 'Manage your farming licenses',
            icon: Icons.card_membership,
          ),
        ],
        body: _buildContent(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'license_management_fab',
        onPressed: _addLicense,
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add),
        label: const Text('Add License'),
      ),
    );
  }

  Widget _buildContent() {
    if (_licenses.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _licenses.length,
      itemBuilder: (context, index) {
        return _buildLicenseCard(_licenses[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_membership_outlined,
            size: 120,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No licenses added',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add your farming licenses to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseCard(LicenseItem license) {
    final daysUntilExpiry = license.expiryDate.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysUntilExpiry < 30 && daysUntilExpiry > 0;
    final isExpired = daysUntilExpiry < 0;

    Color statusColor;
    IconData statusIcon;
    if (isExpired) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else if (isExpiringSoon) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    license.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isExpired
                        ? 'Expired'
                        : isExpiringSoon
                            ? 'Expiring Soon'
                            : 'Active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  Icons.numbers,
                  'License Number',
                  license.licenseNumber,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Issue Date',
                  _formatDate(license.issueDate),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.event,
                  'Expiry Date',
                  _formatDate(license.expiryDate),
                ),
                if (daysUntilExpiry >= 0) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.access_time,
                    'Days Until Expiry',
                    '$daysUntilExpiry days',
                  ),
                ],
              ],
            ),
          ),
          // Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _viewLicense(license),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _renewLicense(license),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Renew'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _addLicense() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add license feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewLicense(LicenseItem license) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(license.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('License Number: ${license.licenseNumber}'),
            const SizedBox(height: 8),
            Text('Issued: ${_formatDate(license.issueDate)}'),
            Text('Expires: ${_formatDate(license.expiryDate)}'),
            Text('Status: ${license.status}'),
          ],
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

  void _renewLicense(LicenseItem license) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Renew license: ${license.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class LicenseItem {
  final String name;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String status;
  final String licenseNumber;

  LicenseItem({
    required this.name,
    required this.issueDate,
    required this.expiryDate,
    required this.status,
    required this.licenseNumber,
  });
}
