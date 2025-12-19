import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:foundervers/services/password_reset_service.dart';
import 'package:foundervers/features/auth/auth_service.dart';

/// Email Verification OTP Page - for signup email verification
class EmailVerificationOtpPage extends StatefulWidget {
  final String email;

  const EmailVerificationOtpPage({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationOtpPage> createState() => _EmailVerificationOtpPageState();
}

class _EmailVerificationOtpPageState extends State<EmailVerificationOtpPage> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _resendTimer;
  int _resendCountdown = 0;
  static const int _resendCooldownSeconds = 60;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  bool get _isOtpComplete => _otpController.text.trim().length == 6;
  bool get _canResend => _resendCountdown == 0;

  void _startResendCooldown() {
    _resendCountdown = _resendCooldownSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (!_isOtpComplete || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await PasswordResetService.instance.verifyEmailVerificationOTP(
        email: widget.email,
        otp: _otpController.text.trim(),
      );

      if (mounted) {
        if (result['success']) {
          // Mark email as verified in our users table
          await AuthService.instance.markEmailAsVerified();
          
          if (!mounted) return;

          // Email verified successfully - session should now be active
          // AuthGate will automatically navigate to home page
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully! Welcome to FounderVers!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _errorMessage = result['message'];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Network error. Please check your connection and try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await PasswordResetService.instance.requestEmailVerification(
        email: widget.email,
      );

      if (mounted) {
        if (result['success'] == true) {
          _startResendCooldown();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code sent!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Handle rate limiting and other errors
          final message = result['message'] ?? 'Failed to resend code';
          if (message.contains('wait') || message.contains('rate')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            setState(() {
              _errorMessage = message;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to resend code. Please try again later.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkEmailConfirmation() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await PasswordResetService.instance.confirmEmailFromLink(
        email: widget.email,
      );

      if (mounted) {
        if (result['success'] == true) {
          // Email was confirmed via link
          await AuthService.instance.markEmailAsVerified();
          
          if (!mounted) return;

          Navigator.of(context).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully! Welcome to FounderVers!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Email not yet confirmed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to check email status. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.email_outlined,
                  size: 40,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Verify Your Email',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'We sent a verification email to',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              Text(
                widget.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Instructions for both OTP and link
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Check your email for:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• A 6-digit verification code (enter below)\n• OR a confirmation link (click to verify)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                          ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // OTP Input
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                enabled: !_isLoading,
                autofocus: true,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.w600,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    letterSpacing: 8,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  counterText: '', // Hide character counter
                ),
                onChanged: (value) {
                  setState(() {
                    _errorMessage = null;
                  });
                  // Auto-verify when 6 digits entered
                  if (value.length == 6) {
                    _verifyOtp();
                  }
                },
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isOtpComplete && !_isLoading ? _verifyOtp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Verify Email',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Resend Code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t receive the code? ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  TextButton(
                    onPressed: _canResend && !_isLoading ? _resendCode : null,
                    child: Text(
                      _canResend
                          ? 'Resend'
                          : 'Resend in ${_resendCountdown}s',
                      style: TextStyle(
                        color: _canResend
                            ? Theme.of(context).primaryColor
                            : Colors.grey[400],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Check if email was confirmed via link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Clicked the email link? ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  TextButton(
                    onPressed: !_isLoading ? _checkEmailConfirmation : null,
                    child: Text(
                      'Check Status',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Security Notice
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: Colors.amber[700],
                      size: 28,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Security Notice',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This code expires in 15 minutes for your security. Don\'t share it with anyone.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.amber[700],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}