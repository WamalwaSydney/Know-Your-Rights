// lib/core/services/google_signin_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleSignInService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('🔐 Starting Google Sign-In...');

      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        print('❌ User cancelled Google Sign-In');
        return null;
      }

      print('✅ Google Sign-In successful: ${googleUser.email}');
      print('📧 Email: ${googleUser.email}');
      print('👤 Name: ${googleUser.displayName}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      print('✅ Firebase authentication successful');
      print('🆔 User ID: ${userCredential.user?.uid}');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code}');
      print('Message: ${e.message}');

      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw 'An account already exists with this email but different sign-in credentials. Please sign in using a different method.';
        case 'invalid-credential':
          throw 'Invalid credentials. Please try again.';
        case 'operation-not-allowed':
          throw 'Google Sign-In is not enabled. Please contact support.';
        case 'user-disabled':
          throw 'This user account has been disabled.';
        case 'user-not-found':
          throw 'No user found with this email.';
        case 'wrong-password':
          throw 'Invalid password.';
        case 'invalid-verification-code':
          throw 'Invalid verification code.';
        case 'invalid-verification-id':
          throw 'Invalid verification ID.';
        default:
          throw 'Authentication failed: ${e.message ?? "Unknown error"}';
      }
    } catch (e) {
      print('❌ Unexpected Error: $e');
      throw 'Failed to sign in with Google: $e';
    }
  }

  /// Sign out from Google and Firebase
  Future<void> signOut() async {
    try {
      print('🔓 Signing out...');

      // Sign out from Google
      await _googleSignIn.signOut();

      // Sign out from Firebase
      await _auth.signOut();

      print('✅ Sign out successful');
    } catch (e) {
      print('❌ Error signing out: $e');
      throw 'Failed to sign out: $e';
    }
  }

  /// Check if user is currently signed in
  bool isSignedIn() {
    return _auth.currentUser != null;
  }

  /// Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Get current user email
  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  /// Get current user display name
  String? getCurrentUserDisplayName() {
    return _auth.currentUser?.displayName;
  }

  /// Get current user photo URL
  String? getCurrentUserPhotoUrl() {
    return _auth.currentUser?.photoURL;
  }

  /// Check if user is signed in with Google
  Future<bool> isSignedInWithGoogle() async {
    final User? user = _auth.currentUser;
    if (user == null) return false;

    // Check if any of the user's providers is Google
    for (var info in user.providerData) {
      if (info.providerId == 'google.com') {
        return true;
      }
    }
    return false;
  }

  /// Re-authenticate user (useful for sensitive operations)
  Future<UserCredential?> reAuthenticateWithGoogle() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw 'No user is currently signed in';

      // Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Re-authenticate
      return await user.reauthenticateWithCredential(credential);
    } catch (e) {
      print('❌ Re-authentication failed: $e');
      throw 'Failed to re-authenticate: $e';
    }
  }

  /// Link Google account to existing account
  Future<UserCredential> linkWithGoogle() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw 'No user is currently signed in';

      // Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw 'Google Sign-In was cancelled';

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link with current user
      return await user.linkWithCredential(credential);
    } catch (e) {
      print('❌ Linking failed: $e');
      throw 'Failed to link Google account: $e';
    }
  }

  /// Unlink Google account
  Future<User> unlinkGoogle() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw 'No user is currently signed in';

      return await user.unlink('google.com');
    } catch (e) {
      print('❌ Unlinking failed: $e');
      throw 'Failed to unlink Google account: $e';
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw 'No user is currently signed in';

      // Delete from Firebase
      await user.delete();

      // Sign out from Google
      await _googleSignIn.signOut();

      print('✅ Account deleted successfully');
    } catch (e) {
      print('❌ Account deletion failed: $e');
      throw 'Failed to delete account: $e';
    }
  }
}