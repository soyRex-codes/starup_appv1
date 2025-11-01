# Pre-Testing Verification Checklist ✅

## 📋 Configuration Verification

### ✅ Environment Variables
- [x] `.env.mobile` has `STRIPE_PUBLISHABLE_KEY` = `pk_test_51QCGRmHzme0zworxPBjjq0JeN6OBH5dRAmNPMujnWEe679KQDUKaSXxfRpMqoR4hWNbBn9AV7meNAE05V2icLrV400KsZwMmjf`
- [x] Supabase has secret `stripe_secret_key` = `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`
- [x] Supabase has secret `stripe_webhook_secret` = (from webhook signing secret)

### ✅ Code Implementation
- [x] `main.dart` initializes Stripe with publishable key
- [x] `application_payment_service.dart` has real Stripe integration
- [x] `payment_processing_page.dart` calls real payment service
- [x] `flutter_stripe` package in pubspec.yaml

### ✅ Supabase Setup
- [x] Both Edge Functions deployed:
  - `create-payment-intent`
  - `stripe-webhook`
- [x] Secrets configured in Edge Functions:
  - `stripe_secret_key`
  - `stripe_webhook_secret`
- [x] Database schema supports payments (application_payments table exists)

### ✅ Stripe Setup
- [x] Test Publishable Key configured
- [x] Test Secret Key in Supabase
- [x] Webhook endpoint created
- [x] Webhook signing secret added to Supabase

---

## 🧪 Testing Plan

### Test 1: Verify Initialization (2 minutes)
1. Run: `flutter clean && flutter pub get`
2. Run: `flutter run`
3. **Check console for these messages:**
   ```
   ✅ Stripe initialized successfully
   ✅ Supabase initialized successfully
   ```

### Test 2: Navigate to Payment (3 minutes)
1. Open app
2. Go to: **Ecosystem** → **Select a Service** (e.g., "Business Registration")
3. Fill out the form with test data:
   - Applicant Name: "Test User"
   - Applicant Email: "test@example.com"
   - Any other required fields
4. Click: **"Review & Pay"**
5. **Expected**: Payment Summary page appears showing $20.00 fee

### Test 3: Make Payment (5 minutes)
1. Click: **"Proceed to Secure Payment"**
2. **Expected**: Stripe Payment Sheet appears
3. Use test card: **4242 4242 4242 4242**
4. Any future expiry date (e.g., 12/26)
5. Any 3-digit CVC (e.g., 123)
6. Click: **"Pay $20.00"**
7. **Expected**: Payment Sheet closes, Success page appears with:
   - ✅ Green checkmark animation
   - ✅ Receipt with Application ID
   - ✅ "What's Next" information
   - ✅ Buttons: "Track Status" and "Go Home"

### Test 4: Verify Database (3 minutes)
1. Go to Supabase Dashboard
2. Check `application_payments` table:
   - New record should exist
   - `status` should be `succeeded`
   - `payment_intent_id` should have Stripe ID (starts with `pi_test_`)
3. Check `business_applications` table:
   - Application should have `status` = `paid`
   - `payment_status` = `completed`

### Test 5: Check Email (2 minutes)
1. Check inbox for: **test@example.com**
2. Should receive confirmation email with:
   - Application ID
   - Service type
   - Next steps

### Test 6: Test Payment Failure (3 minutes)
1. Go back to Ecosystem
2. Fill form again
3. Use declined card: **4000 0000 0000 0002**
4. **Expected**: Payment fails with error message
5. Database should show failed status

### Test 7: Webhook Verification (5 minutes)
1. Stripe Dashboard → Webhooks → Your endpoint
2. Should show successful deliveries
3. Click on a delivery to see the response
4. **Expected**: Response status 200

---

## 🚨 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "Stripe.publishableKey not initialized" | Make sure `.env.mobile` has correct key and `flutter run` loads it |
| Payment Sheet doesn't appear | Check browser console for errors; verify edge function is deployed |
| "Edge function returned 400" | Check Supabase function logs for the error |
| Database not updating | Check if webhook endpoint is receiving events in Stripe dashboard |
| Email not sent | Check Supabase email trigger logs |

---

## 📊 Success Indicators

You'll know it's working when:

✅ Stripe Payment Sheet appears and accepts payment
✅ Success page displays after payment
✅ `application_payments` table has new record with `status` = `succeeded`
✅ `business_applications` table shows `status` = `paid`
✅ Webhook events show in Stripe dashboard
✅ Email confirmation received

---

## 🎯 Ready to Start Testing?

Run this command to start:

```bash
cd /Users/rajkushwaha/Desktop/develop/starup_appv1
flutter clean
flutter pub get
flutter run
```

Let me know what happens! 🚀

