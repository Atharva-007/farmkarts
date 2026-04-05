// Quick fix for auth service - simplified and working version
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Simple and fast image upload method
  Future<String> _uploadLicenseImageQuick(
    String uid, {
    File? licenseImage,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    try {
      if ((kIsWeb && imageBytes == null) || (!kIsWeb && licenseImage == null)) {
        throw Exception('No image data provided');
      }

      // Check file size early
      if (kIsWeb && imageBytes != null && imageBytes.length > 2 * 1024 * 1024) {
        throw Exception(
            'Image too large. Please select an image smaller than 2MB.');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${uid}_$timestamp.jpg';
      final ref = _storage.ref().child('licenses').child(fileName);

      // print('Creating storage reference: licenses/$fileName');

      // Simplified upload without complex metadata
      late UploadTask uploadTask;

      if (kIsWeb && imageBytes != null) {
        // print('Uploading image bytes for web platform (${imageBytes.length} bytes)');
        uploadTask = ref.putData(imageBytes);
      } else if (!kIsWeb && licenseImage != null) {
        // print('Uploading image file for mobile platform');
        uploadTask = ref.putFile(licenseImage);
      } else {
        throw Exception('Platform mismatch');
      }

      // print('Starting upload task with timeout...');

      // Tracking upload progress
      uploadTask.snapshotEvents.listen((event) {
        double progress =
            event.bytesTransferred.toDouble() / event.totalBytes.toDouble();
        // print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // Increased timeout for better resilience on slower networks
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception(
            'Upload timed out. Your connection might be too slow for this image size. Please try again or use a smaller image.'),
      );

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        // print('Upload successful. Download URL: $downloadUrl');
        return downloadUrl;
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
    } catch (e) {
      // print('Error uploading license image: $e');
      if (e.toString().toLowerCase().contains('timeout')) {
        throw Exception(
            'Upload timed out. Please check your internet connection and try again.');
      } else if (e.toString().toLowerCase().contains('permission')) {
        throw Exception(
            'Permission denied. Please check your internet connection.');
      } else if (e.toString().toLowerCase().contains('too large') ||
          e.toString().toLowerCase().contains('size')) {
        throw Exception(
            'Image file is too large. Please select an image smaller than 2MB.');
      } else {
        throw Exception(
            'Upload failed. Please try with a different image or check your internet connection.');
      }
    }
  }

  // Main signup method
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String mobileNo,
    required UserRole role,
    double? acresLand,
    String? dukanName,
    File? licenseImage,
    Uint8List? licenseImageBytes,
    String? licenseImageName,
  }) async {
    try {
      // Create user account first
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      final uid = user.uid;

      // Upload license image if needed (for addats) - now optional during signup
      String? licenseImageUrl;
      if (role == UserRole.addat &&
          (licenseImage != null || licenseImageBytes != null)) {
        licenseImageUrl = await _uploadLicenseImageQuick(
          uid,
          licenseImage: licenseImage,
          imageBytes: licenseImageBytes,
          imageName: licenseImageName,
        );
      }

      // Create user profile
      UserModel userModel;
      if (role == UserRole.farmer) {
        userModel = FarmerModel(
          uid: uid,
          email: email,
          fullName: fullName,
          mobileNo: mobileNo,
          acresLand: acresLand ?? 0.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        userModel = AddatModel(
          uid: uid,
          email: email,
          fullName: fullName,
          mobileNo: mobileNo,
          dukanName: dukanName ?? '',
          licenseImageUrl: licenseImageUrl, // Can be null now
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // Save to Firestore
      await _firestore.collection('users').doc(uid).set(userModel.toMap());

      return userCredential;
    } catch (e) {
      // Clean up auth user if profile creation fails
      if (_auth.currentUser != null) {
        try {
          await _auth.currentUser!.delete();
        } catch (deleteError) {
          // print('Could not clean up auth user: $deleteError');
        }
      }
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Other required methods
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      // Add a 15-second timeout to profile fetching
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 15));

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final roleString = data['role'] as String?;

        if (roleString == null) {
          throw Exception(
              'User profile is corrupted - missing role information');
        }

        final role = UserRole.values.firstWhere(
          (e) => e.toString().split('.').last == roleString,
          orElse: () => UserRole.farmer,
        );

        if (role == UserRole.farmer) {
          return FarmerModel.fromMap(data);
        } else {
          return AddatModel.fromMap(data);
        }
      } else {
        throw Exception('User profile not found. Please register again.');
      }
    } catch (e) {
      throw Exception('Failed to load user profile: ${e.toString()}');
    }
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user model
  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      return await getUserProfile(user.uid);
    } catch (e) {
      // print('Error getting current user model: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel userModel) async {
    try {
      await _firestore
          .collection('users')
          .doc(userModel.uid)
          .update(userModel.toMap());
    } catch (e) {
      throw Exception('Failed to update user profile: ${e.toString()}');
    }
  }

  // Delete user account
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete authentication account
      await user.delete();
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await user.verifyBeforeUpdateEmail(newEmail);

      // Update email in user profile
      final userProfile = await getUserProfile(user.uid);
      if (userProfile != null) {
        if (userProfile is FarmerModel) {
          final updatedProfile = userProfile.copyWith(email: newEmail);
          await updateUserProfile(updatedProfile);
        } else if (userProfile is AddatModel) {
          final updatedProfile = userProfile.copyWith(email: newEmail);
          await updateUserProfile(updatedProfile);
        }
      }
    } catch (e) {
      throw Exception('Failed to update email: ${e.toString()}');
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await user.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Failed to update password: ${e.toString()}');
    }
  }

  // Upload license image (for license management page)
  Future<String> uploadLicenseImage({
    required String userId,
    File? licenseImage,
    Uint8List? licenseImageBytes,
    required String licenseImageName,
  }) async {
    try {
      return await _uploadLicenseImageQuick(
        userId,
        licenseImage: licenseImage,
        imageBytes: licenseImageBytes,
        imageName: licenseImageName,
      );
    } catch (e) {
      throw Exception('Failed to upload license image: ${e.toString()}');
    }
  }
}
