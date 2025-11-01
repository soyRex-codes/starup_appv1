import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:foundervers/features/auth/auth_service.dart';
import 'package:foundervers/features/auth/otp_verification_page.dart';
import 'package:foundervers/features/auth/forgot_password_page_new.dart';
import 'package:foundervers/services/password_reset_service.dart';
import 'package:foundervers/widgets/foundervers_logo.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _fullName = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Add listeners to update UI when passwords change
    _password.addListener(_updatePasswordMatch);
    _confirmPassword.addListener(_updatePasswordMatch);
  }

  void _updatePasswordMatch() {
    if (mounted && !_isLogin) {
      setState(() {}); // Trigger UI update for password match indicator
    }
  }

  Future<void> _submit() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final email = _email.text.trim();
      final password = _password.text;

      // Validate email and password
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Please fill in all fields');
      }

      // For sign-up, validate password confirmation
      if (!_isLogin) {
        final fullName = _fullName.text.trim();
        final confirmPassword = _confirmPassword.text;

        if (fullName.isEmpty) {
          throw Exception('Please enter your full name');
        }
        if (confirmPassword.isEmpty) {
          throw Exception('Please confirm your password');
        }
        if (password != confirmPassword) {
          throw Exception('Passwords do not match');
        }
        if (password.length < 12) {
          throw Exception('Password must be at least 12 characters long');
        }
      }

      if (_isLogin) {
        await AuthService.instance
            .signInWithEmailPassword(email: email, password: password);
      } else {
        // Handle signup with email confirmation and full name
        final fullName = _fullName.text.trim();
        final response = await AuthService.instance.registerWithEmailPassword(
          email: email,
          password: password,
          displayName: fullName,
        );

        if (response.user != null) {
          // Always require email verification for new signups
          // Send verification email using the correct method
          final result =
              await PasswordResetService.instance.requestEmailVerification(
            email: email,
          );

          if (result['success'] == true) {
            if (mounted) {
              // Success - navigate to OTP page
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      OtpVerificationPage.emailVerification(email),
                ),
              );
            }
          } else {
            // Handle different error cases
            if (result['message']?.contains('rate') == true ||
                result['message']?.contains('wait') == true) {
              if (mounted) {
                // Rate limited - navigate to OTP page with helpful message
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        OtpVerificationPage.emailVerification(email),
                  ),
                );
                // Show informative message after navigation
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'Account created! You can request a new verification code on the next page if needed.'),
                        backgroundColor: Colors.blue,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                });
              }
            } else {
              throw Exception(
                  result['message'] ?? 'Failed to send verification email');
            }
          }
        } else {
          throw Exception('Failed to create account');
        }
      }
    } catch (e) {
      if (mounted) {
        // Improved error logging for debugging
        if (kDebugMode) {
          debugPrint('🔥 SIGNUP ERROR DETAILS:');
          debugPrint('Error type: ${e.runtimeType}');
          debugPrint('Full error: $e');
          debugPrint('Error string: ${e.toString()}');
        }

        setState(() {
          // More specific error handling
          final errorStr = e.toString().toLowerCase();

          // Check for specific Supabase auth errors first
          if (errorStr.contains('email_address_invalid') ||
              errorStr.contains('invalid_email')) {
            _error = 'Please enter a valid email address.';
          } else if (errorStr.contains('signup_disabled')) {
            _error =
                'Account creation is currently disabled. Please try again later.';
          } else if (errorStr.contains('password_too_short')) {
            _error = 'Password must be at least 12 characters long.';
          } else if (errorStr.contains('user_already_registered') ||
              errorStr.contains('email_address_not_available')) {
            _error =
                'An account with this email already exists. Please sign in instead.';
          } else if (errorStr.contains('over_email_send_rate_limit') ||
              errorStr.contains('rate_limit') ||
              errorStr.contains('429')) {
            final match = RegExp(r'after (\d+) seconds').firstMatch(errorStr);
            final waitTime = match?.group(1);
            if (waitTime != null) {
              _error =
                  'Too many email requests. Please wait $waitTime seconds before trying again.';
            } else {
              _error =
                  'Too many requests. Please wait a minute before trying again.';
            }
          } else if (errorStr.contains('socketexception') ||
              errorStr.contains('failed host lookup')) {
            _error =
                'Network connection issue. Please check your internet connection and try again.';
          } else if (errorStr.contains('timeout')) {
            _error =
                'Connection timeout. Please check your internet connection and try again.';
          } else {
            // Show the actual error for debugging but in a user-friendly way
            if (kDebugMode) {
              _error = 'Signup failed: ${e.toString()}';
            } else {
              _error = 'Unable to create account. Please try again.';
            }
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _password.removeListener(_updatePasswordMatch);
    _confirmPassword.removeListener(_updatePasswordMatch);
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _fullName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Sign In' : 'Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20), // Add some top spacing

            // App Logo
            const Center(
              child: FounderVersLogo(
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(height: 32),

            // Show full name field only during sign-up
            if (!_isLogin) ...[
              TextField(
                controller: _fullName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  helperText: 'Your first and last name',
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                helperText: !_isLogin ? 'Minimum 12 characters' : null,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  tooltip:
                      _isPasswordVisible ? 'Hide password' : 'Show password',
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            // Show confirm password field only during sign-up
            if (!_isLogin) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPassword,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  helperText: 'Re-enter your password',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Password match indicator
                      if (_confirmPassword.text.isNotEmpty)
                        Icon(
                          _password.text == _confirmPassword.text
                              ? Icons.check_circle
                              : Icons.error,
                          color: _password.text == _confirmPassword.text
                              ? Colors.green
                              : Colors.red,
                        ),
                      // Visibility toggle
                      IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        tooltip: _isConfirmPasswordVisible
                            ? 'Hide password'
                            : 'Show password',
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isLogin ? 'Sign In' : 'Create Account'),
            ),
            const SizedBox(height: 12),

            // Show "Forgot Password?" only during login
            if (_isLogin) ...[
              TextButton(
                onPressed: _loading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordPageNew(),
                          ),
                        );
                      },
                child: const Text('Forgot Password?'),
              ),
              const SizedBox(height: 8),
            ],

            TextButton(
              onPressed: _loading
                  ? null
                  : () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _error = null; // Clear any previous errors
                        _confirmPassword
                            .clear(); // Clear confirm password when switching
                        _fullName.clear(); // Clear full name when switching
                        _isPasswordVisible = false; // Reset password visibility
                        _isConfirmPasswordVisible =
                            false; // Reset confirm password visibility
                      });
                    },
              child: Text(_isLogin
                  ? "Don't have an account? Create one"
                  : 'Have an account? Sign in'),
            ),
            const SizedBox(height: 20), // Add some bottom spacing
          ],
        ),
      ),
    );
  }
}
