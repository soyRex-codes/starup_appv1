# Edge Functions: Notifications

send-dm-notification
- Purpose: Send an FCM push when a new personal_messages row is inserted.
- Trigger: Database Webhook on INSERT to public.personal_messages.
- Permissions: Use SERVICE_ROLE key inside the function; do not expose to clients.

Env variables (set via supabase CLI or dashboard)
- SUPABASE_URL
- SUPABASE_SERVICE_ROLE_KEY
- FCM_PROJECT_ID
- FCM_CLIENT_EMAIL
- FCM_PRIVATE_KEY (escape newlines) or use a service account JSON loaded via secret manager

Local development
- supabase functions new send-dm-notification
- supabase functions serve send-dm-notification --env-file ./supabase/.env

Webhook payload (simplified)
- type: INSERT
- table: personal_messages
- record: { id, sender_id, recipient_id, subject, content, created_at }

Logic
1) Validate payload type/table.
2) Lookup recipient device tokens:
   - select fcm_token from public.user_devices where user_id = record.recipient_id
3) For each token, call FCM HTTP v1 send API with a minimal notification payload.
4) Handle failures (e.g., 404/invalid token) by deleting stale tokens.
5) Optionally write to a notifications_log table (not required for MVP).

Deployment
- supabase functions deploy send-dm-notification
- Create a database webhook in Supabase Dashboard pointing to the function endpoint.

Security
- Keep SERVICE_ROLE only in the function environment.
- Apply RLS to user_devices (already in migrations/secure_rls_supabase.sql); the function runs with service role and bypasses RLS.
