import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'services/auth_service.dart';
import 'services/user_state_service.dart';
import 'models/user_model.dart';
import 'theme/app_theme.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _imagePicker = ImagePicker();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _acresController = TextEditingController();
  final TextEditingController _dukanNameController = TextEditingController();

  UserRole _selectedRole = UserRole.farmer;
  File? _licenseImage;
  Uint8List? _licenseImageBytes; // For web compatibility
  String? _licenseImageName;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _pickLicenseImage() async {
    try {
      setState(() {
        _errorMessage = null; // Clear any previous errors
      });
      
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Slightly higher quality for better preview
        maxWidth: 1920,   // Limit size to prevent huge uploads
        maxHeight: 1920,
      );
      
      if (pickedFile != null) {
        if (kIsWeb) {
          // For web platform
          final imageBytes = await pickedFile.readAsBytes();
          
          // Check file size (5MB limit)
          if (imageBytes.length > 5 * 1024 * 1024) {
            setState(() {
              _errorMessage = 'Image too large. Please select an image smaller than 5MB.';
            });
            return;
          }
          
          setState(() {
            _licenseImageBytes = imageBytes;
            _licenseImageName = pickedFile.name;
            _licenseImage = null; // Clear file for web
          });
          
          print('Web image selected: ${pickedFile.name} (${imageBytes.length} bytes)');
        } else {
          // For mobile platforms
          final file = File(pickedFile.path);
          final fileSize = await file.length();
          
          // Check file size (5MB limit)
          if (fileSize > 5 * 1024 * 1024) {
            setState(() {
              _errorMessage = 'Image too large. Please select an image smaller than 5MB.';
            });
            return;
          }
          
          setState(() {
            _licenseImage = file;
            _licenseImageBytes = null; // Clear bytes for mobile
            _licenseImageName = pickedFile.name;
          });
          
          print('Mobile image selected: ${pickedFile.name} (${fileSize} bytes)');
        }
        
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selected: ${pickedFile.name}'),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _errorMessage = 'Error selecting image: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    // No license validation needed during signup anymore
    // Vendors can upload license later in their profile

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Starting optimized signup process...');
      
      // Show progress messages to user
      _showProgressSnackBar('Creating account...');
      
      final userCredential = await _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        fullName: _fullNameController.text.trim(),
        mobileNo: _mobileController.text.trim(),
        acresLand: _selectedRole == UserRole.farmer 
            ? double.tryParse(_acresController.text) ?? 0.0 
            : null,
        dukanName: _selectedRole == UserRole.addat 
            ? _dukanNameController.text.trim() 
            : null,
        // License upload removed from signup - vendors can upload later
        licenseImage: null,
        licenseImageBytes: null,
        licenseImageName: null,
      ).timeout(
        const Duration(minutes: 2), // Reduced timeout since no image upload
        onTimeout: () => throw Exception('Account creation timed out. Please check your internet connection and try again.'),
      );

      if (userCredential?.user != null) {
        print('Signup successful, setting user state...');
        
        // Show progress
        _showProgressSnackBar('Setting up your profile...');
        
        // Set user in state service with timeout
        final userStateService = Provider.of<UserStateService>(context, listen: false);
        await userStateService.setCurrentUser(userCredential!.user!.uid).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Profile setup timed out. Please try logging in.'),
        );
        
        if (userStateService.currentUser != null) {
          print('User state set successfully, navigating to home...');
          
          if (mounted) {
            // Clear any existing snackbars
            ScaffoldMessenger.of(context).clearSnackBars();
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Welcome ${userStateService.currentUser!.fullName}! Your account has been created successfully.'),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.success,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
            
            // Navigate to home with a slight delay to show success message
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/home');
              }
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Account created but failed to load profile. Please try logging in.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to create account. Please try again.';
        });
      }
    } catch (e) {
      print('Signup error: $e');
      
      // Clear progress snackbar
      ScaffoldMessenger.of(context).clearSnackBars();
      
      String errorMessage = 'An error occurred during signup.';
      
      // Handle specific Firebase Auth errors
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('email-already-in-use')) {
        errorMessage = 'This email is already registered. Please use a different email or try logging in.';
      } else if (errorString.contains('weak-password')) {
        errorMessage = 'Password is too weak. Please use at least 6 characters with a mix of letters and numbers.';
      } else if (errorString.contains('invalid-email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (errorString.contains('operation-not-allowed')) {
        errorMessage = 'Email/password accounts are not enabled. Please contact support.';
      } else if (errorString.contains('network-request-failed') || errorString.contains('network error')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (errorString.contains('timeout') || errorString.contains('timed out')) {
        errorMessage = 'The operation timed out. Please check your internet connection and try again.';
      } else if (errorString.contains('permission denied') || errorString.contains('database access denied')) {
        errorMessage = 'Database access issue. Please try again or contact support if the problem persists.';
      } else if (errorString.contains('failed to upload license image')) {
        errorMessage = 'Failed to upload license image. Please try with a different image or check your internet connection.';
      } else if (errorString.contains('failed to create user profile')) {
        errorMessage = 'Account created but profile setup failed. Please try logging in or contact support.';
      } else {
        // Clean up generic error messages
        errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('FormatException: ', '');
        if (errorMessage.length > 200) {
          errorMessage = 'An unexpected error occurred. Please try again or contact support if the problem persists.';
        }
      }
      
      setState(() => _errorMessage = errorMessage);
      
      // Show error snackbar for timeout/network errors for immediate feedback
      if (errorString.contains('timeout') || errorString.contains('network')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _signUp(),
            ),
          ),
        );
      }
      
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showProgressSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 30), // Long duration for progress
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildImageWidget() {
    if (kIsWeb && _licenseImageBytes != null) {
      // For web platform, use Image.memory
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Image.memory(
                _licenseImageBytes!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Error displaying web image: $error');
                  return _buildErrorPlaceholder();
                },
              ),
              // File info overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _licenseImageName ?? 'license.jpg',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${(_licenseImageBytes!.length / 1024).toStringAsFixed(1)} KB',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (!kIsWeb && _licenseImage != null) {
      // For mobile platforms, use Image.file
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Image.file(
                _licenseImage!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Error displaying mobile image: $error');
                  return _buildErrorPlaceholder();
                },
              ),
              // File info overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _licenseImageName ?? 'license.jpg',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      FutureBuilder<int>(
                        future: _licenseImage!.length(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              '${(snapshot.data! / 1024).toStringAsFixed(1)} KB',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Fallback placeholder when no image is selected
      return _buildEmptyPlaceholder();
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Error loading image',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to select again',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 40,
            color: AppTheme.primaryGreen,
          ),
          SizedBox(height: 8),
          Text(
            'Upload License Image',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryGreen,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap to select image',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Max size: 5MB',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.agriculture,
                  size: 48,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 26, 
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Join FarmKarts as a farmer or vendor'),
              const SizedBox(height: 30),

              // Role Selection
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Your Role',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedRole = UserRole.farmer),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _selectedRole == UserRole.farmer 
                                        ? AppTheme.primaryGreen 
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: _selectedRole == UserRole.farmer 
                                      ? AppTheme.primaryGreen.withOpacity(0.1) 
                                      : Colors.white,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.agriculture,
                                      color: _selectedRole == UserRole.farmer 
                                          ? AppTheme.primaryGreen 
                                          : Colors.grey,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Farmer',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _selectedRole == UserRole.farmer 
                                            ? AppTheme.primaryGreen 
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedRole = UserRole.addat),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _selectedRole == UserRole.addat 
                                        ? AppTheme.primaryGreen 
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: _selectedRole == UserRole.addat 
                                      ? AppTheme.primaryGreen.withOpacity(0.1) 
                                      : Colors.white,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.store,
                                      color: _selectedRole == UserRole.addat 
                                          ? AppTheme.primaryGreen 
                                          : Colors.grey,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Addat/Vendor',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _selectedRole == UserRole.addat 
                                            ? AppTheme.primaryGreen 
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Common Fields
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _mobileController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mobile number is required';
                        }
                        if (value.length != 10) {
                          return 'Enter a valid 10-digit mobile number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Role-specific fields
                    if (_selectedRole == UserRole.farmer)
                      TextFormField(
                        controller: _acresController,
                        decoration: const InputDecoration(
                          labelText: 'Acres of Land',
                          prefixIcon: Icon(Icons.landscape),
                          border: OutlineInputBorder(),
                          suffixText: 'acres',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Land area is required';
                          }
                          final acres = double.tryParse(value);
                          if (acres == null || acres <= 0) {
                            return 'Enter a valid land area';
                          }
                          return null;
                        },
                      )
                    else ...[
                      TextFormField(
                        controller: _dukanNameController,
                        decoration: const InputDecoration(
                          labelText: 'Dukan/Shop Name',
                          prefixIcon: Icon(Icons.store),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Shop name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // License Upload - Now handled in profile after account creation
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppTheme.primaryGreen,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'License Verification',
                                  style: TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'After creating your account, you can upload your business license in your profile for verification. This will help build trust with customers.',
                              style: TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: AppTheme.success,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Quick account creation - no waiting!',
                                  style: TextStyle(
                                    color: AppTheme.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Password Fields
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Password is required';
                        if (value.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 16),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Already have account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
