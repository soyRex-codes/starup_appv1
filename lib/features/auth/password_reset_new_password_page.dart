import 'package:flutter/material.dart';
import 'package:foundervers/services/password_reset_service.dart';

/// Screen 3: Set New Password - Final Step
/// Mobile-first password reset flow step 3
class PasswordResetNewPasswordPage extends StatefulWidget {
  final String email;
  final String otp;

  const PasswordResetNewPasswordPage({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<PasswordResetNewPasswordPage> createState() =>
      _PasswordResetNewPasswordPageState();
}

class _PasswordResetNewPasswordPageState
    extends State<PasswordResetNewPasswordPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isPasswordValid =>
      _validatePasswordStrength(_newPasswordController.text)['valid'];
  bool get _doPasswordsMatch =>
      _newPasswordController.text == _confirmPasswordController.text;
  bool get _canSubmit =>
      _isPasswordValid &&
      _doPasswordsMatch &&
      _newPasswordController.text.isNotEmpty;

  Map<String, dynamic> _validatePasswordStrength(String password) {
    if (password.isEmpty) {
      return {'valid': false, 'message': 'Password cannot be empty'};
    }
    if (password.length < 8) {
      return {
        'valid': false,
        'message': 'Password must be at least 8 characters'
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
    return {'valid': true, 'message': 'Password meets requirements'};
  }

  List<Widget> _buildPasswordRequirements() {
    final password = _newPasswordController.text;
    final requirements = [
      {'text': 'At least 8 characters', 'met': password.length >= 8},
      {
        'text': 'One uppercase letter',
        'met': password.contains(RegExp(r'[A-Z]'))
      },
      {
        'text': 'One lowercase letter',
        'met': password.contains(RegExp(r'[a-z]'))
      },
      {'text': 'One number', 'met': password.contains(RegExp(r'[0-9]'))},
      {
        'text': 'One special character',
        'met': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))
      },
    ];

    return requirements.map((req) {
      final isMet = req['met'] as bool;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              isMet ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: isMet ? Colors.green[600] : Colors.grey[400],
            ),
            const SizedBox(width: 8),
            Text(
              req['text'] as String,
              style: TextStyle(
                fontSize: 12,
                color: isMet ? Colors.green[600] : Colors.grey[600],
                fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate() || !_canSubmit || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await PasswordResetService.instance.resetPassword(
        email: widget.email,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        if (result['success']) {
          _showSuccessDialog();
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 28),
            const SizedBox(width: 12),
            const Text('Success!'),
          ],
        ),
        content: const Text(
          'Your password has been reset successfully. You can now sign in with your new password.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context)
                  .popUntil((route) => route.isFirst); // Return to sign in
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    final validation = _validatePasswordStrength(value);
    if (!validation['valid']) {
      return validation['message'];
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set New Password'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Header Section
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),

                Text(
                  'Create New Password',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Text(
                  'Please create a strong password to secure your account.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // New Password Input
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_isNewPasswordVisible,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Enter your new password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isNewPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        });
                      },
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
                  ),
                  validator: _validatePassword,
                  onChanged: (_) =>
                      setState(() {}), // Update requirements display
                ),
                const SizedBox(height: 16),

                // Password Requirements
                if (_newPasswordController.text.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password Requirements:',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                        ),
                        const SizedBox(height: 8),
                        ..._buildPasswordRequirements(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Confirm Password Input
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your new password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
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
                  ),
                  validator: _validateConfirmPassword,
                  onChanged: (_) => setState(() {}), // Update button state
                  onFieldSubmitted: (_) => _resetPassword(),
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

                // Reset Password Button
                ElevatedButton(
                  onPressed:
                      (_canSubmit && !_isLoading) ? _resetPassword : null,
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
                          'Update Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 40),

                // Success Indicator
                if (_doPasswordsMatch &&
                    _isPasswordValid &&
                    _newPasswordController.text.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green[600], size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Password meets all requirements and matches confirmation',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
