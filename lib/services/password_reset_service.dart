import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Secure Password Reset Service
/// Implements the mobile-first password reset system and email verification with OTP
class PasswordResetService {
  static final instance = PasswordResetService._();
  PasswordResetService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// Step 1: Request password reset - sends OTP to email
  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    return _requestOTP(email: email, purpose: 'reset');
  }

  /// Request email verification OTP for signup
  /// Reuses the same OTP system as password reset for consistency
  Future<Map<String, dynamic>> requestEmailVerification({
    required String email,
  }) async {
    return _requestOTP(email: email, purpose: 'signup');
  }

  /// Generic OTP request method for both password reset and email verification
  Future<Map<String, dynamic>> _requestOTP({
    required String email,
    required String purpose,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('$purpose OTP requested for: $email');
      }

      // Validate email format
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }

      // Determine if we should create user based on purpose
      bool shouldCreateUser = purpose == 'signup';

      if (kDebugMode) {
        debugPrint('shouldCreateUser: $shouldCreateUser for purpose: $purpose');
      }

      // Use Supabase's OTP system
      // Note: This sends an email OTP, not a recovery OTP
      await _client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: shouldCreateUser,
      );

      if (kDebugMode) {
        debugPrint('$purpose OTP sent to: $email');
      }

      return {
        'success': true,
        'message': 'A verification code has been sent to your email.',
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$purpose OTP request failed: $e');
        debugPrint('Error type: ${e.runtimeType}');
        debugPrint('Full error: $e');
      }

      String errorMessage =
          'Failed to send verification code. Please try again.';
      if (e.toString().contains('rate')) {
        errorMessage = 'Too many requests. Please wait before trying again.';
      } else if (e.toString().contains('User already registered')) {
        errorMessage = 'Email already exists. Try signing in instead.';
      } else if (e.toString().contains('Invalid email')) {
        errorMessage = 'Please enter a valid email address.';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  /// Step 2: Verify the OTP code for password reset
  Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) async {
    return _verifyOTPGeneric(email: email, otp: otp, purpose: 'reset');
  }

  /// Verify email verification OTP for signup
  /// Reuses the same OTP verification system as password reset
  Future<Map<String, dynamic>> verifyEmailVerificationOTP({
    required String email,
    required String otp,
  }) async {
    final result =
        await _verifyOTPGeneric(email: email, otp: otp, purpose: 'signup');

    // If successful, mark email as verified in our users table
    if (result['success'] == true) {
      await _markEmailAsVerified(email);
    }

    return result;
  }

  /// Handle email confirmation link (alternative to OTP)
  /// This method can be called when user clicks the confirmation link in email
  Future<Map<String, dynamic>> confirmEmailFromLink({
    required String email,
  }) async {
    try {
      // Check if user session is now valid after clicking the link
      final user = _client.auth.currentUser;
      if (user != null && user.emailConfirmedAt != null) {
        // Email was confirmed via link
        await _markEmailAsVerified(email);

        return {
          'success': true,
          'message': 'Email confirmed successfully.',
        };
      } else {
        return {
          'success': false,
          'message':
              'Email confirmation not completed. Please check your email and click the confirmation link.',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Email link confirmation check failed: $e');
      }

      return {
        'success': false,
        'message': 'Unable to verify email confirmation. Please try again.',
      };
    }
  }

  /// Generic OTP verification method for both password reset and email verification
  Future<Map<String, dynamic>> _verifyOTPGeneric({
    required String email,
    required String otp,
    required String purpose,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('Verifying $purpose OTP for: $email');
        debugPrint('OTP length: ${otp.length}');
        debugPrint('OTP content: $otp');
      }

      // Verify OTP with Supabase Auth
      // Using email type since signInWithOtp sends email OTPs
      final response = await _client.auth.verifyOTP(
        type: OtpType.email,
        token: otp,
        email: email,
      );

      if (response.session == null) {
        throw Exception('Invalid or expired code');
      }

      // Check if user is suspended after successful OTP verification
      if (response.user != null) {
        final userProfile = await _client
            .from('users')
            .select('is_suspended, suspension_reason')
            .eq('id', response.user!.id)
            .maybeSingle();

        if (userProfile != null && userProfile['is_suspended'] == true) {
          // Sign out the suspended user immediately
          await _client.auth.signOut();

          final reason = userProfile['suspension_reason'] as String? ??
              'Your account has been suspended. Please contact support.';

          return {
            'success': false,
            'message': 'Account suspended: $reason',
          };
        }
      }

      // For email verification (signup), we need to update the user's email_verified status
      if (purpose == 'signup') {
        await _markEmailAsVerified(email);
      }

      if (kDebugMode) {
        debugPrint('$purpose OTP verified successfully for: $email');
      }

      return {
        'success': true,
        'message': 'Code verified successfully.',
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$purpose OTP verification failed: $e');
        debugPrint('Error type: ${e.runtimeType}');
        if (e.toString().contains('otp_expired')) {
          debugPrint('OTP has expired - check if OTP is being sent correctly');
        }
      }

      String errorMessage = 'Invalid or expired code. Please try again.';

      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  /// Mark user's email as verified in our users table
  Future<void> _markEmailAsVerified(String email) async {
    try {
      await _client.from('users').update({
        'email_verified': true,
      }).eq('email', email);

      if (kDebugMode) {
        debugPrint('Email verified status updated for: $email');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to update email verified status: $e');
      }
    }
  }

  /// Step 3: Set new password after OTP verification
  /// Note: OTP should already be verified in previous step, user should be authenticated
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('Resetting password for: $email');
      }

      // Validate password strength first
      final passwordValidation = _validatePassword(newPassword);
      if (!passwordValidation['valid']) {
        throw Exception(passwordValidation['message']);
      }

      // Check if user is currently authenticated (OTP should have been verified in previous step)
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated. Please verify OTP first.');
      }

      // Update the user's password (user is already authenticated via OTP)
      final updateResponse = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (updateResponse.user == null) {
        throw Exception('Failed to update password');
      }

      if (kDebugMode) {
        debugPrint('Password reset successful for: $email');
      }

      return {
        'success': true,
        'message': 'Password updated successfully.',
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Password reset failed: $e');
      }

      String errorMessage = 'Failed to reset password. Please try again.';
      if (e.toString().contains('not authenticated')) {
        errorMessage = 'Session expired. Please verify your code again.';
      } else if (e.toString().contains('Password')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else if (e.toString().contains('rate')) {
        errorMessage = 'Too many requests. Please wait before trying again.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Private helper methods

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Map<String, dynamic> _validatePassword(String password) {
    if (password.isEmpty) {
      return {'valid': false, 'message': 'Password cannot be empty'};
    }
    if (password.length < 12) {
      return {
        'valid': false,
        'message': 'Password must be at least 12 characters'
      };
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return {
        'valid': false,
        'message': 'Password must contain at least one uppercase letter'
      };
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return {
        'valid': false,
        'message': 'Password must contain at least one lowercase letter'
      };
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return {
        'valid': false,
        'message': 'Password must contain at least one number'
      };
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return {
        'valid': false,
        'message': 'Password must contain at least one special character'
      };
    }
    return {'valid': true, 'message': 'Password is valid'};
  }
}
