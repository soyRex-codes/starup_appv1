# 🚀 Quick Start Commands for Testing

## Step 1: Clean and Setup (1-2 minutes)

```bash
# Navigate to project
cd /Users/rajkushwaha/Desktop/develop/starup_appv1

# Clean previous build
flutter clean

# Get dependencies
flutter pub get

# Verify no errors
flutter analyze
```

Expected output: No major errors, just warnings are OK.

---

## Step 2: Run the App (30 seconds)

```bash
# For iPhone simulator
flutter run -d iPhone

# For Android emulator
flutter run -d android

# Or just run (picks available device)
flutter run
```

Expected output:
```
✅ Stripe initialized successfully
✅ Supabase initialized successfully
✨ Built ...
🎉 Flutter app is ready in X seconds
```

---

## Step 3: Navigate to Payment Flow

In the app:

1. **Tap**: "Ecosystem" (or "Business Services" - whatever your nav calls it)
2. **Tap**: Select a service (e.g., "Business Registration")
3. **Fill form**: Required fields with test data
4. **Tap**: "Review & Pay" button
5. **Expected**: Payment Summary page with $20.00 fee

---

## Step 4: Process Payment

1. **Tap**: "Proceed to Secure Payment"
2. **Wait**: Stripe Payment Sheet loads (2-3 seconds)
3. **Enter test card**:
   - Card: `4242 4242 4242 4242`
   - Expiry: `12/26` (or any future date)
   - CVC: `123` (or any 3 digits)
   - ZIP: `12345` (or any 5 digits)
4. **Tap**: "Pay $20.00" button
5. **Expected**: Success page appears

---

## Step 5: Verify in Console

While app is running, watch the terminal for logs:

```
[INFO] Creating payment record...
[INFO] Calling edge function: create-payment-intent
[INFO] Received PaymentIntent: pi_test_xxxxx
[INFO] Initializing Stripe Payment Sheet
[INFO] Payment Sheet dismissed - success!
[INFO] Updating payment record with intent ID
[INFO] Payment succeeded!
```

---

## Step 6: Check Database

### Using Supabase Dashboard:

1. Go to: https://app.supabase.com
2. Select your project
3. Go to: **SQL Editor** or **Table Editor**
4. Run this query:

```sql
-- Check latest payment
SELECT * FROM application_payments 
ORDER BY created_at DESC 
LIMIT 1;

-- Check application status
SELECT id, status, payment_status, paid_at 
FROM business_applications 
ORDER BY created_at DESC 
LIMIT 1;
```

Expected result:
```
payment record:
- status: "succeeded"
- payment_intent_id: "pi_test_..."
- amount: 20.00

application record:
- status: "paid"
- payment_status: "completed"
- paid_at: (timestamp)
```

---

## Step 7: Check Email

1. Check the email inbox for: `test@example.com` (or whatever you used)
2. Look for email titled: "Application Received - FounderVers"
3. Should contain:
   - Application ID
   - Service type
   - Next steps

---

## Step 8: Test Webhook in Stripe

1. Go to: https://dashboard.stripe.com/webhooks
2. Find your endpoint
3. Click on it
4. Look at "Recent Events"
5. Should see: `payment_intent.succeeded` events
6. Click one to see the response (should be 200)

---

## 🐛 Debugging Commands

If something goes wrong, try these:

### View Flutter logs in detail:
```bash
flutter run -v
```

### Check for any code errors:
```bash
flutter analyze
```

### View only Stripe-related logs:
```bash
flutter run 2>&1 | grep -i stripe
```

### View only Supabase-related logs:
```bash
flutter run 2>&1 | grep -i supabase
```

---

## 📋 Quick Checklist During Testing

- [ ] App starts with "Stripe initialized successfully" message
- [ ] Can navigate to Ecosystem and select service
- [ ] Payment Summary page shows $20.00
- [ ] Stripe Payment Sheet appears with "Pay $20.00" button
- [ ] Payment sheet accepts test card and processes
- [ ] Success page appears with animation
- [ ] Database has new payment record
- [ ] Application status changed to "paid"
- [ ] Webhook shows successful delivery in Stripe

---

## ✅ Success!

If all the above work, your Stripe integration is **100% complete** and **production-ready**! 🎉

---

## 🆘 Need Help?

Check these files for error details:

1. **Flutter errors**: Terminal where you ran `flutter run`
2. **Supabase Edge Function logs**: 
   - Supabase Dashboard → Functions → create-payment-intent → Logs
   - Supabase Dashboard → Functions → stripe-webhook → Logs
3. **Stripe webhook logs**: 
   - https://dashboard.stripe.com/webhooks → Click your endpoint → Events

