// lib/core/services/auth_service.dart (ENHANCED VERSION)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to check user authentication state
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if email is verified
      if (result.user != null && !result.user!.emailVerified) {
        throw Exception('Please verify your email before signing in. '
            'Check your inbox for the verification link.');
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code}');
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email address.');
        case 'wrong-password':
          throw Exception('Incorrect password. Please try again.');
        case 'invalid-email':
          throw Exception('Invalid email address format.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        case 'too-many-requests':
          throw Exception('Too many failed attempts. Please try again later.');
        default:
          throw Exception(e.message ?? 'Sign in failed. Please try again.');
      }
    } catch (e) {
      print('Sign in error: $e');
      throw Exception(e.toString());
    }
  }

  // Register with email and password
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await result.user?.sendEmailVerification();

      return result.user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code}');
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('An account already exists with this email address.');
        case 'invalid-email':
          throw Exception('Invalid email address format.');
        case 'weak-password':
          throw Exception('Password is too weak. Use at least 6 characters.');
        case 'operation-not-allowed':
          throw Exception('Email/password accounts are not enabled.');
        default:
          throw Exception(e.message ?? 'Registration failed. Please try again.');
      }
    } catch (e) {
      print('Registration error: $e');
      throw Exception('An unexpected error occurred during registration.');
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      } else if (user == null) {
        throw Exception('No user is currently signed in.');
      } else {
        throw Exception('Email is already verified.');
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'too-many-requests':
          throw Exception('Too many requests. Please wait before requesting again.');
        default:
          throw Exception(e.message ?? 'Failed to send verification email.');
      }
    } catch (e) {
      print('Email verification error: $e');
      throw Exception('Failed to send verification email: $e');
    }
  }

  // Check and reload email verification status
  Future<bool> checkEmailVerified() async {
    try {
      await _auth.currentUser?.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code}');
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email address.');
        case 'invalid-email':
          throw Exception('Invalid email address format.');
        case 'too-many-requests':
          throw Exception('Too many requests. Please try again later.');
        default:
          throw Exception(e.message ?? 'Failed to send password reset email.');
      }
    } catch (e) {
      print('Password reset error: $e');
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Change password (requires recent authentication)
  Future<void> changePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'requires-recent-login':
          throw Exception(
              'This operation requires recent authentication. Please sign out and sign in again.'
          );
        case 'weak-password':
          throw Exception('Password is too weak. Use at least 6 characters.');
        default:
          throw Exception(e.message ?? 'Failed to change password.');
      }
    } catch (e) {
      print('Change password error: $e');
      throw Exception('Failed to change password: $e');
    }
  }

  // Re-authenticate user (needed before sensitive operations)
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user is currently signed in.');
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          throw Exception('Incorrect password.');
        case 'user-mismatch':
          throw Exception('The credential does not match the current user.');
        default:
          throw Exception(e.message ?? 'Re-authentication failed.');
      }
    } catch (e) {
      print('Re-authentication error: $e');
      throw Exception('Re-authentication failed: $e');
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Google sign-in error: ${e.code}');
      throw Exception(e.message ?? 'Google sign-in failed');
    } catch (e) {
      print('Google sign-in error: $e');
      throw Exception('Google sign-in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in via Google
      await GoogleSignIn().signOut();
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      throw Exception('Error signing out: $e');
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }
      await user.delete();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'requires-recent-login':
          throw Exception(
              'This operation requires recent authentication. Please sign out and sign in again.'
          );
        default:
          throw Exception(e.message ?? 'Failed to delete account.');
      }
    } catch (e) {
      print('Delete account error: $e');
      throw Exception('Failed to delete account: $e');
    }
  }
}