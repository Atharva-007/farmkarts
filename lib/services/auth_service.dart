import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with role-based registration
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required UserRole role,
    required String fullName,
    required String mobileNo,
    double? acresLand, // For farmers
    String? dukanName, // For addat
    File? licenseImage, // For addat (mobile)
    Uint8List? licenseImageBytes, // For addat (web)
    String? licenseImageName, // Image filename
  }) async {
    UserCredential? userCredential;
    
    try {
      print('Starting signup process for email: $email, role: $role');
      
      // Create user with email and password
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final now = DateTime.now();

        print('User created successfully with UID: $uid');

        try {
          if (role == UserRole.farmer) {
            // Create farmer profile
            final farmer = FarmerModel(
              uid: uid,
              email: email,
              fullName: fullName,
              mobileNo: mobileNo,
              acresLand: acresLand ?? 0.0,
              createdAt: now,
              updatedAt: now,
            );

            print('Creating farmer profile in Firestore...');
            await _firestore.collection('users').doc(uid).set(farmer.toMap());
            print('Farmer profile created successfully');
            
          } else if (role == UserRole.addat) {
            String licenseImageUrl = '';

            // Upload license image if provided
            if (licenseImage != null || licenseImageBytes != null) {
              print('Uploading license image...');
              try {
                licenseImageUrl = await _uploadLicenseImage(
                  uid, 
                  licenseImage: licenseImage,
                  imageBytes: licenseImageBytes,
                  imageName: licenseImageName,
                );
                print('License image uploaded successfully: $licenseImageUrl');
              } catch (uploadError) {
                print('Error uploading license image: $uploadError');
                // Continue without license image for now
                licenseImageUrl = '';
              }
            }

            // Create addat profile
            final addat = AddatModel(
              uid: uid,
              email: email,
              fullName: fullName,
              mobileNo: mobileNo,
              dukanName: dukanName ?? '',
              licenseImageUrl: licenseImageUrl,
              createdAt: now,
              updatedAt: now,
            );

            print('Creating addat profile in Firestore...');
            await _firestore.collection('users').doc(uid).set(addat.toMap());
            print('Addat profile created successfully');
          }

          // Update display name
          print('Updating display name...');
          await userCredential.user!.updateDisplayName(fullName);
          print('Display name updated successfully');
          
        } catch (firestoreError) {
          print('Error creating user profile in Firestore: $firestoreError');
          // Delete the auth user if profile creation fails
          try {
            await userCredential.user!.delete();
          } catch (deleteError) {
            print('Error deleting user after profile creation failure: $deleteError');
          }
          throw Exception('Failed to create user profile: $firestoreError');
        }
      }

      return userCredential;
    } catch (e) {
      print('Error in signup process: $e');
      
      // If user was created but profile failed, clean up
      if (userCredential?.user != null) {
        try {
          await userCredential!.user!.delete();
        } catch (deleteError) {
          print('Error cleaning up user after signup failure: $deleteError');
        }
      }
      
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      print('Getting user profile for UID: $uid');
      
      // Check if Firestore is available
      await _checkFirestoreConnection();
      
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        print('User document found with data: ${data.keys}');
        
        final roleString = data['role'] as String?;
        if (roleString == null) {
          print('Error: No role field found in user document');
          throw Exception('User profile is corrupted - missing role information');
        }
        
        final role = UserRole.values.firstWhere(
          (e) => e.toString().split('.').last == roleString,
          orElse: () => UserRole.farmer,
        );

        print('User role determined as: $role');

        if (role == UserRole.farmer) {
          final farmer = FarmerModel.fromMap(data);
          print('Created FarmerModel for: ${farmer.fullName}');
          return farmer;
        } else {
          final addat = AddatModel.fromMap(data);
          print('Created AddatModel for: ${addat.fullName}');
          return addat;
        }
      } else {
        print('User document does not exist for UID: $uid');
        throw Exception('User profile not found. Please register again or contact support.');
      }
    } catch (e) {
      print('Error getting user profile for UID $uid: $e');
      
      // Handle specific Firestore errors
      final errorString = e.toString();
      if (errorString.contains('unavailable') || errorString.contains('offline')) {
        throw Exception('Unable to connect to database. Please check your internet connection.');
      } else if (errorString.contains('permission-denied')) {
        throw Exception('Database access denied. Please ensure Firestore is properly configured.');
      } else if (errorString.contains('not-found')) {
        throw Exception('Database not found. Please ensure Firestore is set up in Firebase Console.');
      }
      
      rethrow;
    }
  }

  // Check Firestore connection
  Future<void> _checkFirestoreConnection() async {
    try {
      // Try to perform a simple operation to check connection
      await _firestore.settings;
      print('Firestore connection check passed');
    } catch (e) {
      print('Firestore connection check failed: $e');
      throw Exception('Unable to connect to Firestore. Please check your internet connection and Firebase configuration.');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update({
        ...user.toMap(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Upload license image for addat
  Future<String> _uploadLicenseImage(
    String uid, {
    File? licenseImage,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    try {
      print('Starting image upload for user: $uid');
      
      // Validate that we have image data
      if ((kIsWeb && imageBytes == null) || (!kIsWeb && licenseImage == null)) {
        throw Exception('No valid image data provided for platform');
      }
      
      final ref = _storage.ref().child('licenses').child('$uid.jpg');
      print('Created storage reference: licenses/$uid.jpg');
      
      UploadTask uploadTask;
      
      if (kIsWeb && imageBytes != null) {
        print('Uploading image bytes for web platform (${imageBytes.length} bytes)');
        uploadTask = ref.putData(
          imageBytes,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'originalName': imageName ?? 'license.jpg',
              'uploadedBy': uid,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );
      } else if (!kIsWeb && licenseImage != null) {
        print('Uploading image file for mobile platform');
        uploadTask = ref.putFile(
          licenseImage,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'originalName': imageName ?? 'license.jpg',
              'uploadedBy': uid,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );
      } else {
        throw Exception('Platform mismatch or no valid image data');
      }
      
      print('Starting upload task...');
      final snapshot = await uploadTask;
      print('Upload completed successfully');
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Got download URL: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading license image: $e');
      
      // Provide more specific error messages
      if (e.toString().contains('storage/unauthorized')) {
        throw Exception('Permission denied. Please check Firebase Storage rules.');
      } else if (e.toString().contains('storage/invalid-format')) {
        throw Exception('Invalid image format. Please use JPG or PNG.');
      } else if (e.toString().contains('storage/object-not-found')) {
        throw Exception('Storage location not found. Please contact support.');
      } else {
        throw Exception('Failed to upload license image: ${e.toString()}');
      }
    }
  }

  // Check if user exists
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  // Get current user model
  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user != null) {
      return await getUserProfile(user.uid);
    }
    return null;
  }
}