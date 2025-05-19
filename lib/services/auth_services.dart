import 'package:astrology_app/common/utils/constants.dart';
import 'package:astrology_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../client/model/user_model.dart';
import '../common/utils/common.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Function to register astrologer
  Future<void> registerAstrologer({
    required String? name,
    required String? gender,
    required String? birthDate,
    required List<String>? languages,
    required String? email,
    required List<String> skills,
    required String? profilePicturePath,
    required String bio,
    required String specialization,
    required int yearsOfExperience,
    required String? certificationUrl,
    required String? idProofUrl,
    required Function(bool success, String? error) callback,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        callback(false, 'No authenticated user');
        return;
      }

      // Upload profile picture if provided
      String? profilePictureUrl;
      if (profilePicturePath != null) {
        profilePictureUrl = await CommonUtilities.uploadImageToFirebase(
          filePath: profilePicturePath,
          storagePath: 'profile_pictures/${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      // Create complete AstrologerProfile with all fields
      final astrologerProfile = AstrologerProfile(
        name: name,
        email: email,
        gender: gender,
        birthDate: birthDate,
        languages: languages,
        bio: bio,
        specialization: specialization,
        skills: skills,
        yearsOfExperience: yearsOfExperience,
        certificationUrl: certificationUrl,
        idProofUrl: idProofUrl,
        imageUrl: profilePictureUrl,
        status: AstrologerStatus.approved,
        rating: 0.0,
        totalReadings: 0,
      );

      // Update ONLY the astrologerProfile, userType and updatedAt fields
      final updatedUser = userStore.user?.copyWith(
        astrologerProfile: astrologerProfile,
        // userType: UserType.pendingAstrologer,
        updatedAt: DateTime.now(),
      );

      if (updatedUser == null) {
        callback(false, 'User data not found');
        return;
      }

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .set(updatedUser.toJson());

      // Update local user store
      userStore.updateUserData(updatedUser);

      callback(true, null);
    } catch (e) {
      debugPrint('Error registering astrologer: $e');
      callback(false, 'Failed to register: ${e.toString()}');
    }
  }


  // Logout method
  Future<void> signOut({
    required Function(bool success, String? error) callback,
  }) async {
    try {
      await _auth.signOut();
      callback(true, null);
    } catch (e) {
      print('Error signing out: $e');
      callback(false, e.toString());
    }
  }

  // Check if user exists in Firestore 'users' collection
  Future<void> checkUserExists({
    required Function(bool exists, UserModel? userModel) callback,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        callback(false, null);
        return;
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        // Construct UserModel from Firestore document
        final userModel = UserModel.fromJson({
          'id': currentUser.uid,
          ...userDoc.data()!,
        });
        callback(true, userModel);
      } else {
        // Return a minimal UserModel with just the ID for new users
        final userModel = UserModel(id: currentUser.uid);
        callback(false, userModel);
      }
    } catch (e) {
      print('Error checking user existence: $e');
      callback(false, null);
    }
  }

  // Add this method to your AuthService class
  Future<void> updateUserProfile({
    required UserModel user,
    required Function(bool success, String? error) callback,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        callback(false, 'No authenticated user');
        return;
      }

      // Ensure the user ID matches the current user
      if (user.id != null && user.id != currentUser.uid) {
        callback(false, 'User ID mismatch');
        return;
      }

      // Update the updatedAt timestamp
      final updatedUser = user.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update(updatedUser.toJson());

      callback(true, null);
    } catch (e) {
      print('Error updating user profile: $e');
      callback(false, e.toString());
    }
  }
}