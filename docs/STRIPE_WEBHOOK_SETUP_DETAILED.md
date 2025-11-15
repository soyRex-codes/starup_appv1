# Stripe Webhook Setup - Step-by-Step Guide

## 🎯 Complete Webhook Configuration

### Step 1: Navigate to Webhooks Section
```
Stripe Dashboard
    ↓
Left Sidebar → Scroll down
    ↓
Find "Developers" section
    ↓
Click "Webhooks"
```

Or direct link: https://dashboard.stripe.com/webhooks

---

### Step 2: Add Endpoint
Look for a button that says **"Add an endpoint"** or **"+ Add endpoint"**

Click it and you'll see a form:

```
URL to send events to:
┌─────────────────────────────────────────────────────────────┐
│ https://YOUR_PROJECT_ID.supabase.co/functions/v1/stripe-webhook │
└─────────────────────────────────────────────────────────────┘

Events to send:
┌─────────────────────────────────────────────────────────────┐
│ Select all events  ∨                                         │
│ ☐ charge.captured                                           │
│ ☑ charge.refunded          ← CHECK THIS                     │
│ ☑ payment_intent.succeeded ← CHECK THIS                     │
│ ☑ payment_intent.payment_failed ← CHECK THIS                │
│ ... and more                                                │
└─────────────────────────────────────────────────────────────┘
```

---

### Step 3: Get Your Supabase Function URL

**First, you need to find your Supabase Project ID:**

1. Open Supabase Dashboard: https://app.supabase.com
2. Select your project
3. Go to: Settings → General
4. Copy your **Project ID** (looks like: `qddhubtyvqoqlbshxfkr`)
5. Your webhook URL will be:
   ```
   https://qddhubtyvqoqlbshxfkr.supabase.co/functions/v1/stripe-webhook
   ```

---

### Step 4: Create the Endpoint

1. Paste the URL in the "URL to send events to" field
2. Select these events:
   - ✅ `payment_intent.succeeded`
   - ✅ `payment_intent.payment_failed`
   - ✅ `charge.refunded`
3. Click **"Add endpoint"** or **"Save"**

---

### Step 5: Copy the Signing Secret

After creating the endpoint, you'll see:

```
Signing secret
┌──────────────────────────────────────────────────┐
│ whsec_test_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx...  │
│                                        [Copy ↔]  │
└──────────────────────────────────────────────────┘
```

**Copy this entire secret** (click the copy button)

---

### Step 6: Add Secret to Supabase

1. Go to Supabase Dashboard
2. Select your project
3. Navigate to: **Settings → Edge Functions**
4. Scroll to **Secrets** section
5. Click **"Add secret"**
6. Fill in:
   ```
   Name: stripe_webhook_secret
   Value: whsec_test_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx...
   ```
7. Click **"Save secret"**

---

## ✅ Verification Checklist

After completing above steps, verify:

- [ ] Webhook endpoint created in Stripe
- [ ] URL is correct (matches your Supabase project)
- [ ] Three events selected (succeeded, failed, refunded)
- [ ] Signing secret copied
- [ ] Signing secret added to Supabase as `stripe_webhook_secret`

---

## 📊 Expected Result

Your Stripe Webhooks page should show:

```
Endpoints
┌─────────────────────────────────────────────────────────┐
│ https://your-project.supabase.co/functions/v1/stripe...  │
│ Status: ✅ Enabled                                       │
│ 3 events selected                                        │
│ Signing secret: whsec_test_xxx...                       │
└─────────────────────────────────────────────────────────┘
```

---

## 🧪 Test the Webhook (Optional)

1. In Stripe Webhooks page, find your endpoint
2. Click on it
3. Scroll down to "Recent events"
4. Click **"Send test event"**
5. Select: `payment_intent.succeeded`
6. Choose an action: `Send event`

This will test if your webhook is working!

---

## 🆘 Common Issues

| Issue | Solution |
|-------|----------|
| "URL returned status 400" | Make sure Edge Functions are deployed |
| "Failed to deliver event" | Check Supabase function logs |
| Can't find Webhooks | Make sure you're in Test mode (top of Stripe dashboard) |
| "Signing secret not found" | Make sure `stripe_webhook_secret` is added to Supabase Secrets |

