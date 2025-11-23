// lib/widgets/google_sign_in_button.dart

import 'package:flutter/material.dart';
import 'package:legal_ai/core/constants.dart';
import 'package:legal_ai/core/services/auth_service.dart';

class GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onSignInSuccess;
  final Function(String)? onSignInError;

  const GoogleSignInButton({
    Key? key,
    this.onSignInSuccess,
    this.onSignInError,
  }) : super(key: key);

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    // Prevent multiple simultaneous sign-in attempts
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      print('🔐 Starting Google Sign-In...');

      // Show loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Signing in with Google...'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // Perform Google Sign-In using your existing AuthService
      final user = await _authService.signInWithGoogle();

      if (user == null) {
        // User cancelled the sign-in
        print('❌ User cancelled Google Sign-In');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Sign-in cancelled'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Sign-in successful
      print('✅ Google Sign-In successful!');
      print('👤 User: ${user.displayName}');
      print('📧 Email: ${user.email}');
      print('🆔 UID: ${user.uid}');

      if (mounted) {
        // Hide any existing snackbars
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Welcome, ${user.displayName ?? user.email ?? "User"}!',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Call success callback (navigation happens in AuthWrapper automatically)
        widget.onSignInSuccess?.call();
      }
    } catch (e) {
      print('❌ Google Sign-In error: $e');

      if (mounted) {
        // Hide loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Extract clean error message
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring('Exception: '.length);
        }

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage.length > 80
                        ? 'Sign-in failed. Please try again.'
                        : errorMessage,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _handleGoogleSignIn,
            ),
          ),
        );

        // Call error callback
        widget.onSignInError?.call(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: _isLoading
          ? const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      )
          : Image.asset(
        'assets/google_logo.png',
        height: 24.0,
        errorBuilder: (context, error, stackTrace) {
          // Fallback icon if image not found
          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade600,
                  Colors.red.shade600,
                  Colors.yellow.shade600,
                  Colors.green.shade600,
                ],
              ),
            ),
            child: const Center(
              child: Text(
                'G',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          );
        },
      ),
      label: Text(
        _isLoading ? 'Signing in...' : 'Continue with Google',
        style: const TextStyle(
          color: kDarkTextColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      style: OutlinedButton.styleFrom(
        backgroundColor: _isLoading ? Colors.grey[100] : kLightTextColor,
        side: BorderSide(
          color: _isLoading ? Colors.grey[300]! : Colors.grey,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        minimumSize: const Size.fromHeight(50),
        disabledBackgroundColor: Colors.grey[100],
      ),
    );
  }
}