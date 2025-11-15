# 📧 Applicant Confirmation Email Setup Guide

## Overview
This guide will help you set up automatic confirmation emails that are sent to users immediately after they submit a business service application.

## ✨ Features

### What Applicants Receive:
- ✅ **Instant confirmation email** with professional design
- 📋 **Application details** (ID, service type, submission time)
- ⏱️ **Timeline** of what happens next (3-step process)
- 🔗 **Track application** link to check status
- 💼 **Professional branding** with FounderVers design

### Email Contents:
1. **Header**: Beautiful gradient with checkmark icon
2. **Greeting**: Personalized with applicant name
3. **Confirmation message**: Clear confirmation of receipt
4. **Application details box**: All key information at a glance
5. **Timeline**: What happens next (Review → Assignment → Contact)
6. **CTA button**: Link to track application status
7. **Important notice**: 48-hour response time + spam folder reminder
8. **Footer**: Contact info and social links

---

## 🚀 Setup Instructions

### Step 1: Deploy Edge Function

The confirmation email is sent via a Supabase Edge Function.

```bash
# Navigate to your project directory
cd /Users/rajkushwaha/Desktop/develop/starup_appv1

# Deploy the edge function
supabase functions deploy send-application-confirmation

# Verify deployment
supabase functions list
```

**Expected output:**
```
send-application-confirmation    deployed    [timestamp]
```

---

### Step 2: Configure Email Service (Resend)

