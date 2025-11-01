# Quick Visual: Where to Click in Stripe Dashboard

## Current Location: ❌ Wrong Place
```
Dashboard
├── Home
├── Balances
├── Transactions
├── Customers
├── Product catalog
├── Shortcuts
│   ├── Subscriptions ← YOU ARE HERE (Wrong!)
│   ├── Payments analytics
│   ├── Terminal
│   └── Payment Links
└── Products
```

## Correct Location: ✅ Go Here
```
Dashboard
├── Home
├── Balances
├── Transactions
├── Customers
├── Product catalog
├── Shortcuts
│   ├── Subscriptions
│   ├── Payments analytics
│   ├── Terminal
│   └── Payment Links
└── DEVELOPERS SECTION (scroll down left sidebar)
    └── Webhooks ← CLICK HERE!
```

---

## Direct Navigation

**From Stripe Dashboard:**

1. Look at the **left sidebar** (where you see "Home", "Balances", etc.)
2. **Scroll down** to find section labeled **"Developers"** or just look for **"Webhooks"**
3. Click **"Webhooks"**

**Direct URL:** https://dashboard.stripe.com/webhooks

---

## In Webhooks Page, You'll See:

### If you have NO endpoints yet:
```
┌─────────────────────────────────────┐
│  Webhooks                           │
│                                     │
│  No endpoints yet                   │
│                                     │
│  [+ Add an endpoint]  ← CLICK THIS  │
└─────────────────────────────────────┘
```

### If you already have endpoints:
```
┌─────────────────────────────────────┐
│  Webhooks                           │
│                                     │
│  [+ Add an endpoint]                │
│                                     │
│  Endpoints:                         │
│  • https://example.com/webhook      │
│  • https://another.com/webhook      │
│                                     │
│  [Add another one...]               │
└─────────────────────────────────────┘
```

---

## The Form You'll Fill:

```
URL Configuration:
┌──────────────────────────────────────────────────────────┐
│ Endpoint URL                                             │
│ ┌────────────────────────────────────────────────────┐  │
│ │ https://PROJECT_ID.supabase.co/functions/v1/stripe-webhook  │
│ └────────────────────────────────────────────────────┘  │
│                                                          │
│ Events: Select specific events you'd like to listen to  │
│ ┌────────────────────────────────────────────────────┐  │
│ │ payment_intent.succeeded                           │  │
│ │ payment_intent.payment_failed                       │  │
│ │ charge.refunded                                     │  │
│ │ [All Events dropdown]                              │  │
│ └────────────────────────────────────────────────────┘  │
│                                                          │
│                    [Add endpoint]                        │
└──────────────────────────────────────────────────────────┘
```

---

## After Creating - Copy This:

```
Once created, you'll see:

┌──────────────────────────────────────────────────────────┐
│ Signing secret                                           │
│ ┌────────────────────────────────────────────────────┐  │
│ │ whsec_test_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx       │  │
│ │ Reveal                                   [Copy] ← COPY  │
│ └────────────────────────────────────────────────────┘  │
│                                                          │
│ This is the secret for your .env!                       │
└──────────────────────────────────────────────────────────┘
```

---

## Once You Have the Secret:

### In Supabase:

```
Supabase Dashboard
    ↓
Select Project
    ↓
Settings → Edge Functions (or look for Secrets)
    ↓
Add Secret
    ↓
Name: stripe_webhook_secret
Value: whsec_test_xxx...
    ↓
Save
```

Done! ✅

