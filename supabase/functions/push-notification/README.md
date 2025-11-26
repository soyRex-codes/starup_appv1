# Push Notification Edge Function

This function listens for new rows in the `notifications` table and sends Push Notifications via Firebase Cloud Messaging (FCM).

## Setup Instructions

### 1. Firebase Service Account
1.  Go to Firebase Console -> Project Settings -> Service accounts.
2.  Click "Generate new private key".
3.  Save the JSON file.
4.  Minify the JSON (remove newlines) to a single line string.

### 2. Set Secrets
Run this command in your terminal:
```bash
supabase secrets set FIREBASE_SERVICE_ACCOUNT='{"type":"service_account",...}'
```

### 3. Deploy Function
```bash
supabase functions deploy push-notification --no-verify-jwt
```

### 4. Create Database Webhook
You need to create a webhook in the Supabase Dashboard to trigger this function.
1.  Go to Database -> Webhooks.
2.  Create a new webhook.
3.  Name: `push-notification-trigger`.
4.  Table: `notifications`.
5.  Events: `INSERT`.
6.  Type: `HTTP Request`.
7.  URL: `https://<project-ref>.supabase.co/functions/v1/push-notification`.
8.  Method: `POST`.
9.  Headers: `Authorization: Bearer <service-role-key>`.
