# Stripe Integration Implementation Guide

## Status: Ready for Deployment ✅

All code changes have been completed. Here's what was implemented:

---

## 📋 Changes Summary

### 1. **Supabase Edge Functions** (2 new functions created)

#### `create-payment-intent` Function
- **File**: `/supabase/functions/create-payment-intent/index.ts`
- **Purpose**: Creates Stripe PaymentIntent when user clicks "Pay Now"
- **Triggered by**: Frontend (via `Supabase.functions.invoke()`)
- **Returns**: 
  ```json
  {
    "clientSecret": "pi_xxx_secret_xxx",
    "paymentIntentId": "pi_xxx"
  }
  ```
- **Handles**: Validation, Stripe API calls, error handling with CORS

#### `stripe-webhook` Function  
- **File**: `/supabase/functions/stripe-webhook/index.ts`
- **Purpose**: Receives webhooks from Stripe when payments succeed/fail
- **Triggered by**: Stripe webhooks (payment_intent.succeeded, payment_intent.payment_failed, charge.refunded)
- **Actions**:
  - Verifies webhook signature
  - Updates `application_payments` table status
  - Database triggers auto-sync to `business_applications` table
  - Sends confirmation emails via existing triggers
- **Webhook Events Handled**:
  - `payment_intent.succeeded` → Updates payment status to 'succeeded'
  - `payment_intent.payment_failed` → Updates payment status to 'failed'  
  - `charge.refunded` → Updates payment status to 'refunded'

---

### 2. **Flutter Backend Updates**

#### `/lib/services/application_payment_service.dart`
**Changed**: `processPayment()` method
- **Before**: Simulated payment with 2-second delay
- **After**: Real Stripe integration with:
  1. Calls `create-payment-intent` Edge Function
  2. Initializes Stripe Payment Sheet with `SetupPaymentSheetParameters`
  3. Presents Payment Sheet UI to user
  4. Handles user cancellation and errors
  5. Updates database on completion

**Key Code Changes**:
```dart
// Initialize Payment Sheet
await Stripe.instance.initPaymentSheet(
  paymentSheetParameters: SetupPaymentSheetParameters(
    paymentIntentClientSecret: clientSecret,
    merchantDisplayName: 'FounderVers',
    style: ThemeMode.system,
    googlePay: const PaymentSheetGooglePay(
      merchantCountryCode: 'US',
      testEnv: true, // Use true for testing
    ),
    applePay: const PaymentSheetApplePay(
      merchantCountryCode: 'US',
    ),
  ),
);

// Present to user
await Stripe.instance.presentPaymentSheet();
```

---

### 3. **UI/Widget Updates**

#### `/lib/features/ecosystem/payment_processing_page.dart`
**Changed**: `_processPayment()` method
- Now passes user email, applicant name to payment service
- Updated error handling for real Stripe errors
- User-friendly error messages

---

### 4. **Initialization**

#### `/lib/main.dart`
**Added**:
```dart
import 'package:flutter_stripe/flutter_stripe.dart';

// In _bootstrap():
final stripePublishableKey = dotenv.dotenv.maybeGet('STRIPE_PUBLISHABLE_KEY') ??
    const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

if (stripePublishableKey.isNotEmpty) {
  Stripe.publishableKey = stripePublishableKey;
  await Stripe.instance.applySettings();
  print('✅ Stripe initialized successfully');
}
```

---

### 5. **Environment Configuration**

#### `/env.mobile`
**Added**:
```bash
# Stripe Configuration (PUBLIC - publishable key safe for client)
STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_PUBLISHABLE_KEY_HERE
```

#### **Supabase Secrets** (already configured by you)
- `stripe_secret_key` = sk_test_YOUR_SECRET_KEY (in Edge Function secrets)

---

### 6. **Dependencies**

#### `pubspec.yaml`
```yaml
dependencies:
  flutter_stripe: ^10.0.0
```

