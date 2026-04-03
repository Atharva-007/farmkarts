import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/user_state_service.dart';

class SignUpViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  final formKey = GlobalKey<FormState>();
  
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final fullNameController = TextEditingController();
  final mobileController = TextEditingController();
  final acresController = TextEditingController();
  final dukanNameController = TextEditingController();

  UserRole _selectedRole = UserRole.farmer;
  UserRole get selectedRole => _selectedRole;

  File? _licenseImage;
  File? get licenseImage => _licenseImage;

  Uint8List? _licenseImageBytes;
  Uint8List? get licenseImageBytes => _licenseImageBytes;

  String? _licenseImageName;
  String? get licenseImageName => _licenseImageName;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> pickLicenseImage() async {
    try {
      clearError();
      
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (pickedFile != null) {
        if (kIsWeb) {
          final imageBytes = await pickedFile.readAsBytes();
          
          if (imageBytes.length > 5 * 1024 * 1024) {
            _errorMessage = 'Image too large. Please select an image smaller than 5MB.';
            notifyListeners();
            return;
          }
          
          _licenseImageBytes = imageBytes;
          _licenseImageName = pickedFile.name;
          _licenseImage = null;
          
        } else {
          final file = File(pickedFile.path);
          final fileSize = await file.length();
          
          if (fileSize > 5 * 1024 * 1024) {
            _errorMessage = 'Image too large. Please select an image smaller than 5MB.';
            notifyListeners();
            return;
          }
          
          _licenseImage = file;
          _licenseImageBytes = null;
          _licenseImageName = pickedFile.name;
        }
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick image: $e';
      notifyListeners();
    }
  }

  Future<bool> signUp(UserStateService userStateService) async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (_selectedRole == UserRole.addat) {
      if ((kIsWeb && _licenseImageBytes == null) || (!kIsWeb && _licenseImage == null)) {
        _errorMessage = 'Please upload your business license';
        notifyListeners();
        return false;
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _authService.signUpWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
        fullName: fullNameController.text.trim(),
        mobileNo: mobileController.text.trim(),
        role: _selectedRole,
        acresLand: _selectedRole == UserRole.farmer 
            ? double.tryParse(acresController.text.trim()) 
            : null,
        dukanName: _selectedRole == UserRole.addat 
            ? dukanNameController.text.trim() 
            : null,
        licenseImage: _licenseImage,
        licenseImageBytes: _licenseImageBytes,
        licenseImageName: _licenseImageName,
      );

      await userStateService.initializeUser();
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getReadableErrorMessage(e.toString());
      notifyListeners();
      return false;
    }
  }

  String _getReadableErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'An account already exists for that email.';
    } else if (error.contains('invalid-email')) {
      return 'The email address is not valid.';
    } else if (error.contains('weak-password')) {
      return 'The password provided is too weak.';
    } else if (error.contains('network-request-failed')) {
      return 'Network error. Please check your connection.';
    } else if (error.contains('Exception: ')) {
      return error.replaceAll('Exception: ', '');
    }
    return 'Failed to create account. Please try again later.';
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    fullNameController.dispose();
    mobileController.dispose();
    acresController.dispose();
    dukanNameController.dispose();
    super.dispose();
  }
}