# ⚡ Quick Fix - Step by Step

## What I Fixed ✅
- Removed `stripe_test_key` from `.env.mobile` (secret keys should NOT be in mobile app!)
- Only `STRIPE_PUBLISHABLE_KEY` remains (this is safe)

---

## What You Need to Do NOW (3 steps)

### **Step 1: Verify Supabase Secret is Correct** (1 minute)

1. Open Supabase Dashboard
2. **Settings → Edge Functions → Secrets**
3. Look for: `stripe_secret_key`

**If it's there:**
- Value should start with `sk_test_`
- ✅ Good!

**If it's NOT there:**
- Click **"Add secret"**
- Name: `stripe_secret_key`
- Value: `sk_test_51QCGRmHzme0zworxwDmKgfnZHCX6XcGcLCBMHe0nsywVyltT12gzMz1fWq0ffpA5I5TPiJ0n31BmEaZqSd0FGhO300ONHOe4YJ`
- Click **Save**

---

### **Step 2: Redeploy Edge Functions** (2 minutes)

After adding/changing secrets, functions must be redeployed:

```bash
cd /Users/rajkushwaha/Desktop/develop/starup_appv1/supabase
supabase functions deploy create-payment-intent
supabase functions deploy stripe-webhook
```

Wait for completion ✅

---

### **Step 3: Restart App & Test** (2 minutes)

```bash
# Stop the app (Ctrl+C)
flutter clean
flutter pub get
flutter run
```

**Watch console for:**
```
✅ Stripe initialized successfully
✅ Supabase initialized successfully
```

**Both must appear!** If not, something is still wrong.

---

## 🧪 Then Test Payment

1. Go to Ecosystem → Service → Fill form
2. Click "Review & Pay"
3. Click "Proceed to Secure Payment"
4. Enter: `4242 4242 4242 4242` (test card)
5. Expiry: `12/28` CVC: `123`
6. **Should work now!** ✅

---

## 🆘 If Still Not Working

Run these commands and share output:

```bash
# Check Edge Function logs
cd /Users/rajkushwaha/Desktop/develop/starup_appv1
supabase functions list

# Look for create-payment-intent and check its status
```

Also check **Supabase Dashboard → Functions → create-payment-intent → Logs** for actual error messages.

---

**Do Steps 1-3 above and let me know what happens!**

