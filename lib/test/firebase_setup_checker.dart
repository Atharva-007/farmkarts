import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseSetupChecker extends StatefulWidget {
  const FirebaseSetupChecker({super.key});

  @override
  State<FirebaseSetupChecker> createState() => _FirebaseSetupCheckerState();
}

class _FirebaseSetupCheckerState extends State<FirebaseSetupChecker> {
  Map<String, bool> _checks = {};
  List<String> _errors = [];
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _runChecks();
  }

  Future<void> _runChecks() async {
    setState(() {
      _isChecking = true;
      _checks.clear();
      _errors.clear();
    });

    // Check Firebase Core
    try {
      await Firebase.initializeApp();
      _checks['Firebase Core'] = true;
    } catch (e) {
      _checks['Firebase Core'] = false;
      _errors.add('Firebase Core: $e');
    }

    // Check Firebase Auth
    try {
      FirebaseAuth.instance.currentUser;
      _checks['Firebase Auth'] = true;
    } catch (e) {
      _checks['Firebase Auth'] = false;
      _errors.add('Firebase Auth: $e');
    }

    // Check Firestore
    try {
      await FirebaseFirestore.instance.settings;
      await FirebaseFirestore.instance.enableNetwork();
      _checks['Firestore Database'] = true;
    } catch (e) {
      _checks['Firestore Database'] = false;
      _errors.add('Firestore Database: $e');
    }

    // Check Firebase Storage
    try {
      await FirebaseStorage.instance.ref().listAll();
      _checks['Firebase Storage'] = true;
    } catch (e) {
      _checks['Firebase Storage'] = false;
      _errors.add('Firebase Storage: $e');
    }

    // Test Firestore connectivity
    try {
      await FirebaseFirestore.instance
          .collection('_test')
          .doc('connection')
          .get()
          .timeout(const Duration(seconds: 10));
      _checks['Firestore Connectivity'] = true;
    } catch (e) {
      _checks['Firestore Connectivity'] = false;
      _errors.add('Firestore Connectivity: $e');
    }

    setState(() {
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Setup Checker'),
        actions: [
          IconButton(
            onPressed: _runChecks,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isChecking)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Checking Firebase setup...'),
                  ],
                ),
              )
            else ...[
              const Text(
                'Firebase Components Status:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Status checks
              ..._checks.entries.map((entry) => Card(
                child: ListTile(
                  leading: Icon(
                    entry.value ? Icons.check_circle : Icons.error,
                    color: entry.value ? Colors.green : Colors.red,
                  ),
                  title: Text(entry.key),
                  subtitle: Text(
                    entry.value ? 'Working correctly' : 'Not configured or error',
                  ),
                ),
              )),
              
              const SizedBox(height: 20),
              
              // Errors section
              if (_errors.isNotEmpty) ...[
                const Text(
                  'Errors Found:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                ...(_errors.map((error) => Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ))),
                const SizedBox(height: 20),
              ],
              
              // Recommendations
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Setup Recommendations:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!(_checks['Firestore Database'] ?? false))
                        const Text('• Enable Firestore Database in Firebase Console'),
                      if (!(_checks['Firebase Storage'] ?? false))
                        const Text('• Enable Firebase Storage in Firebase Console'),
                      if (!(_checks['Firestore Connectivity'] ?? false))
                        const Text('• Check internet connection and Firestore rules'),
                      const Text('• Ensure you\'re using the correct Firebase project'),
                      const Text('• Check Firebase security rules allow authenticated access'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _runChecks,
                      child: const Text('Re-check Setup'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}