import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:foundervers/services/password_reset_service.dart';
import 'package:foundervers/features/auth/password_reset_new_password_page.dart';

/// Screen 2: Enter Reset Code - OTP Verification
/// Mobile-first password reset flow step 2
class PasswordResetOtpPage extends StatefulWidget {
  final String email;

  const PasswordResetOtpPage({
    super.key,
    required this.email,
  });

  @override
  State<PasswordResetOtpPage> createState() => _PasswordResetOtpPageState();
}

class _PasswordResetOtpPageState extends State<PasswordResetOtpPage> {
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
      final result = await PasswordResetService.instance.verifyOTP(
        email: widget.email,
        otp: _otpController.text.trim(),
      );

      if (mounted) {
        if (result['success']) {
          // Navigate to password reset screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PasswordResetNewPasswordPage(
                email: widget.email,
                otp: _otpController.text.trim(),
              ),
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
      await PasswordResetService.instance.requestPasswordReset(
        email: widget.email,
      );

      if (mounted) {
        _startResendCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset code sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to resend code. Please try again.';
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
        title: const Text('Enter Reset Code'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Header Section
              Icon(
                Icons.security,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),

              Text(
                'Enter Reset Code',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'We sent a 6-digit code to',
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
              const SizedBox(height: 40),

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
                  LengthLimitingTextInputFormatter(6),
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
                        color: Theme.of(context).primaryColor, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  counterText: '', // Hide character counter
                ),
                onChanged: (_) => setState(() {}), // Update button state
                onFieldSubmitted: (_) => _verifyOtp(),
              ),
              const SizedBox(height: 32),

              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style:
                              TextStyle(color: Colors.red[700], fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Verify Code Button
              ElevatedButton(
                onPressed: (_isOtpComplete && !_isLoading) ? _verifyOtp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Verify Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Resend Code Section
              Column(
                children: [
                  Text(
                    'Didn\'t receive the code?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _canResend && !_isLoading ? _resendCode : null,
                    child: Text(
                      _canResend ? 'Resend' : 'Resend in ${_resendCountdown}s',
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
              const SizedBox(height: 40),

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