We use [Resend](https://resend.com) for reliable email delivery.

#### 2.1 Create Resend Account
1. Go to https://resend.com
2. Sign up for free account (100 emails/day free tier)
3. Verify your email address

#### 2.2 Add Your Domain (Recommended for Production)
1. Go to **Domains** in Resend Dashboard
2. Click **Add Domain**
3. Add your domain (e.g., `foundervers.com`)
4. Add DNS records as instructed
5. Wait for verification (usually 15 minutes)

**OR** use Resend's test domain for development:
- Test emails will be sent from `onboarding@resend.dev`
- Limited to verified recipients only

#### 2.3 Get API Key
1. Go to **API Keys** in Resend Dashboard
2. Click **Create API Key**
3. Name it: `FounderVers Production` or `FounderVers Development`
4. Copy the API key (starts with `re_`)

#### 2.4 Add API Key to Supabase
1. Go to Supabase Dashboard
2. Navigate to **Project Settings** → **Edge Functions**
3. Scroll to **Environment Variables**
4. Click **Add Variable**
   - Name: `RESEND_API_KEY`
   - Value: `re_your_api_key_here`
5. Click **Save**

---

### Step 3: Configure Database

#### 3.1 Enable HTTP Extension
Run in Supabase SQL Editor:
```sql
CREATE EXTENSION IF NOT EXISTS http;
```

#### 3.2 Set Supabase Configuration
Get your credentials:
- **Project URL**: Supabase Dashboard → Project Settings → API → Project URL
- **Service Role Key**: Supabase Dashboard → Project Settings → API → service_role key (secret)

Run in Supabase SQL Editor (replace with your actual values):
```sql
ALTER DATABASE postgres SET app.supabase_url = 'https://your-project-ref.supabase.co';
ALTER DATABASE postgres SET app.supabase_service_key = 'your-service-role-key-here';
```

⚠️ **SECURITY**: Never commit these values to git!

#### 3.3 Apply Migration
Run the migration script:
```bash
# Option A: Via Supabase CLI
supabase db push

# Option B: Via SQL Editor
# Copy contents of add_applicant_confirmation_email.sql
# Paste into Supabase Dashboard → SQL Editor
# Click "Run"
```

---

### Step 4: Verify Setup

#### 4.1 Check Database Components
Run in SQL Editor:
```sql
-- Check if http extension is enabled
SELECT * FROM pg_extension WHERE extname = 'http';

-- Check if function exists
SELECT proname FROM pg_proc WHERE proname = 'send_applicant_confirmation_email';

-- Check if trigger exists
SELECT tgname FROM pg_trigger WHERE tgname = 'send_applicant_confirmation';

-- Verify configuration
SELECT current_setting('app.supabase_url', true) as supabase_url;
```

All queries should return results.

#### 4.2 Test with Real Application
1. Open your app
2. Go to **Business Services** section
3. Fill out and submit an application
4. Use your real email address
5. Check your inbox for confirmation email
6. Check spam folder if not received within 1 minute

#### 4.3 Check Logs
Monitor in Supabase Dashboard:
- **Database** → **Logs** → Look for "Confirmation email sent"
- **Edge Functions** → **send-application-confirmation** → **Logs**

Expected log messages:
```
NOTICE: Confirmation email sent to user@example.com for application 123
```

---

## 🧪 Testing

### Test Script
```sql
-- Insert test application
INSERT INTO business_applications (
  service_type,
  applicant_name,
  applicant_email,
  form_data,
  status
) VALUES (
  'business_consultation',
  'Test User',
  'your-email@example.com',  -- Use your actual email
  '{"business_name": "Test Business", "description": "Test submission"}'::jsonb,
  'pending'
) RETURNING id;

-- Check your email inbox (should receive confirmation within seconds)

-- Clean up test data
DELETE FROM business_applications WHERE applicant_email = 'your-email@example.com';
```

### What to Check:
- ✅ Email arrives within 5-10 seconds
- ✅ From address shows "FounderVers <noreply@foundervers.com>"
- ✅ Subject line: "✅ Application Received - [Service Type] | FounderVers"
- ✅ Email HTML renders correctly (no broken formatting)
- ✅ Application ID matches database
- ✅ All personalization works (name, service type, etc.)
- ✅ Links work correctly
- ✅ Plain text fallback works (disable HTML in email client)

---

## 🔧 Troubleshooting

### Problem: No email received

**Check 1: Spam folder**
- Confirmation emails might be filtered to spam initially
- Add noreply@foundervers.com to contacts

**Check 2: Database logs**
```sql
-- Check if trigger fired
SELECT * FROM pg_stat_user_tables WHERE relname = 'business_applications';

-- Check trigger is enabled
SELECT tgname, tgenabled FROM pg_trigger WHERE tgname = 'send_applicant_confirmation';
```

**Check 3: Edge Function logs**
- Go to Supabase Dashboard
- Edge Functions → send-application-confirmation → Logs
- Look for errors or "No RESEND_API_KEY found"

**Check 4: Resend Dashboard**
- Go to Resend Dashboard → Emails
- Check if email shows as sent/delivered/bounced

### Problem: "Failed to send confirmation email"

**Cause**: Edge Function not deployed
```bash
supabase functions deploy send-application-confirmation
```

**Cause**: Missing RESEND_API_KEY
- Add to Supabase Edge Functions environment variables

**Cause**: Invalid API key
- Generate new API key in Resend Dashboard
- Update in Supabase

### Problem: "Error calling Edge Function"

**Cause**: Missing Supabase configuration
```sql
-- Verify settings exist
SELECT current_setting('app.supabase_url', true);
SELECT current_setting('app.supabase_service_key', true);

-- If NULL, set them:
ALTER DATABASE postgres SET app.supabase_url = 'https://your-project.supabase.co';
ALTER DATABASE postgres SET app.supabase_service_key = 'your-service-key';
```

### Problem: Email sends but looks broken

**Cause**: HTML rendering issue in email client
- Test in multiple clients (Gmail, Outlook, Apple Mail)
- Check plain text version works

**Cause**: Missing email template
- Verify edge function deployed correctly
- Check function code in Supabase Dashboard

---

## 📊 Monitoring

### Check Email Delivery Stats
Resend Dashboard:
- **Overview**: Daily email volume
- **Emails**: Individual email status
- **Analytics**: Open rates, click rates (if tracking enabled)

### Check Application Submission Rate
```sql
-- Applications submitted today
SELECT COUNT(*) as today_applications
FROM business_applications
WHERE DATE(created_at) = CURRENT_DATE;

-- Applications by service type (last 7 days)
SELECT 
  service_type,
  COUNT(*) as count
FROM business_applications
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY service_type
ORDER BY count DESC;

-- Email delivery success rate
SELECT 
  DATE(created_at) as date,
  COUNT(*) as total_applications,
  COUNT(CASE WHEN applicant_email IS NOT NULL THEN 1 END) as emails_expected
FROM business_applications
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

---

## 🎨 Customization

### Change Email Design
Edit: `supabase/functions/send-application-confirmation/index.ts`

```typescript
// Customize colors
background: linear-gradient(135deg, #YOUR_COLOR 0%, #YOUR_COLOR2 100%);

// Customize text
subject: `✅ Your Custom Subject - ${service_type_display} | FounderVers`

// Customize timeline steps
// Find "What Happens Next?" section and modify

// Redeploy after changes
supabase functions deploy send-application-confirmation
```

### Change Email Sender
Resend Dashboard → Domains → Verify Domain
Update function:
```typescript
from: 'Your Name <noreply@yourdomain.com>'
```

### Add More Data to Email
Edit function to include more form_data fields:
```typescript
business_description: formData.description,
company_size: formData.company_size,
// etc.
```

---

## 🔒 Security Best Practices

1. **Never log service role key** in application code
2. **Use environment variables** for all sensitive config
3. **Validate email addresses** before sending
4. **Rate limit** application submissions (add to RLS policies)
5. **Monitor** for abuse via Supabase logs
6. **Review** Resend bounce reports regularly

---

## 📈 Next Steps

### Recommended Enhancements:
1. **Add application tracking page** where users can view status
2. **Send status update emails** when application is reviewed/completed
3. **Add email preferences** (allow users to opt out)
4. **Track email opens** (optional, via Resend analytics)
5. **A/B test** email designs to improve open rates
6. **Add SMS notifications** for high-priority applications

### Database Indexes for Performance:
```sql
-- If you have many applications, add indexes
CREATE INDEX IF NOT EXISTS idx_business_applications_email 
ON business_applications(applicant_email);

CREATE INDEX IF NOT EXISTS idx_business_applications_created 
ON business_applications(created_at DESC);
```

---

## 📝 Summary

✅ **Confirmation emails** are now automatically sent to applicants
✅ **Professional design** with timeline and tracking link
✅ **Reliable delivery** via Resend
✅ **Error handling** ensures submissions never fail
✅ **Monitoring** via Supabase + Resend dashboards

**Total Setup Time**: ~15-20 minutes

**Cost**: Free (up to 100 emails/day with Resend free tier)

Need help? Check Supabase logs or Resend dashboard for detailed error messages.
