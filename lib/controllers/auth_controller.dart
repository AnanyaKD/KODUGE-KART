import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koduge_kart/screens/donor_home.dart';
import 'package:koduge_kart/screens/ngo_home.dart';
import 'package:koduge_kart/utils/logger_service.dart';

enum UserType { donor, ngo }

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable variables
  final RxBool isLoading = false.obs;
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    currentUser.bindStream(_auth.authStateChanges());
  }

  /// Login with email and password
  Future<bool> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      LoggerService.auth('Starting login process for email: $email');

      // Attempt authentication
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      LoggerService.auth('Authentication successful', credential.user?.uid);

      // // Check if email is verified
      // if (credential.user != null && !credential.user!.emailVerified) {
      //   LoggerService.auth('Email not verified', credential.user?.uid);
      //   errorMessage.value =
      //       'Please verify your email before logging in. Check your inbox.';
      //   await _auth.signOut();
      //   isLoading.value = false;
      //   return false;
      // }

      // Get user data from Firestore
      await Future.delayed(const Duration(milliseconds: 500));
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        LoggerService.error(
          'User is null after successful authentication',
          null,
          null,
          'AUTH',
        );
        throw FirebaseAuthException(
          code: 'auth-state-error',
          message: 'Authentication state error occurred',
        );
      }

      // Fetch user document
      final userDoc =
          await _firestore.collection("user").doc(currentUser.uid).get();

      LoggerService.database('User document fetched', 'user');

      if (!userDoc.exists) {
        LoggerService.error('User document not found in Firestore');
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'User data not found',
        );
      }

      final userData = userDoc.data();
      final userType = userData?["userType"];
      LoggerService.auth('User type: $userType', currentUser.uid);

      isLoading.value = false;

      // Navigate based on user type
      if (context.mounted) {
        LoggerService.navigation(
          'Navigating to ${userType == "UserType.donor" ? "DonorHome" : "NGOHome"}',
        );

        Get.offAll(
          () =>
              userType == "UserType.donor"
                  ? const DonorHome()
                  : const NGOHome(),
          transition: Transition.fadeIn,
        );
      }

      return true;
    } on FirebaseAuthException catch (e) {
      LoggerService.error('FirebaseAuthException', e, null, 'AUTH');
      isLoading.value = false;

      errorMessage.value = switch (e.code) {
        'user-not-found' => 'No user found with this email.',
        'wrong-password' => 'Incorrect password.',
        'invalid-email' => 'Invalid email address.',
        'user-disabled' => 'This account has been disabled.',
        'auth-state-error' => 'Authentication state error. Please try again.',
        'invalid-credential' => 'Invalid email or password.',
        _ => 'Authentication failed: ${e.message}',
      };

      return false;
    } on FirebaseException catch (e) {
      LoggerService.error('FirebaseException', e, null, 'AUTH');
      isLoading.value = false;
      errorMessage.value = 'Database error: ${e.message}';
      return false;
    } catch (e) {
      LoggerService.error('Unexpected error during login', e, null, 'AUTH');
      isLoading.value = false;
      errorMessage.value = 'An unexpected error occurred: ${e.toString()}';
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
    required UserType userType,
    required BuildContext context,
  }) async {
    UserCredential? userCredential;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      LoggerService.auth('Starting registration for email: $email');

      // Create user account
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      LoggerService.auth(
        'User account created successfully',
        userCredential.user?.uid,
      );

      // CRITICAL: Save user data to Firestore IMMEDIATELY before any state change
      // This ensures the StreamBuilder in main.dart will find the user data
      await _firestore.collection("user").doc(userCredential.user!.uid).set(
        {
          "email": email.trim(),
          "userType": userType.toString(),
          "phone": phone.trim(),
          "address": address.trim(),
          "name": name.trim(),
          "emailVerified": true,
          "createdAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: false), // Ensure complete write
      );

      LoggerService.database(
        'User data saved to Firestore',
        'user/${userCredential.user!.uid}',
      );

      // Send email verification (optional - commented out per user's preference)
      // if (userCredential.user != null) {
      //   await userCredential.user!.sendEmailVerification();
      //   LoggerService.auth('Verification email sent', userCredential.user?.uid);
      // }

      // Sign out the user after registration so they must login
      // This prevents the StreamBuilder from trying to navigate before data is ready
      await _auth.signOut();

      LoggerService.auth(
        'User signed out after registration - must login to continue',
        userCredential.user?.uid,
      );

      isLoading.value = false;
      return true;
    } on FirebaseAuthException catch (e) {
      LoggerService.error('FirebaseAuthException during registration', e);
      isLoading.value = false;

      errorMessage.value = switch (e.code) {
        'weak-password' => 'The password provided is too weak.',
        'email-already-in-use' => 'The account already exists for that email.',
        'invalid-email' => 'Invalid email address.',
        'operation-not-allowed' => 'Email/password accounts are not enabled.',
        _ => 'Registration failed: ${e.message}',
      };

      return false;
    } catch (e) {
      LoggerService.error('Unexpected error during registration', e);
      isLoading.value = false;
      errorMessage.value = 'Some Error. Try again later.';
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      errorMessage.value = '';
      LoggerService.auth('Sending password reset email to: $email');

      await _auth.sendPasswordResetEmail(email: email.trim());

      LoggerService.auth('Password reset email sent successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      LoggerService.error('Error sending password reset email', e);

      errorMessage.value = switch (e.code) {
        'user-not-found' => 'No user found with this email.',
        'invalid-email' => 'Invalid email address.',
        _ => 'Error: ${e.message}',
      };

      return false;
    } catch (e) {
      LoggerService.error('Unexpected error sending password reset', e);
      errorMessage.value = 'An error occurred. Please try again.';
      return false;
    }
  }

  /// Resend email verification
  Future<bool> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        LoggerService.auth('Verification email resent', user.uid);
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.error('Error resending verification email', e);
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      LoggerService.auth('User logging out', _auth.currentUser?.uid);
      await _auth.signOut();
      LoggerService.auth('User logged out successfully');
    } catch (e) {
      LoggerService.error('Error during logout', e);
    }
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get current user email
  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  /// Check if current user is NGO
  Future<bool> isNGOUser() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return false;

      final userDoc = await _firestore.collection('user').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['userType'] == "UserType.ngo";
      }
      return false;
    } catch (e) {
      LoggerService.error('Error checking user type', e);
      return false;
    }
  }

  /// Check if current user is Donor
  Future<bool> isDonorUser() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return false;

      final userDoc = await _firestore.collection('user').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['userType'] == "UserType.donor";
      }
      return false;
    } catch (e) {
      LoggerService.error('Error checking user type', e);
      return false;
    }
  }

  /// Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return null;

      final userDoc = await _firestore.collection('user').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      LoggerService.error('Error fetching user data', e);
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    errorMessage.value = '';
  }
}
