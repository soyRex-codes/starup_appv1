# Stripe Payment Android Troubleshooting Guide

## Common Issues & Solutions for Android Payment Failures

### Issue 1: Payment Sheet Not Appearing
**Symptoms:**
- Payment button pressed but nothing happens
- No error message shown
- App logs show Stripe initialization but payment sheet doesn't display

**Possible Causes & Fixes:**

1. **Missing Stripe Publishable Key**
   - Check `.env.mobile` file has `STRIPE_PUBLISHABLE_KEY`
   - Verify the key starts with `pk_test_` (test mode) or `pk_live_` (production)
   - Rebuild app after adding/changing the key: `flutter clean && flutter build apk --release`

2. **Stripe Not Initialized**
   - Check app logs for "✅ Stripe initialized successfully"
   - If you see "⚠️ Warning: Stripe publishable key not found", the key isn't loading
   - Ensure `.env.mobile` is bundled in the app

3. **ProGuard/R8 Stripping Stripe Classes**
   - Already fixed in `android/app/proguard-rules.pro`
   - Verify the file contains: `-keep class com.stripe.android.** { *; }`
   - Rebuild with `flutter clean && flutter build apk --release`

### Issue 2: Payment Sheet Crashes on Open
**Symptoms:**
- App crashes when trying to show payment sheet
- Error: "Failed to create payment intent"

**Possible Causes & Fixes:**

1. **Edge Function Not Deployed**
   - Ensure `create-premium-subscription` Edge Function is deployed to Supabase
   - Test the function directly in Supabase dashboard
   - Check function logs for errors

2. **Stripe Secret Key Missing in Edge Function**
   - Edge Function needs `STRIPE_SECRET_KEY` environment variable
   - Set in Supabase Dashboard → Edge Functions → Secrets
   - Use test key `sk_test_...` for testing

3. **Network Issues**
   - Check device has internet connection
   - Check Supabase URL is correct in `.env.mobile`
   - Verify Edge Functions URL is accessible from device

### Issue 3: Payment Completes But Subscription Not Activated
**Symptoms:**
- Payment goes through successfully
- Money charged but user not marked as premium
- Success page shows but premium features still locked

**Possible Causes & Fixes:**

1. **Webhook Not Configured**
   - Stripe webhook must be set up to notify your backend
   - URL: `https://YOUR_PROJECT.supabase.co/functions/v1/stripe-webhook`
   - Events to listen for:
     - `payment_intent.succeeded`
     - `payment_intent.payment_failed`
     - `charge.refunded`

2. **Webhook Secret Mismatch**
   - Get webhook signing secret from Stripe Dashboard
   - Set as `STRIPE_WEBHOOK_SECRET` in Edge Function environment
   - Verify in Supabase Dashboard → Edge Functions → Secrets

3. **Database Schema Missing**
   - Ensure both migrations are applied:
     - `add_premium_subscription.sql`
     - `add_premium_payments_table.sql`
   - Check in Supabase Dashboard → Database → Tables

### Issue 4: "Payment failed" Error After Card Entry
**Symptoms:**
- User enters card details
- Payment fails with generic error
- Stripe test cards not working

**Possible Causes & Fixes:**

1. **Using Wrong Test Card**
   - Use Stripe test cards: `4242 4242 4242 4242`
   - Any future expiry date (e.g., 12/25)
   - Any 3-digit CVC
   - Any 5-digit ZIP code

2. **Test Mode Mismatch**
   - Ensure using test publishable key (`pk_test_...`)
   - Ensure using test secret key (`sk_test_...`) in Edge Function
   - Both must be from same Stripe account

3. **Payment Amount Issue**
   - Stripe requires minimum amount (usually $0.50)
   - Check your pricing is above minimum
   - Monthly: $19.99, Annual: $167.99 (both above minimum)

### Issue 5: Google Pay Not Working
**Symptoms:**
- Google Pay button doesn't appear
- Google Pay payment fails

**Fixes:**
- Google Pay requires production keys for real payments
- Test mode Google Pay may not work on all devices
- Use card payment for testing

## Enhanced Logging

The app now includes comprehensive logging. Check these in your terminal:

