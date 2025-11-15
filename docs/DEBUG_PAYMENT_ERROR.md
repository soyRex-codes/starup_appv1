# 🔍 Debug: Stripe Payment Processing Error

## Problem
Getting "Payment processing failed" error when trying to pay

## Root Cause Analysis

The error happens at one of these steps:
1. ❓ Stripe not initialized in app
2. ❓ Edge Function `create-payment-intent` not deployed or failing
3. ❓ Supabase secret `stripe_secret_key` not set correctly
4. ❓ Network error calling Edge Function

---

## 🔧 Debug Steps (Do These in Order)

### Step 1: Verify Stripe Initialization (Mobile App)

**Check the console output when app starts:**

Look for BOTH messages:
```
✅ Stripe initialized successfully
✅ Supabase initialized successfully
```

If you see `⚠️ Warning: Stripe publishable key not found`:
- ✅ FIXED: We removed it from .env.mobile
- Run: `flutter clean && flutter pub get && flutter run`

---

### Step 2: Verify Supabase Secrets (CRITICAL)

Go to **Supabase Dashboard → Settings → Edge Functions → Secrets**

You should have:
```
Name: stripe_secret_key
Value: sk_test_51QCGRmHzme0zworxwDmKgfnZHCX6XcGcLCBMHe0nsywVyltT12gzMz1fWq0ffpA5I5TPiJ0n31BmEaZqSd0FGhO300ONHOe4YJ
```

⚠️ **IF NOT SET:**
1. Click "Add secret"
2. Name: `stripe_secret_key`
3. Value: `sk_test_51QCGRmHzme0zworxwDmKgfnZHCX6XcGcLCBMHe0nsywVyltT12gzMz1fWq0ffpA5I5TPiJ0n31BmEaZqSd0FGhO300ONHOe4YJ`
4. Click "Save secret"

---

### Step 3: Check Edge Function Logs

1. Go to Supabase Dashboard
2. **Functions** section
3. Click on **`create-payment-intent`**
4. Look for **"Logs"** tab
5. Try a payment again and watch the logs

**What to look for:**
```
✅ PaymentIntent created: pi_test_...
```

OR error like:
```
❌ Error: Invalid API Key
❌ Error: stripe_secret_key is undefined
❌ Error: Missing stripe_secret_key in environment
```

---

### Step 4: Redeploy Edge Functions (If Secrets Changed)

After adding/changing secrets, you must redeploy:

```bash
cd /Users/rajkushwaha/Desktop/develop/starup_appv1/supabase

# Redeploy both functions
supabase functions deploy create-payment-intent
supabase functions deploy stripe-webhook
```

Or use Supabase Dashboard UI to redeploy.

---

## 📋 Checklist Before Testing

- [ ] `.env.mobile` only has `STRIPE_PUBLISHABLE_KEY` (no secret keys)
- [ ] Supabase secret `stripe_secret_key` is set correctly
- [ ] Edge Functions redeployed after secret was added
- [ ] App started after fixing `.env.mobile` (flutter clean && flutter run)
- [ ] Console shows both ✅ messages when app starts
- [ ] Edge Function logs show PaymentIntent created successfully

---

## 🚀 Quick Verification Test

In terminal where app is running, you should see:

```bash
✅ Stripe initialized successfully
✅ Supabase initialized successfully
```

If you see warning instead:
```
⚠️ Warning: Stripe publishable key not found
```

Then `.env.mobile` is not being loaded correctly.

---

## ✅ Solution Path

1. **Clean up** ✅ DONE - removed secret from .env.mobile
2. **Verify Supabase Secret** - CHECK THIS NOW
3. **Redeploy Functions** - DO THIS IF NEEDED
4. **Restart App** - `flutter run`
5. **Check Logs** - Look for ✅ messages and function logs
6. **Test Payment** - Try again

---

## 💡 Next Step

Tell me what you see when you:

1. Check Supabase Secrets (is `stripe_secret_key` there and correct?)
2. Check Edge Function logs (any errors?)
3. Restart the app and check console (do you see both ✅ messages?)

I'll help you fix it from there!

