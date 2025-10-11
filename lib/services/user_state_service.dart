import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  UserRole? get userRole => _currentUser?.role;
  bool get isFarmer => _currentUser?.role == UserRole.farmer;
  bool get isAddat => _currentUser?.role == UserRole.addat;
  bool get isOnline => _isOnline;

  void _initializeConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (!wasOnline && _isOnline && _currentUser == null && _authService.currentUser != null) {
        // Reconnected and we have an authenticated user but no profile
        print('UserStateService: Reconnected - attempting to load user profile');
        setCurrentUser(_authService.currentUser!.uid);
      }
      
      notifyListeners();
    });
  }

  // Initialize user state on app start
  Future<void> initializeUser() async {
    _setLoading(true);
    _retryCount = 0;
    
    try {
      await _checkConnectivity();
      final currentUser = await _authService.getCurrentUserModel();
      _currentUser = currentUser;
      _error = null;
      _retryCount = 0;
      print('UserStateService: User initialized successfully');
    } catch (e) {
      await _handleError(e, () => initializeUser());
    }
    _setLoading(false);
  }

  // Set current user after login/signup
  Future<void> setCurrentUser(String uid) async {
    _setLoading(true);
    _retryCount = 0;
    
    try {
      print('UserStateService: Loading user profile for UID: $uid');
      
      await _checkConnectivity();
      final userModel = await _authService.getUserProfile(uid);
      
      if (userModel != null) {
        _currentUser = userModel;
        _error = null;
        _retryCount = 0;
        print('UserStateService: User profile loaded successfully - ${userModel.fullName} (${userModel.role})');
      } else {
        _error = 'User profile not found in database. Please try registering again.';
        _currentUser = null;
        print('UserStateService: User profile not found for UID: $uid');
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
      await _checkConnectivity();
      await _authService.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
      _error = null;
      print('UserStateService: User profile updated successfully');
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
      print('UserStateService: User cleared successfully');
    } catch (e) {
      print('UserStateService: Error clearing user: $e');
      _error = e.toString();
    }
    _setLoading(false);
  }

  // Retry loading user profile manually
  Future<void> retryLoadUser() async {
    if (_authService.currentUser != null) {
      _error = null;
      await setCurrentUser(_authService.currentUser!.uid);
    }
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;
    
    if (!_isOnline) {
      throw Exception('No internet connection. Please check your network settings.');
    }
  }

  Future<void> _handleError(dynamic error, Future<void> Function() retryFunction) async {
    final errorString = error.toString();
    print('UserStateService: Error occurred: $errorString');

    if (errorString.contains('unavailable') || 
        errorString.contains('offline') ||
        errorString.contains('network-request-failed')) {
      
      if (_retryCount < _maxRetries) {
        _retryCount++;
        print('UserStateService: Retrying... attempt $_retryCount/$_maxRetries');
        
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: _retryCount * 2));
        
        try {
          await retryFunction();
          return; // Success, exit error handling
        } catch (retryError) {
          if (_retryCount >= _maxRetries) {
            _error = 'Connection failed after $_maxRetries attempts. Please check your internet connection and try again.';
          }
          return;
        }
      } else {
        _error = 'Unable to connect to server. Please check your internet connection and try again.';
      }
    } else if (errorString.contains('permission-denied')) {
      _error = 'Database access denied. Please contact support or check if Firestore is properly configured.';
    } else if (errorString.contains('not-found')) {
      _error = 'User profile not found. Please try logging in again or contact support.';
    } else {
      _error = 'An unexpected error occurred. Please try again later.';
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
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _retryCount = 0;
    notifyListeners();
  }
}