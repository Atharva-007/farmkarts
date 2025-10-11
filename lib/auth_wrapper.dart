import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import 'main_app_layout.dart';
import 'services/user_state_service.dart';
import 'widgets/connection_status_widget.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ConnectionStatusWidget(
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Initializing...'),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            // User is logged in, initialize user state
            return FutureBuilder(
              future: _initializeUserState(context, snapshot.data!.uid),
              builder: (context, futureSnapshot) {
                return Consumer<UserStateService>(
                  builder: (context, userState, child) {
                    if (userState.isLoading) {
                      return const Scaffold(
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading your profile...'),
                            ],
                          ),
                        ),
                      );
                    }

                    if (userState.error != null && !userState.isOnline) {
                      return _buildOfflineScreen(context, userState);
                    }

                    if (userState.error != null) {
                      return _buildErrorScreen(context, userState);
                    }

                    if (userState.currentUser != null) {
                      return const MainAppLayout();
                    }

                    // Fallback to login if something went wrong
                    return const LoginPage();
                  },
                );
              },
            );
          } else {
            // User is not logged in
            return const LoginPage();
          }
        },
      ),
    );
  }

  Future<void> _initializeUserState(BuildContext context, String uid) async {
    final userStateService = Provider.of<UserStateService>(context, listen: false);
    await userStateService.setCurrentUser(uid);
  }

  Widget _buildOfflineScreen(BuildContext context, UserStateService userState) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              const Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  userState.clearError();
                  userState.retryLoadUser();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, UserStateService userState) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 24),
              const Text(
                'Connection Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                userState.error ?? 'An unknown error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      userState.clearError();
                      userState.retryLoadUser();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () {
                      userState.clearUser();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Need Help?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('If you\'re seeing this error:'),
                      const SizedBox(height: 8),
                      const Text('• Make sure you have an internet connection'),
                      const Text('• Check if Firestore is set up in Firebase Console'),
                      const Text('• Contact support if the problem persists'),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          // You can add a help/support navigation here
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please contact support for assistance'),
                            ),
                          );
                        },
                        child: const Text('Contact Support'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}