import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:foundervers/services/password_reset_service.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final response =
        await _client.auth.signInWithPassword(email: email, password: password);

    if (response.user != null) {
      // Check if user is suspended before allowing login
      await _checkUserSuspension(response.user!.id);
      await _upsertUserProfile();
    }
    return response;
  }

  /// Check if user is suspended and sign them out if they are
  Future<void> _checkUserSuspension(String userId) async {
    try {
      final userProfile = await _client
          .from('users')
          .select('is_suspended, suspension_reason')
          .eq('id', userId)
          .maybeSingle();

      if (userProfile != null && userProfile['is_suspended'] == true) {
        // Sign out the suspended user immediately
        await _client.auth.signOut();

        final reason = userProfile['suspension_reason'] as String? ??
            'Your account has been suspended. Please contact support.';

        throw AuthException(
          'Account suspended: $reason',
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      // If we can't check suspension status, allow login but log the error
      if (kDebugMode) debugPrint('⚠️ Could not check suspension status: $e');
    }
  }

  Future<AuthResponse> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Starting registration for: $email');
        debugPrint('📝 Display name: $displayName');
      }

      // Create user without automatic email confirmation
      // We'll handle email verification manually with our OTP system
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'full_name': displayName} : null,
        emailRedirectTo: null, // Don't use automatic email confirmation
      );

      if (response.user != null) {
        if (kDebugMode) {
          debugPrint('✅ User created: ${response.user!.id}');
          debugPrint(
              '📧 Email confirmed: ${response.user!.emailConfirmedAt != null}');
          debugPrint('🔐 Session exists: ${response.session != null}');
        }

        // Sign out immediately to prevent automatic login
        // User must verify email with OTP before they can use the account
        if (response.session != null) {
          await _client.auth.signOut();
          if (kDebugMode)
            debugPrint('🚪 User signed out - must verify email first');
        }

        // Create basic user profile immediately (before email confirmation)
        // But mark email as unverified
        try {
          await _createUserProfile(
            userId: response.user!.id,
            email: email,
            displayName: displayName,
            isEmailVerified: false,
          );
          if (kDebugMode)
            debugPrint('✅ Basic user profile created (unverified)');
        } catch (profileError) {
          if (kDebugMode)
            debugPrint('⚠️ Failed to create user profile: $profileError');
          // Don't fail the whole registration for this
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔥 AUTH SERVICE REGISTRATION ERROR:');
        debugPrint('Error type: ${e.runtimeType}');
        debugPrint('Full error: $e');
        debugPrint('Error details: ${e.toString()}');

        // Check if it's a specific Supabase error
        if (e.toString().contains('AuthApiException')) {
          debugPrint('🚨 This is a Supabase AuthApiException');
        }
      }
      rethrow;
    }
  }

  Future<void> resendEmailConfirmation(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  /// Send email verification OTP using the new OTP system
  Future<Map<String, dynamic>> sendEmailVerificationOTP(String email) async {
    // Import the service at the top if not already imported
    final passwordResetService = PasswordResetService.instance;
    return await passwordResetService.requestEmailVerification(email: email);
  }

  /// Verify email verification OTP using the new OTP system
  Future<Map<String, dynamic>> verifyEmailVerificationOTP({
    required String email,
    required String otp,
  }) async {
    // Import the service at the top if not already imported
    final passwordResetService = PasswordResetService.instance;
    return await passwordResetService.verifyEmailVerificationOTP(
      email: email,
      otp: otp,
    );
  }

  // Email Password Reset Methods (Legacy - Use PasswordResetService instead)
  @Deprecated(
      'Use PasswordResetService.instance.requestPasswordReset() instead')
  Future<void> sendPasswordResetOTP(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      // Don't specify redirectTo - let it use default
    );
  }

  @Deprecated('Use PasswordResetService.instance.verifyOTP() instead')
  Future<AuthResponse> verifyEmailOTPAndSignIn({
    required String email,
    required String token,
  }) async {
    return await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email, // Use email OTP type
    );
  }

  @Deprecated('Use PasswordResetService.instance.resetPassword() instead')
  Future<void> updateUserPassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Mark user's email as verified after successful OTP verification
  Future<void> markEmailAsVerified() async {
    final user = currentUser;
    if (user == null) return;

    try {
      await _client.from('users').update({
        'email_verified': true,
      }).eq('id', user.id);

      if (kDebugMode)
        debugPrint('✅ Email marked as verified for user: ${user.id}');
    } on PostgrestException catch (e) {
      if (kDebugMode) debugPrint('Mark email verified error: $e');
    }
  }

  /// Create user profile with specific user ID (for new registrations)
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    String? displayName,
    required bool isEmailVerified,
  }) async {
    final payload = {
      'id': userId,
      'email': email,
      'name': displayName ?? email.split('@')[0],
      'username': email.split('@')[0],
      'full_name': displayName,
      'avatar_url': null,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'email_verified': isEmailVerified,
    };

    try {
      await _client.from('users').insert(payload);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // User already exists, update instead
        await _client.from('users').update({
          'name': displayName ?? email.split('@')[0],
          'full_name': displayName,
          'email_verified': isEmailVerified,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      } else {
        rethrow;
      }
    }
  }

  Future<void> _upsertUserProfile({
    String? displayName,
    bool? isEmailVerified,
  }) async {
    final user = currentUser;
    if (user == null) return;

    Map<String, dynamic>? existingProfile;
    try {
      existingProfile = await _client
          .from('users')
          .select('name, username, full_name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to load existing profile for ${user.id}: $e');
      }
    }

    String? _fallbackName() =>
        displayName ??
        user.userMetadata?['full_name'] ??
        user.email?.split('@')[0];

    final payload = <String, dynamic>{
      'id': user.id,
      'email': user.email,
      'name': existingProfile?['name'] ?? _fallbackName(),
      'username': existingProfile?['username'] ?? user.email?.split('@')[0],
      'full_name': existingProfile?['full_name'] ??
          displayName ??
          user.userMetadata?['full_name'],
      'avatar_url':
          existingProfile?['avatar_url'] ?? user.userMetadata?['avatar_url'],
      'email_verified': isEmailVerified ?? (user.emailConfirmedAt != null),
      'last_login_at': DateTime.now().toIso8601String(),
    };

    try {
      await _client.from('users').upsert(payload);
    } on PostgrestException catch (e) {
      if (kDebugMode) debugPrint('Upsert user profile error: $e');
    }
  }
}
