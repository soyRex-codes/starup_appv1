import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:foundervers/services/password_reset_service.dart';
import 'package:foundervers/features/auth/password_reset_new_password_page.dart';
import 'package:foundervers/features/auth/auth_service.dart';

/// Generic OTP Verification Page
/// Handles both password reset and email verification (signup confirmation)
class OtpVerificationPage extends StatefulWidget {
  final String email;
  final OtpType type;
  final String title;
  final String description;

  const OtpVerificationPage({
    super.key,
    required this.email,
    required this.type,
    required this.title,
    required this.description,
  });

  /// Factory constructor for password reset
  factory OtpVerificationPage.passwordReset(String email) {
    return OtpVerificationPage(
      email: email,
      type: OtpType.passwordReset,
      title: 'Reset Your Password',
      description: 'Enter the 6-digit code sent to your email to reset your password.',
    );
  }

  /// Factory constructor for email verification (signup)
  factory OtpVerificationPage.emailVerification(String email) {
    return OtpVerificationPage(
      email: email,
      type: OtpType.emailVerification,
      title: 'Verify Your Email',
      description: 'Enter the 6-digit code sent to your email to verify your account.',
    );
  }

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

enum OtpType { passwordReset, emailVerification }

class _OtpVerificationPageState extends State<OtpVerificationPage> {
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
      final otp = _otpController.text.trim();
      Map<String, dynamic> result;

      if (widget.type == OtpType.passwordReset) {
        result = await PasswordResetService.instance.verifyOTP(
          email: widget.email,
          otp: otp,
        );
      } else {
        result = await PasswordResetService.instance.verifyEmailVerificationOTP(
          email: widget.email,
          otp: otp,
        );
      }

      if (mounted) {
        if (result['success']) {
          if (widget.type == OtpType.passwordReset) {
            // Navigate to new password page
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => PasswordResetNewPasswordPage(
                  email: widget.email,
                  otp: otp,
                ),
              ),
            );
          } else {
            // Email verification successful - mark as verified and go home
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
          }
        } else {
          setState(() {
            _errorMessage = result['message'];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Verification failed. Please try again.';
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
      Map<String, dynamic> result;

      if (widget.type == OtpType.passwordReset) {
        result = await PasswordResetService.instance.requestPasswordReset(
          email: widget.email,
        );
      } else {
        result = await PasswordResetService.instance.requestEmailVerification(
          email: widget.email,
        );
      }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         kToolbarHeight,
            ),
            child: Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  
                  // Title and Description
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.015),

                  Text(
                    widget.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),

                  Text(
                    widget.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                  // OTP Input
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    enabled: !_isLoading,
                    autofocus: true,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.06,
                      letterSpacing: MediaQuery.of(context).size.width * 0.02,
                      fontWeight: FontWeight.w600,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      hintText: '000000',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        letterSpacing: MediaQuery.of(context).size.width * 0.02,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                      counterText: '',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _errorMessage = null;
                      });
                      if (value.length == 6) {
                        _verifyOtp();
                      }
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                  // Error Message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
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
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
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
                          : Text(
                              widget.type == OtpType.passwordReset ? 'Verify Code' : 'Verify Email',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                  // Resend Code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'Didn\'t receive the code? ',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
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

                  SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                  // Security Notice
                  Container(
                    padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.security, color: Colors.blue[700], size: 24),
                        const SizedBox(height: 8),
                        Text(
                          'Security Notice',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This code will expire in 5 minutes for your security. Never share this code with anyone.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.blue[600],
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Bottom spacing for scroll
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}