import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../models/user_model.dart';
import '../../services/user_state_service.dart';
import '../../services/auth_service.dart';

class LicenseManagementPage extends StatefulWidget {
  const LicenseManagementPage({super.key});

  @override
  State<LicenseManagementPage> createState() => _LicenseManagementPageState();
}

class _LicenseManagementPageState extends State<LicenseManagementPage> {
  final _authService = AuthService();
  final _imagePicker = ImagePicker();
  
  File? _licenseImage;
  Uint8List? _licenseImageBytes; // For web compatibility
  String? _licenseImageName;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStateService>(
      builder: (context, userState, child) {
        final user = userState.currentUser;
        
        if (user == null || user is! AddatModel) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('License Management'),
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Text('Access denied. This page is only for vendors.'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          appBar: AppBar(
            title: const Text('License Management'),
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: AppConstants.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(user),
                  const SizedBox(height: 24),
                  _buildCurrentStatus(user),
                  const SizedBox(height: 24),
                  _buildLicenseUpload(user),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorMessage(),
                  ],
                  const SizedBox(height: 24),
                  _buildVerificationInfo(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AddatModel user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: AppConstants.defaultPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryGreen.withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.business,
                  color: AppTheme.primaryGreen,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Business License',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your business license for ${user.dukanName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatus(AddatModel user) {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // License Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: user.licenseImageUrl != null
                        ? (user.isLicenseVerified ? AppTheme.success.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1))
                        : AppTheme.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    user.licenseImageUrl != null
                        ? (user.isLicenseVerified ? Icons.verified : Icons.pending)
                        : Icons.error_outline,
                    color: user.licenseImageUrl != null
                        ? (user.isLicenseVerified ? AppTheme.success : AppTheme.warning)
                        : AppTheme.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusTitle(user),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusDescription(user),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Upload Date
            if (user.licenseUploadedAt != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppTheme.textGrey),
                  const SizedBox(width: 8),
                  Text(
                    'Uploaded: ${_formatDate(user.licenseUploadedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ],
            
            // Verification Notes
            if (user.verificationNotes != null && user.verificationNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.info.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note, size: 16, color: AppTheme.info),
                        const SizedBox(width: 8),
                        Text(
                          'Admin Notes',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.verificationNotes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseUpload(AddatModel user) {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.licenseImageUrl != null ? 'Update License' : 'Upload License',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Current License Image
            if (user.licenseImageUrl != null) ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    user.licenseImageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.grey.shade400, size: 48),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Upload New License
            GestureDetector(
              onTap: _isUploading ? null : _pickLicenseImage,
              child: Container(
                width: double.infinity,
                height: (_licenseImage != null || _licenseImageBytes != null) ? 200 : 120,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isUploading ? AppTheme.primaryGreen : Colors.grey.shade300,
                    width: _isUploading ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: _isUploading 
                      ? AppTheme.primaryGreen.withOpacity(0.05)
                      : Colors.grey.shade50,
                ),
                child: _isUploading
                    ? _buildUploadingWidget()
                    : (_licenseImage != null || _licenseImageBytes != null)
                        ? _buildNewImageWidget()
                        : _buildUploadPlaceholder(user),
              ),
            ),
            
            if (_licenseImage != null || _licenseImageBytes != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _uploadLicense,
                      icon: const Icon(Icons.cloud_upload),
                      label: Text(_isUploading ? 'Uploading...' : 'Upload License'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isUploading ? null : _clearSelection,
                    child: const Icon(Icons.clear),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.all(12),
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

  Widget _buildUploadingWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          color: AppTheme.primaryGreen,
          strokeWidth: 3,
        ),
        const SizedBox(height: 16),
        Text(
          'Uploading license...',
          style: TextStyle(
            color: AppTheme.primaryGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please wait, this may take a moment',
          style: TextStyle(
            color: AppTheme.textGrey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildNewImageWidget() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: kIsWeb && _licenseImageBytes != null
                ? Image.memory(
                    _licenseImageBytes!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
                  )
                : !kIsWeb && _licenseImage != null
                    ? Image.file(
                        _licenseImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
                      )
                    : _buildErrorPlaceholder(),
          ),
        ),
        // File info overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _getFileSize(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Success indicator
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.success,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadPlaceholder(AddatModel user) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 40,
          color: AppTheme.primaryGreen,
        ),
        const SizedBox(height: 12),
        Text(
          user.licenseImageUrl != null ? 'Upload New License' : 'Upload License Image',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryGreen,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to select image from your device',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textGrey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Max size: 5MB • JPG, PNG',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.info,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.red.shade50,
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
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationInfo() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.info),
                const SizedBox(width: 8),
                Text(
                  'Verification Process',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoStep(
              icon: Icons.upload_file,
              title: 'Upload License',
              description: 'Upload a clear photo of your business license',
              isCompleted: false, // Will be dynamic based on upload status
            ),
            const SizedBox(height: 12),
            _buildInfoStep(
              icon: Icons.rate_review,
              title: 'Admin Review',
              description: 'Our team will review your license within 1-2 business days',
              isCompleted: false,
            ),
            const SizedBox(height: 12),
            _buildInfoStep(
              icon: Icons.verified,
              title: 'Verification Complete',
              description: 'Once verified, you can start selling products',
              isCompleted: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoStep({
    required IconData icon,
    required String title,
    required String description,
    required bool isCompleted,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCompleted 
                ? AppTheme.success.withOpacity(0.1)
                : AppTheme.textGrey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isCompleted ? AppTheme.success : AppTheme.textGrey,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? AppTheme.success : AppTheme.textDark,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods
  String _getStatusTitle(AddatModel user) {
    if (user.licenseImageUrl == null) {
      return 'License Not Uploaded';
    } else if (!user.isLicenseVerified) {
      return 'Pending Verification';
    } else {
      return 'License Verified';
    }
  }

  String _getStatusDescription(AddatModel user) {
    if (user.licenseImageUrl == null) {
      return 'Upload your business license to start the verification process';
    } else if (!user.isLicenseVerified) {
      return 'Your license is under review by our admin team';
    } else {
      return 'Your business license has been verified successfully';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getFileSize() {
    if (kIsWeb && _licenseImageBytes != null) {
      return '${(_licenseImageBytes!.length / 1024).toStringAsFixed(1)} KB';
    } else if (!kIsWeb && _licenseImage != null) {
      // For mobile, we'll calculate size asynchronously
      return 'Calculating size...';
    }
    return '';
  }

  // Action methods
  Future<void> _pickLicenseImage() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Reduced quality for smaller files
        maxWidth: 1280,   // Reduced resolution
        maxHeight: 1280,  // Reduced resolution
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final imageBytes = await pickedFile.readAsBytes();
          
          if (imageBytes.length > 2 * 1024 * 1024) { // 2MB limit
            setState(() {
              _errorMessage = 'Image too large. Please select an image smaller than 2MB.';
            });
            return;
          }

          setState(() {
            _licenseImageBytes = imageBytes;
            _licenseImageName = pickedFile.name;
            _licenseImage = null;
          });
        } else {
          final file = File(pickedFile.path);
          final fileSize = await file.length();
          
          if (fileSize > 2 * 1024 * 1024) { // 2MB limit
            setState(() {
              _errorMessage = 'Image too large. Please select an image smaller than 2MB.';
            });
            return;
          }

          setState(() {
            _licenseImage = file;
            _licenseImageBytes = null;
            _licenseImageName = pickedFile.name;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selected: ${pickedFile.name}'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting image: $e';
      });
    }
  }

  Future<void> _uploadLicense() async {
    if (_licenseImage == null && _licenseImageBytes == null) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final userStateService = Provider.of<UserStateService>(context, listen: false);
      final currentUser = userStateService.currentUser as AddatModel;

      // Upload the license image
      final licenseUrl = await _authService.uploadLicenseImage(
        userId: currentUser.uid,
        licenseImage: _licenseImage,
        licenseImageBytes: _licenseImageBytes,
        licenseImageName: _licenseImageName ?? 'license.jpg',
      );

      // Update user profile with new license
      final updatedUser = currentUser.copyWith(
        licenseImageUrl: licenseUrl,
        licenseUploadedAt: DateTime.now(),
        isLicenseVerified: false, // Reset verification status
        verificationNotes: null, // Clear any previous notes
      );

      await _authService.updateUserProfile(updatedUser);
      await userStateService.setCurrentUser(currentUser.uid);

      if (mounted) {
        setState(() {
          _licenseImage = null;
          _licenseImageBytes = null;
          _licenseImageName = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('License uploaded successfully! It will be reviewed within 1-2 business days.'),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload license: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _licenseImage = null;
      _licenseImageBytes = null;
      _licenseImageName = null;
      _errorMessage = null;
    });
  }
}