### Successful Payment Flow Logs:
```
🚀 Starting premium payment process...
👤 User ID: [user-id]
📧 User Email: [email]
📝 Step 1: Creating payment record...
✅ Payment record created: [payment-id]
💳 Step 2: Processing payment with Stripe...
🔵 Calling create-premium-subscription Edge Function...
📧 Email: [email]
💰 Amount: $[amount]
📅 Type: [monthly/annual]
📡 Edge Function response status: 200
📦 Edge Function response data: {...}
🔧 Initializing Stripe Payment Sheet...
🔑 Client Secret: pi_...
✅ Payment sheet initialized successfully
📱 Presenting payment sheet...
✅ Payment sheet completed successfully
✅ Payment processed successfully
🎯 Step 3: Activating premium subscription...
🎉 Premium subscription activated successfully!
```

### Error Log Examples:
```
❌ Edge Function error: [error details]
❌ Stripe error: Payment was cancelled by user
💥 Premium payment processing exception: [exception]
```

## Testing Checklist

### Pre-Test Verification
- [ ] `.env.mobile` has valid `STRIPE_PUBLISHABLE_KEY`
- [ ] Both SQL migrations applied in Supabase
- [ ] `create-premium-subscription` Edge Function deployed
- [ ] `stripe-webhook` Edge Function deployed  
- [ ] Stripe webhook configured (URL + secret)
- [ ] Edge Function has `STRIPE_SECRET_KEY` set
- [ ] Edge Function has `STRIPE_WEBHOOK_SECRET` set
- [ ] App rebuilt after any config changes

### Payment Test Flow
1. [ ] Open app on Android device
2. [ ] Check logs show "✅ Stripe initialized successfully"
3. [ ] Navigate to premium upgrade (Business.AI or Global Chat)
4. [ ] Tap "Upgrade Now" button
5. [ ] Check logs show "🚀 Starting premium payment process..."
6. [ ] Select monthly or annual plan
7. [ ] Tap payment button
8. [ ] Check logs show "🔧 Initializing Stripe Payment Sheet..."
9. [ ] Payment sheet should appear
10. [ ] Enter test card: 4242 4242 4242 4242
11. [ ] Enter any future expiry, CVC, ZIP
12. [ ] Confirm payment
13. [ ] Check logs show "✅ Payment sheet completed successfully"
14. [ ] Should see success page
15. [ ] Check gold badge appears on profile
16. [ ] Verify Business.AI/Global Chat are now accessible

### Database Verification
After successful payment:
- [ ] Check `premium_payments` table has new record with status='completed'
- [ ] Check `users` table has `is_premium=true` for the user
- [ ] Check `premium_expires_at` is set to future date

## Quick Rebuild Commands

```bash
# Clean and rebuild release APK
flutter clean
flutter build apk --release

# Install on connected device
flutter install

# View real-time logs
flutter logs
```

## Still Having Issues?

### Check These:

1. **Verify Stripe Keys**
   ```bash
   # In .env.mobile
   STRIPE_PUBLISHABLE_KEY=pk_test_51QCGRmHzme0zworxPBjjq0JeN6OBH5dRAmNPMujnWEe679KQDUKaSXxfRpMqoR4hWNbBn9AV7meNAE05V2icLrV400KsZwMmjf
   ```

2. **Check Edge Function Logs**
   ```bash
   supabase functions logs create-premium-subscription --project-ref YOUR_PROJECT_REF
   supabase functions logs stripe-webhook --project-ref YOUR_PROJECT_REF
   ```

3. **Test Edge Function Directly**
   - Go to Supabase Dashboard → Edge Functions
   - Click on `create-premium-subscription`
   - Use test body:
   ```json
   {
     "amount": 19.99,
     "userId": "test-user-id",
     "email": "test@example.com",
     "subscriptionType": "monthly"
   }
   ```
   - Should return `clientSecret` and `paymentIntentId`

4. **Check Network Connectivity**
   - Ensure device has internet
   - Try on WiFi vs mobile data
   - Check no VPN/proxy blocking Stripe

5. **Verify Android Version**
   - Minimum SDK 21 (Android 5.0) required
   - Google Play Services must be installed for Google Pay

## Contact Support

If issues persist after following this guide:
1. Collect logs from `flutter logs` command
2. Note exact error message shown to user
3. Check Stripe Dashboard → Developers → Logs for any API errors
4. Check Supabase Edge Function logs
5. Share all above information for debugging

## Production Deployment Checklist

When ready to go live:
- [ ] Replace test keys with live keys in `.env.mobile`
- [ ] Update Edge Function environment variables with live keys
- [ ] Create production webhook in Stripe with live endpoint
- [ ] Test with real card (small amount first)
- [ ] Monitor first few transactions closely
- [ ] Set up Stripe email notifications
