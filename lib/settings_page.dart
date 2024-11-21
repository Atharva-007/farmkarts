import 'package:flutter/material.dart';
import 'login_page.dart'; // Import the LoginPage

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text('Account Settings'),
              leading: const Icon(Icons.account_circle),
              onTap: () {
                // Handle account settings
              },
            ),
            ListTile(
              title: const Text('Notification Settings'),
              leading: const Icon(Icons.notifications),
              onTap: () {
                // Handle notification settings
              },
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Handle logout logic
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false, // Remove all previous routes
                  );
                },
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
