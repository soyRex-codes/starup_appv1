import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:foundervers/features/auth/auth_service.dart';
import 'package:foundervers/features/auth/auth_error_message.dart';
import 'package:foundervers/features/auth/otp_verification_page.dart';
import 'package:foundervers/features/auth/forgot_password_page_new.dart';
import 'package:foundervers/widgets/terai_logo.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _acceptedTerms = false;
  bool _ageVerified = false; // COPPA compliance: 13+ years old

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

    // Dismiss keyboard before processing
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _email.text.trim();
      final password = _password.text;

      // Validate email format
      if (email.isEmpty) {
        throw Exception('Please enter your email address');
      }
      if (!email.contains('@') || !email.contains('.')) {
        throw Exception('Please enter a valid email address');
      }

      // Validate password
      if (password.isEmpty) {
        throw Exception('Please enter your password');
      }

      // For sign-up, validate password confirmation and additional fields
      if (!_isLogin) {
        final fullName = _fullName.text.trim();
        final confirmPassword = _confirmPassword.text;

        if (fullName.isEmpty) {
          throw Exception('Please enter your full name');
        }
        if (fullName.length < 2) {
          throw Exception('Full name must be at least 2 characters');
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
        if (!_acceptedTerms) {
          throw Exception(
              'Please accept the Terms of Service and Privacy Policy');
        }
        if (!_ageVerified) {
          throw Exception(
              'You must be at least 13 years old to use FounderVers');
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
          // Signup successful!
          // Supabase automatically sends the confirmation email (OTP) on signup.
          // We don't need to send another one immediately, as that triggers rate limits.

          if (mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created! Please verify your email.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );

            // Navigate to OTP page
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    OtpVerificationPage.emailVerification(email),
              ),
            );
          }
        } else {
          throw Exception('Failed to create account');
        }
      }
    } catch (e) {
      if (mounted) {
        // Improved error logging for debugging
        if (kDebugMode) {
          debugPrint('🔥 AUTH ERROR DETAILS:');
          debugPrint('Error type: ${e.runtimeType}');
          debugPrint('Full error: $e');
          debugPrint('Error string: ${e.toString()}');
          debugPrint('Is login: $_isLogin');
        }

        // Determine error message asynchronously
        String? errorMessage;
        final errorStr = e.toString().toLowerCase();

        // Check for specific Supabase auth errors first
        final infrastructureMessage = authInfrastructureErrorMessage(e);
        if (infrastructureMessage != null) {
          errorMessage = infrastructureMessage;
        } else if (errorStr.contains('email_address_invalid') ||
            errorStr.contains('invalid_email') ||
            errorStr.contains('invalid email format')) {
          errorMessage = 'Please enter a valid email address.';
        } else if (errorStr.contains('invalid email or password') ||
            errorStr.contains('invalid credentials') ||
            errorStr.contains('invalid login') ||
            errorStr.contains('invalid_credentials')) {
          // Check if the user is suspended using the RPC
          try {
            final email = _email.text.trim(); // Get email from controller
            final rpcResponse =
                await AuthService.instance.checkSuspensionStatus(email);
            if (rpcResponse['found'] == true &&
                rpcResponse['is_suspended'] == true) {
              errorMessage =
                  'Your account has been suspended. Please send an email to foundervers@gmail.com for review if you think this was a mistake.';
            } else {
              errorMessage = 'Invalid email or password. Please try again.';
            }
          } catch (_) {
            errorMessage = 'Invalid email or password. Please try again.';
          }
        } else if (errorStr.contains('email not confirmed') ||
            errorStr.contains('email_not_confirmed')) {
          errorMessage =
              'Please verify your email with the code sent to your inbox before signing in.';
        } else if (errorStr.contains('account suspended')) {
          errorMessage =
              'Your account has been suspended. Please send an email to foundervers@gmail.com for review if you think this was a mistake.';
        } else if (errorStr.contains('signup_disabled') ||
            errorStr.contains('signup disabled')) {
          errorMessage =
              'Account creation is currently disabled. Please try again later.';
        } else if (errorStr.contains('password_too_short') ||
            errorStr.contains('password') && errorStr.contains('short')) {
          errorMessage = 'Password must be at least 12 characters long.';
        } else if (errorStr.contains('user_already_registered') ||
            errorStr.contains('email_address_not_available') ||
            errorStr.contains('user already registered') ||
            errorStr.contains('already exists')) {
          errorMessage =
              'An account with this email already exists. Please sign in instead.';
        } else if (errorStr.contains('over_email_send_rate_limit') ||
            errorStr.contains('rate_limit') ||
            errorStr.contains('rate limit') ||
            errorStr.contains('too many') ||
            errorStr.contains('429')) {
          final match = RegExp(r'after (\d+) seconds').firstMatch(errorStr);
          final waitTime = match?.group(1);
          if (waitTime != null) {
            errorMessage =
                'Too many email requests. Please wait $waitTime seconds before trying again.';
          } else {
            errorMessage =
                'Too many requests. Please wait a minute before trying again.';
          }
        } else if (errorStr.contains('socketexception') ||
            errorStr.contains('failed host lookup') ||
            errorStr.contains('network') && errorStr.contains('error')) {
          errorMessage =
              'Network connection issue. Please check your internet connection and try again.';
        } else if (errorStr.contains('timeout') ||
            errorStr.contains('timed out')) {
          errorMessage =
              'Connection timeout. Please check your internet connection and try again.';
        } else if (errorStr.contains('handshake') ||
            errorStr.contains('certificate') ||
            errorStr.contains('ssl')) {
          errorMessage =
              'Secure connection failed. Please check your network settings and try again.';
        } else if (errorStr.contains('exception:')) {
          // Clean up "Exception: " prefix from error messages
          final cleanError =
              e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

          // CRITICAL FIX: Don't show raw AuthRetryableFetchException or SocketException details
          if (cleanError.contains('SocketException') ||
              cleanError.contains('AuthRetryableFetchException') ||
              cleanError.contains('ClientException') ||
              cleanError.contains('host lookup')) {
            errorMessage =
                'Network connection issue. Please check your internet connection.';
          } else {
            errorMessage = cleanError;
          }
        } else {
          // Use localized NetworkService for generic/network errors
          // This prevents raw stack traces or sensitive URLs from showing
          if (errorStr.contains('socketexception') ||
              errorStr.contains('authretryablefetchexception') ||
              errorStr.contains('failed host lookup')) {
            errorMessage =
                'Network connection issue. Please check your internet connection.';
          } else {
            // Fallback for completely unknown errors
            errorMessage = _isLogin
                ? 'Sign in failed. Please try again.'
                : 'Unable to create account. Please try again.';
          }
        }

        if (mounted) {
          setState(() {
            _error = errorMessage;
          });
        }
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: TeraiLogo(
                          width: 150,
                          height: 62,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _isLogin ? 'Welcome back' : 'Join the community',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin
                            ? 'Sign in to continue finding people worth building with.'
                            : 'Create an account and meet people working on meaningful problems.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                      ),
                      const SizedBox(height: 28),

                      // Show full name field only during sign-up
                      if (!_isLogin) ...[
                        TextField(
                          controller: _fullName,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline_rounded),
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
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _password,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          helperText:
                              !_isLogin ? 'Minimum 12 characters' : null,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            tooltip: _isPasswordVisible
                                ? 'Hide password'
                                : 'Show password',
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
                                    color:
                                        _password.text == _confirmPassword.text
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

                      // Age verification and Terms checkboxes (only for signup)
                      if (!_isLogin) ...[
                        const SizedBox(height: 20),
                        // Age verification checkbox (COPPA compliance)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _ageVerified,
                              onChanged: (value) {
                                setState(() {
                                  _ageVerified = value ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  'I am at least 13 years old',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Terms and Conditions checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _acceptedTerms,
                              onChanged: (value) {
                                setState(() {
                                  _acceptedTerms = value ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: RichText(
                                  text: TextSpan(
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    children: [
                                      const TextSpan(
                                          text: 'I have read and accept the '),
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () async {
                                            final uri = Uri.parse(
                                                'https://terai.us/legal.html#terms');
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(uri,
                                                  mode: LaunchMode
                                                      .externalApplication);
                                            }
                                          },
                                      ),
                                      const TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () async {
                                            final uri = Uri.parse(
                                                'https://terai.us/legal.html#privacy');
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(uri,
                                                  mode: LaunchMode
                                                      .externalApplication);
                                            }
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3)),
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
                        onPressed: (_loading || (!_isLogin && !_acceptedTerms))
                            ? null
                            : _submit,
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
                                      builder: (context) =>
                                          const ForgotPasswordPageNew(),
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
                                  _fullName
                                      .clear(); // Clear full name when switching
                                  _isPasswordVisible =
                                      false; // Reset password visibility
                                  _isConfirmPasswordVisible =
                                      false; // Reset confirm password visibility
                                  _acceptedTerms =
                                      false; // Reset terms acceptance
                                  _ageVerified =
                                      false; // Reset age verification
                                });
                              },
                        child: Text(_isLogin
                            ? "New to Terai? Create an account"
                            : 'Have an account? Sign in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
