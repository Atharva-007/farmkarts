import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../models/user_model.dart';
import 'auth_service.dart';

class UserStateService extends ChangeNotifier {
  static final UserStateService _instance = UserStateService._internal();
  factory UserStateService() => _instance;
  UserStateService._internal() {
    _initializeConnectivityListener();
  }

  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isOnline = true;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  StreamSubscription? _connectivitySubscription;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  UserRole? get userRole => _currentUser?.role;
  bool get isFarmer => _currentUser?.role == UserRole.farmer;
  bool get isAddat => _currentUser?.role == UserRole.addat;
  bool get isOnline => _isOnline;

  void _initializeConnectivityListener() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((dynamic result) {
      final wasOnline = _isOnline;

      bool isNowOnline = false;
      if (result is List) {
        isNowOnline = !result.contains(ConnectivityResult.none);
      } else {
        isNowOnline = result != ConnectivityResult.none;
      }

      _isOnline = isNowOnline;

      if (!wasOnline && _isOnline) {
        // print('UserStateService: Connection restored');
        if (_currentUser == null && _authService.currentUser != null) {
          // print('UserStateService: Attempting to load user profile after reconnection');
          setCurrentUser(_authService.currentUser!.uid);
        }
      }

      notifyListeners();
    });
  }

  // Initialize user state on app start
  Future<void> initializeUser() async {
    _setLoading(true);
    _retryCount = 0;
    _error = null;

    try {
      final currentUser = await _authService.getCurrentUserModel();
      _currentUser = currentUser;
      _error = null;
      _retryCount = 0;
      // print('UserStateService: User initialized successfully');
    } catch (e) {
      await _handleError(e, () => initializeUser());
    }
    _setLoading(false);
  }

  // Set current user after login/signup
  Future<void> setCurrentUser(String uid) async {
    _setLoading(true);
    _retryCount = 0;
    _error = null;

    try {
      // print('UserStateService: Loading user profile for UID: $uid');

      final userModel = await _authService.getUserProfile(uid);

      if (userModel != null) {
        _currentUser = userModel;
        _error = null;
        _retryCount = 0;
        // print('UserStateService: User profile loaded successfully - ${userModel.fullName} (${userModel.role})');
      } else {
        _error =
            'User profile not found in database. Please try registering again.';
        _currentUser = null;
        // print('UserStateService: User profile not found for UID: $uid');
      }
    } catch (e) {
      await _handleError(e, () => setCurrentUser(uid));
    }
    _setLoading(false);
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel updatedUser) async {
    _setLoading(true);
    try {
      await _authService.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
      _error = null;
      // print('UserStateService: User profile updated successfully');
    } catch (e) {
      await _handleError(e, () => updateUserProfile(updatedUser));
    }
    _setLoading(false);
  }

  // Clear user state on logout
  Future<void> clearUser() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
      _error = null;
      _retryCount = 0;
      // print('UserStateService: User cleared successfully');
    } catch (e) {
      // print('UserStateService: Error clearing user: $e');
      _currentUser = null;
      _error = null;
    }
    _setLoading(false);
  }

  // Retry loading user profile manually
  Future<void> retryLoadUser() async {
    _error = null;
    _retryCount = 0;
    if (_authService.currentUser != null) {
      await setCurrentUser(_authService.currentUser!.uid);
    } else {
      await initializeUser();
    }
  }

  Future<void> _handleError(
      dynamic error, Future<void> Function() retryFunction) async {
    final errorString = error.toString().toLowerCase();
    // print('UserStateService: Error occurred: $errorString');

    bool isNetworkError = errorString.contains('unavailable') ||
        errorString.contains('offline') ||
        errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('deadline-exceeded');

    if (isNetworkError) {
      if (_retryCount < _maxRetries) {
        _retryCount++;
        final waitSeconds =
            _retryCount * _retryCount; // Exponential: 1, 4, 9 seconds
        // print('UserStateService: Network error. Retrying in $waitSeconds seconds... attempt $_retryCount/$_maxRetries');

        await Future.delayed(Duration(seconds: waitSeconds));

        try {
          await retryFunction();
          return;
        } catch (retryError) {
          if (_retryCount >= _maxRetries) {
            _error =
                'Unable to connect to FarmKarts. Please check your internet connection and try again.';
          }
          return;
        }
      } else {
        _error =
            'Connection persistent failure. Please check your network and tap Retry.';
      }
    } else if (errorString.contains('permission-denied')) {
      _error =
          'Access denied. Please contact support or check your account status.';
    } else if (errorString.contains('not-found') ||
        errorString.contains('not found')) {
      _error =
          'User profile could not be found. You may need to sign up again.';
    } else {
      _error =
          'An unexpected error occurred: ${error.toString().split(':').last.trim()}';
    }

    _currentUser = null;
  }

  // Get farmer specific data
  FarmerModel? get farmerProfile {
    if (_currentUser is FarmerModel) {
      return _currentUser as FarmerModel;
    }
    return null;
  }

  // Get addat specific data
  AddatModel? get addatProfile {
    if (_currentUser is AddatModel) {
      return _currentUser as AddatModel;
    }
    return null;
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void clearError() {
    _error = null;
    _retryCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
