# Moderation Pipeline (Server-side)

Overview
- Text moderation via OpenAI Moderations API (or GPT classification) for posts, chat_messages, and personal_messages.
- Image moderation via Google Cloud Vision SafeSearch for Storage uploads linked to media.
- Results stored in moderation_logs; optionally queue items in content_flags for admin review.
- Admin emails (policy-level): foundervers@gmail.com, startupbuilder0213@gmail.com

Entry points
1) Post creation
   - After Insert trigger (or PostgREST webhook) calls a Supabase Edge Function `moderate-content` with post payload.
   - Function checks title/description; sets posts.moderation_status = 'approved'|'pending'|'blocked'.
2) Chat message send
   - Realtime pipeline or DB trigger -> `moderate-content` for text.
3) Media upload
   - Storage webhook on bucket `startupbuilder` -> `moderate-image` function runs Vision SafeSearch.

Data model
- Tables (see supabase-schema.sql additions):
  - moderation_logs(id, content_id, content_type, user_id, moderation_result, cost_incurred, flagged, auto_action, created_at)
  - content_flags(id, content_id, content_type, content_data, user_id, flag_reason, confidence_score, status, admin_id, admin_action_at, admin_reason, created_at)
  - user_trust_scores(user_id, trust_score, ...)
- Columns added: moderation_status on posts and chat_messages.

Actions
- approved: visible normally
- pending: visible to author; show badge to others or hide until approved (product choice)
- blocked: hidden for everyone except admins; author sees a warning

Implementation notes
- Keep API keys in Edge Function secrets; never expose to client apps.
- Log token usage to moderation_logs.cost_incurred.
- Batch and rate limit calls; fallback to 'pending' on API errors.

Testing
- Seed a sample post and chat message with borderline content; ensure status changes.
- Upload safe vs unsafe images to bucket and verify outcomes.

Future
- Add feedback loop to adjust user_trust_scores to reduce false positives over time.
