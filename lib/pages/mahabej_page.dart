import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MahabejPage extends StatelessWidget {
  const MahabejPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mahabej'),
        backgroundColor: AppTheme.getAppBarColor(context),
        foregroundColor: AppTheme.getAppBarTextColor(context),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildElementTile(
              context, 'Mahabej Element 1', 'Description for Element 1'),
          _buildElementTile(
              context, 'Mahabej Element 2', 'Description for Element 2'),
          _buildElementTile(
              context, 'Mahabej Element 3', 'Description for Element 3'),
          // Add more elements as needed
        ],
      ),
    );
  }

  Widget _buildElementTile(
      BuildContext context, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.getIconBackgroundColor(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.grass, color: AppTheme.getPrimaryAccent(context)),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
        ),
        onTap: () {},
      ),
    );
  }
}
