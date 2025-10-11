import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthTestWidget extends StatefulWidget {
  const AuthTestWidget({super.key});

  @override
  State<AuthTestWidget> createState() => _AuthTestWidgetState();
}

class _AuthTestWidgetState extends State<AuthTestWidget> {
  final AuthService _authService = AuthService();
  String _testResults = '';

  Future<void> _runTests() async {
    setState(() {
      _testResults = 'Running authentication tests...\n';
    });

    try {
      // Test 1: Farmer Signup
      await _testFarmerSignup();
      
      // Test 2: Addat Signup (without image for simplicity)
      await _testAddatSignup();
      
      setState(() {
        _testResults += '\n✅ All tests completed successfully!';
      });
    } catch (e) {
      setState(() {
        _testResults += '\n❌ Test failed: $e';
      });
    }
  }

  Future<void> _testFarmerSignup() async {
    setState(() {
      _testResults += '\n🧪 Testing Farmer Signup...';
    });

    try {
      final testEmail = 'farmer.test.${DateTime.now().millisecondsSinceEpoch}@farmkarts.com';
      
      final userCredential = await _authService.signUpWithEmailAndPassword(
        email: testEmail,
        password: 'test123456',
        role: UserRole.farmer,
        fullName: 'Test Farmer',
        mobileNo: '1234567890',
        acresLand: 5.5,
      );

      if (userCredential?.user != null) {
        // Verify user profile was created
        final profile = await _authService.getUserProfile(userCredential!.user!.uid);
        if (profile is FarmerModel && profile.acresLand == 5.5) {
          setState(() {
            _testResults += '\n✅ Farmer signup successful';
          });
          
          // Clean up test user
          await userCredential.user!.delete();
        } else {
          throw Exception('Farmer profile not created correctly');
        }
      } else {
        throw Exception('User credential is null');
      }
    } catch (e) {
      setState(() {
        _testResults += '\n❌ Farmer signup failed: $e';
      });
      rethrow;
    }
  }

  Future<void> _testAddatSignup() async {
    setState(() {
      _testResults += '\n🧪 Testing Addat Signup...';
    });

    try {
      final testEmail = 'addat.test.${DateTime.now().millisecondsSinceEpoch}@farmkarts.com';
      
      final userCredential = await _authService.signUpWithEmailAndPassword(
        email: testEmail,
        password: 'test123456',
        role: UserRole.addat,
        fullName: 'Test Addat',
        mobileNo: '0987654321',
        dukanName: 'Test Shop',
      );

      if (userCredential?.user != null) {
        // Verify user profile was created
        final profile = await _authService.getUserProfile(userCredential!.user!.uid);
        if (profile is AddatModel && profile.dukanName == 'Test Shop') {
          setState(() {
            _testResults += '\n✅ Addat signup successful';
          });
          
          // Clean up test user
          await userCredential.user!.delete();
        } else {
          throw Exception('Addat profile not created correctly');
        }
      } else {
        throw Exception('User credential is null');
      }
    } catch (e) {
      setState(() {
        _testResults += '\n❌ Addat signup failed: $e';
      });
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _runTests,
              child: const Text('Run Authentication Tests'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _testResults.isEmpty ? 'Click the button to run tests' : _testResults,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}