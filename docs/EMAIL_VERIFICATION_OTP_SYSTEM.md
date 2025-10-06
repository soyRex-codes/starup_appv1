# Email Verification OTP System

## Overview

This system implements email verification during user signup using the same OTP (One-Time Passcode) infrastructure as password reset. When users sign up, they receive a 6-digit verification code via email, which they must enter to verify their email address.

## Key Features

✅ **Unified OTP System**: Reuses the existing password reset OTP infrastructure
✅ **Consistent UX**: Same UI patterns as password reset for familiarity
✅ **Security**: Same security measures as password reset (15-min expiry, 3 attempts, hashed storage)
✅ **No Over-engineering**: Minimal changes to existing codebase

## How It Works

### 1. Signup Flow
1. User fills out signup form (email, password, full name)
2. `AuthService.registerWithEmailPassword()` creates the user account
3. If user needs email verification, app calls `PasswordResetService.requestEmailVerification()`
4. User is navigated to `EmailVerificationOtpPage`

### 2. Email Verification Flow
1. 6-digit OTP is sent to user's email
2. User enters OTP in the verification page
3. `PasswordResetService.verifyEmailVerificationOTP()` validates the code
4. If valid, user's `email_verified` status is updated in the database
5. User is redirected back to sign-in with success message

### 3. Database Changes
- Added `purpose` column to `password_reset_otps` table
- Purpose can be `'reset'` (password reset) or `'signup'` (email verification)
- Same security model and expiry rules apply

## Files Added/Modified

### New Files
- `lib/features/auth/email_verification_otp_page.dart` - Email verification UI
- `migrations/20251002_email_verification_otp_system.sql` - Database migration

### Modified Files
- `lib/services/password_reset_service.dart` - Added email verification methods
- `lib/features/auth/auth_service.dart` - Added email verification helper methods
- `lib/features/auth/sign_in_page.dart` - Updated signup flow to use OTP verification
- `main_mobile_app_database_schema.sql` - Updated schema with purpose column

## Usage

### Request Email Verification
```dart
final result = await PasswordResetService.instance.requestEmailVerification(
  email: 'user@example.com',
);

if (result['success']) {
  // Navigate to OTP page
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EmailVerificationOtpPage(email: email),
    ),
  );
}
```

### Verify OTP
```dart
final result = await PasswordResetService.instance.verifyEmailVerificationOTP(
  email: 'user@example.com',
  otp: '123456',
);

if (result['success']) {
  // Email verified successfully
  // User can now sign in
}
```

## Security Features

- **Same as Password Reset**: 15-minute expiry, 3 attempts max, SHA-256 hashed storage
- **Anti-enumeration**: Generic success messages regardless of email existence
- **Rate limiting**: Built into Supabase Auth OTP system
- **Secure storage**: OTPs are never stored in plain text

## Benefits

1. **Consistent UX**: Users get the same experience for both password reset and email verification
2. **Minimal Code**: Reuses existing OTP infrastructure
3. **Battle-tested**: Uses the same security measures as the existing password reset system
4. **Easy Maintenance**: Single codebase for all OTP functionality

## Migration

Run the migration to add the `purpose` column:

```sql
-- Apply the migration
\i migrations/20251002_email_verification_otp_system.sql
```

The migration is safe and backwards-compatible - existing password reset functionality continues to work unchanged.