#### `supabase/functions/deno.json`
```json
"imports": {
  "stripe": "npm:stripe@14.19.0",
  "@supabase/supabase-js": "npm:@supabase/supabase-js@2.39.7"
}
```

---

## 🚀 Manual Steps Required

### **STEP 1: Add Stripe Publishable Key to `.env.mobile`**

Replace the placeholder:
```bash
STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_PUBLISHABLE_KEY_HERE
```

With your actual test publishable key from Stripe Dashboard.

**Where to find it**: https://dashboard.stripe.com/test/apikeys

---

### **STEP 2: Add Stripe Webhook Secret to Supabase**

You need to create a webhook endpoint first:

1. Go to Stripe Dashboard → Webhooks
2. Click "Add Endpoint"
3. Enter your Supabase function URL:
   ```
   https://YOUR_PROJECT_ID.supabase.co/functions/v1/stripe-webhook
   ```
4. Select events to listen for:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `charge.refunded`
5. Click "Add Endpoint"
6. Click on the created endpoint and find "Signing secret"
7. Add to Supabase Secrets:
   - Go to Supabase → Project Settings → Edge Functions → Secrets
   - Add new secret:
     - **Name**: `stripe_webhook_secret`
     - **Value**: `whsec_xxx...` (from Stripe)

---

### **STEP 3: Verify Edge Function Environment Variables**

Both Edge Functions need access to:
- `stripe_secret_key` ✅ (already added)
- `stripe_webhook_secret` ⚠️ (add from Step 2)
- `SUPABASE_URL` (auto-available)
- `SUPABASE_SERVICE_ROLE_KEY` (auto-available)

---

### **STEP 4: Deploy Edge Functions**

```bash
# Navigate to Supabase CLI
cd supabase

# Deploy functions
supabase functions deploy create-payment-intent
supabase functions deploy stripe-webhook
```

Or use Supabase Dashboard:
- Go to Edge Functions
- Upload/deploy the two new functions

---

### **STEP 5: Test with Flutter**

After deployment, test the payment flow:

1. **Run your Flutter app**:
   ```bash
   flutter run
   ```

2. **Navigate to** → Ecosystem → Select Business Service → Fill Form → Click "Review & Pay"

3. **At Payment Screen**, use Stripe test card:
   - **Card Number**: `4242 4242 4242 4242`
   - **Expiry**: Any future date (e.g., `12/25`)
   - **CVC**: Any 3 digits (e.g., `123`)

4. **Expected Flow**:
   ```
   User clicks "Pay $20.00"
   ↓
   Payment Sheet appears (native UI)
   ↓
   User enters test card
   ↓
   Stripe processes payment
   ↓
   Database webhook updates status
   ↓
   Success page displays
   ↓
   Email confirmation sent
   ```

---

## 🔍 Testing Checklist

### Frontend Testing
- [ ] Stripe Payment Sheet displays correctly
- [ ] Can enter test card details
- [ ] Success page shows after payment
- [ ] Error page shows if payment fails
- [ ] User can cancel payment without error

### Database Testing
```sql
-- Check payment record created
SELECT * FROM application_payments 
ORDER BY created_at DESC LIMIT 1;

-- Check webhook updated status
SELECT status, payment_intent_id 
FROM application_payments 
WHERE application_id = <your_app_id>;

-- Check application status updated
SELECT status, payment_status, paid_at 
FROM business_applications 
WHERE id = <your_app_id>;
```

### Webhook Testing
```bash
# In Stripe Dashboard → Webhooks → select your endpoint
# Click "Send test event"
# Select "payment_intent.succeeded"
# Verify your database status updates
```

---

## 🎯 Deployment Checklist

Before going to production:

### Pre-Production Testing
- [ ] Test with all Stripe test card types
- [ ] Test payment failures
- [ ] Test webhook delivery
- [ ] Test email notifications
- [ ] Verify database transactions

