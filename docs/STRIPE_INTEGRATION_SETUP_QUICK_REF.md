# Stripe Integration - Quick Setup Checklist ✓

## 🎯 Your Next Steps (In Order)

### Phase 1: Configuration (15 minutes)

- [ ] **Step 1**: Add Stripe Publishable Key to `.env.mobile`
  ```bash
  STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_KEY_HERE
  ```
  Get it from: https://dashboard.stripe.com/test/apikeys

- [ ] **Step 2**: Create Stripe Webhook Endpoint
  1. Go to: https://dashboard.stripe.com/webhooks
  2. Click "Add an endpoint"
  3. Enter: `https://YOUR_PROJECT_ID.supabase.co/functions/v1/stripe-webhook`
  4. Select Events:
     - `payment_intent.succeeded`
     - `payment_intent.payment_failed`
     - `charge.refunded`
  5. Copy the "Signing secret" (looks like `whsec_xxx...`)

- [ ] **Step 3**: Add Webhook Secret to Supabase
  1. Supabase Dashboard → Project Settings → Edge Functions → Secrets
  2. Add new secret:
     - Name: `stripe_webhook_secret`
     - Value: Paste the signing secret from Step 2

---

### Phase 2: Deployment (10 minutes)

- [ ] **Step 4**: Deploy Edge Functions
  ```bash
  cd supabase
  supabase functions deploy create-payment-intent
  supabase functions deploy stripe-webhook
  ```
  Or use Supabase Dashboard UI

- [ ] **Step 5**: Run Flutter app
  ```bash
  flutter clean
  flutter pub get
  flutter run
  ```

---

### Phase 3: Testing (20 minutes)

- [ ] **Test Payment Flow**
  1. Navigate: Ecosystem → Select Service → Fill Form → "Review & Pay"
  2. Click "Proceed to Secure Payment"
  3. Use test card: `4242 4242 4242 4242`
  4. Any future expiry date and 3-digit CVC
  5. Verify:
     - [ ] Payment Sheet appears
     - [ ] Payment succeeds
     - [ ] Success page shows
     - [ ] Database updated (check application_payments table)
     - [ ] Email sent to applicant

- [ ] **Test Payment Failure**
  1. Use declined card: `4000 0000 0000 0002`
  2. Verify error handling works

- [ ] **Test Webhook**
  1. Stripe Dashboard → Webhooks → Your endpoint
  2. Click "Send test event"
  3. Select "payment_intent.succeeded"
  4. Check database updated correctly

---

## 📊 What's Already Done ✅

Code Implementation:
- ✅ `flutter_stripe: ^10.0.0` added to pubspec.yaml
- ✅ Stripe initialization in main.dart
- ✅ `create-payment-intent` Edge Function created
- ✅ `stripe-webhook` Edge Function created
- ✅ Payment service updated with real Stripe integration
- ✅ Payment processing page updated to use real API
- ✅ Error handling implemented
- ✅ Database schema already supports payments
- ✅ Email triggers already configured

---

## 🔑 Keys You Already Provided

- ✅ `stripe_secret_key` added to Supabase Secrets
- ⏳ `STRIPE_PUBLISHABLE_KEY` in `.env.mobile` (add your key here)
- ⏳ `stripe_webhook_secret` in Supabase Secrets (get from webhook creation)

---

## 📋 File Reference

**New Edge Functions**:
- `/supabase/functions/create-payment-intent/index.ts` - Creates PaymentIntent
- `/supabase/functions/stripe-webhook/index.ts` - Receives webhook events

**Modified Files**:
- `/lib/main.dart` - Stripe initialization
- `/lib/services/application_payment_service.dart` - Real payment processing
- `/lib/features/ecosystem/payment_processing_page.dart` - Updated UI calls
- `/.env.mobile` - Add publishable key
- `/supabase/functions/deno.json` - Added Stripe npm packages
- `/pubspec.yaml` - Fixed duplicate dependencies

---

## 🧪 Stripe Test Cards

For testing in test mode:

| Scenario | Card Number | Expiry | CVC |
|----------|-------------|--------|-----|
| Success | 4242 4242 4242 4242 | Any future | Any 3 digits |
| Declined | 4000 0000 0000 0002 | Any future | Any 3 digits |
| Requires Auth | 4000 0025 0000 3155 | Any future | Any 3 digits |

More: https://stripe.com/docs/testing

---

## ⚠️ Important Notes

1. **Never commit real API keys** - Use environment variables only
2. **Test webhook delivery** - Use Stripe Dashboard webhook testing
3. **Check database updates** - Query `application_payments` table
4. **Email notifications** - Already automated via database triggers
5. **Production keys** - Get from Stripe when ready to go live

---

## 🆘 Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| Payment Sheet not appearing | Check `STRIPE_PUBLISHABLE_KEY` in .env.mobile |
| Webhook not firing | Verify signing secret in Supabase Secrets |
| Database not updating | Check Edge Function error logs in Supabase |
| Cards always declining | Use official test cards from Stripe |

---

## 📞 Support Links

- Stripe Docs: https://stripe.com/docs/payments/payment-sheet
- Flutter Stripe: https://pub.dev/packages/flutter_stripe
- Supabase Webhooks: https://supabase.com/docs/guides/functions
- Test Stripe: https://dashboard.stripe.com/test/dashboard

---

**Status**: All code ready. Waiting on your configuration! 🚀
