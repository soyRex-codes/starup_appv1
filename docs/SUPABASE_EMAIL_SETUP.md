# Supabase Email Configuration for Password Reset

## Issue: Not Receiving OTP Emails

The password reset system is now properly implemented, but you need to configure Supabase to send emails.

## Configuration Steps:

### 1. Supabase Dashboard Settings

1. Go to your Supabase Dashboard: https://app.supabase.com
2. Select your project
3. Navigate to **Authentication** → **Settings**

### 2. Enable SMTP (Required for Production)

**Option A: Use Custom SMTP Provider (Recommended)**
1. In Auth Settings, scroll to **SMTP Settings**
2. Enable "Enable custom SMTP"
3. Configure your SMTP provider:
   - **Host**: smtp.sendgrid.net (or your provider)
   - **Port**: 587
   - **Username**: Your SMTP username
   - **Password**: Your SMTP password
   - **Sender Email**: noreply@yourdomain.com
   - **Sender Name**: Your App Name

**Option B: Use Supabase Built-in Email (Development Only)**
- For development, Supabase provides limited email sending
- Check if this is enabled in your project settings
- Note: This has daily limits and may not be reliable

### 3. Email Templates Configuration

1. Navigate to **Authentication** → **Email Templates**
2. Find **Reset Password** template
3. Customize the template if needed:
   ```html
   <h2>Reset Your Password</h2>
   <p>You requested a password reset for your account.</p>
   <p>Your reset code is: <strong>{{ .Token }}</strong></p>
   <p>This code expires in 60 minutes.</p>
   <p>If you didn't request this, please ignore this email.</p>
   ```

### 4. URL Configuration

1. In **Authentication** → **URL Configuration**
2. Set **Site URL** to your app's URL
3. Add **Redirect URLs** if needed

### 5. Testing Setup

**For Development Testing:**
1. Use a service like **Mailtrap.io** for testing emails
2. Configure SMTP settings with Mailtrap credentials:
   - Host: smtp.mailtrap.io
   - Port: 2525
   - Username: Your Mailtrap username
   - Password: Your Mailtrap password

### 6. Verification Steps

1. Save all settings in Supabase Dashboard
2. Test the password reset flow:
   ```bash
   # Test in your app or via curl:
   curl -X POST 'https://your-project.supabase.co/auth/v1/recover' \
   -H "apikey: your-anon-key" \
   -H "Content-Type: application/json" \
   -d '{"email": "test@example.com"}'
   ```

### 7. Common Issues & Solutions

**Issue**: "SMTP not configured"
- **Solution**: Enable and configure SMTP settings

**Issue**: "Invalid email template"
- **Solution**: Check email template syntax

**Issue**: "Rate limiting"
- **Solution**: Check rate limits in Auth settings

**Issue**: Emails going to spam
- **Solution**: Configure SPF/DKIM records for your domain

### 8. Alternative: Use Your Own Email Service

If you prefer to handle emails yourself, modify the `PasswordResetService`:

```dart
// In requestPasswordReset method, replace Supabase email with your service:
await _sendCustomOTPEmail(email, otp);

Future<void> _sendCustomOTPEmail(String email, String otp) async {
  // Use SendGrid, AWS SES, or your preferred email service
  // Example with HTTP request to your email API:
  await http.post(
    Uri.parse('https://your-api.com/send-otp'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'email': email,
      'otp': otp,
      'template': 'password_reset'
    }),
  );
}
```

## Next Steps:

1. Configure SMTP in Supabase Dashboard
2. Test the email sending
3. Check spam folders during testing
4. Monitor Supabase logs for email sending errors

Once SMTP is properly configured, you should receive the OTP emails successfully!