### Production Deployment
- [ ] Get production Stripe keys (pk_live_xxx, sk_live_xxx)
- [ ] Update `.env.mobile` with production publishable key
- [ ] Update Supabase secrets with production secret key
- [ ] Set `testEnv: false` in Payment Sheet parameters
- [ ] Update Stripe webhook endpoint (production)
- [ ] Deploy functions to production

---

## 📚 How It Works (Complete Flow)

```
┌─────────────────────────────────────────────────────────────┐
│                    PAYMENT FLOW DIAGRAM                      │
└─────────────────────────────────────────────────────────────┘

1. USER INITIATES PAYMENT
   ├─ Clicks "Pay $20.00" button on payment_processing_page
   └─ App validates and calls processPayment()

2. CREATE PAYMENT INTENT
   ├─ Flutter calls: supabase.functions.invoke('create-payment-intent')
   ├─ Edge Function receives request
   ├─ Function calls Stripe API: paymentIntents.create()
   └─ Returns clientSecret to Flutter

3. SHOW PAYMENT SHEET
   ├─ Flutter initializes Stripe Payment Sheet
   ├─ Native payment UI presented to user
   ├─ User enters card details
   └─ User confirms payment

4. STRIPE PROCESSES
   ├─ Stripe validates card
   ├─ Processes payment
   ├─ Sends webhook to stripe-webhook function
   └─ Payment status: succeeded/failed/refunded

5. WEBHOOK HANDLES STATUS
   ├─ stripe-webhook function receives event
   ├─ Verifies webhook signature
   ├─ Updates application_payments table
   └─ Database trigger fires

6. DATABASE TRIGGER
   ├─ Detects payment_status = 'succeeded'
   ├─ Updates business_applications.status = 'paid'
   ├─ Calls existing trigger for email
   └─ Confirmation email sent to user

7. SUCCESS PAGE
   ├─ Flutter detects webhook completion via polling or socket
   ├─ Shows success animation
   ├─ Displays receipt with application ID
   └─ User can track status or go home
```

---

## 🛠️ Troubleshooting

### Payment Sheet Not Showing
- **Check**: Stripe publishable key is set in main.dart
- **Check**: STRIPE_PUBLISHABLE_KEY exists in .env.mobile
- **Solution**: Verify keys match your Stripe Dashboard

### Webhook Not Firing
- **Check**: Webhook endpoint configured in Stripe Dashboard
- **Check**: stripe_webhook_secret added to Supabase Secrets
- **Solution**: Test webhook delivery in Stripe Dashboard → Webhooks

### Database Not Updating
- **Check**: Edge Function has SUPABASE_SERVICE_ROLE_KEY access
- **Check**: RLS policies on application_payments table
- **Solution**: Verify service role has UPDATE permissions

### Cards Declined in Test Mode
- **Use official Stripe test cards**: https://stripe.com/docs/testing
- **Common test card**: 4242 4242 4242 4242
- **Declined card**: 4000 0000 0000 0002

---

## 📝 Files Modified/Created

### New Files (2)
```
/supabase/functions/create-payment-intent/index.ts
/supabase/functions/stripe-webhook/index.ts
```

### Updated Files (5)
```
/lib/main.dart                                          (Stripe initialization)
/lib/services/application_payment_service.dart         (Real payment processing)
/lib/features/ecosystem/payment_processing_page.dart   (UI updates)
/.env.mobile                                            (Stripe publishable key)
/supabase/functions/deno.json                          (Stripe npm packages)
/pubspec.yaml                                           (Fixed duplicate dependencies)
```

---

## ✅ Integration Complete!

All code changes are ready. The next steps are purely configuration (adding keys and deploying Edge Functions).

**Need Help?**
- Stripe docs: https://stripe.com/docs/payments/payment-sheet
- Flutter Stripe: https://pub.dev/packages/flutter_stripe
- Test in Stripe dashboard: https://dashboard.stripe.com/test

---

**Last Updated**: October 31, 2025
**Status**: ✅ Code Ready for Production
