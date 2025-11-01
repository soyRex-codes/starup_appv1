# Apply Notification Migration - Quick Steps

## 🚨 CRITICAL FIRST STEP
**The notification system will NOT work until you apply the database migration.**

## Steps

### 1. Open Supabase SQL Editor
1. Go to https://supabase.com/dashboard
2. Select your project
3. Click **SQL Editor** in left sidebar
4. Click **New query**

### 2. Copy Migration SQL
Copy the entire contents of:
```
/supabase/migrations/create_notifications_table.sql
```

### 3. Execute Migration
1. Paste into SQL Editor
2. Click **Run** button (or press Cmd+Enter)
3. Wait for success message

### 4. Verify Installation
Run this query to confirm:
```sql
-- Should return empty result (no errors)
SELECT * FROM notifications LIMIT 1;

-- Should return 0
SELECT get_unread_notification_count(auth.uid());
```

### 5. Test Notification Creation
```sql
-- Insert test notification (replace YOUR_USER_ID with your UUID from users table)
INSERT INTO notifications (user_id, type, title, message)
VALUES ('YOUR_USER_ID', 'system', 'Test', 'Migration successful!');

-- Verify it appears
SELECT * FROM notifications WHERE user_id = 'YOUR_USER_ID';

-- Clean up test
DELETE FROM notifications WHERE title = 'Test';
```

## What This Migration Creates

### Tables
- ✅ `notifications` - Main notification storage

### Functions
- ✅ `get_unread_notification_count(uuid)` - Fast unread count
- ✅ `mark_all_notifications_read(uuid)` - Bulk mark as read  
- ✅ `cleanup_old_notifications()` - Remove old notifications

### Indexes (for performance)
- ✅ `idx_notifications_user_unread` - User + read status + date
- ✅ `idx_notifications_user_created` - User + created date
- ✅ `idx_notifications_type` - Notification type
- ✅ `idx_notifications_post_id` - Related post

### Security (RLS Policies)
- ✅ Users can only view their own notifications
- ✅ Service can create notifications for any user
- ✅ Users can update/delete their own notifications

## After Migration

### Enable Real-time (if not enabled)
1. Go to **Database** → **Replication**
2. Find `notifications` table
3. Enable replication

### Run the App
```bash
flutter run
```

### Test Flow
1. Login as User A → Create a post
2. Login as User B → Comment on User A's post
3. Login as User A → See bell badge with (1)
4. Tap bell → See "Someone commented on your post"
5. Tap notification → Badge decrements to (0)

## Troubleshooting

### Error: "relation 'notifications' does not exist"
→ Migration not applied. Go back to Step 2.

### Error: "permission denied for table notifications"  
→ RLS policies not created. Re-run entire migration.

### Badge doesn't update in real-time
→ Enable replication for `notifications` table in Supabase Dashboard.

### No notifications appear
→ Check logs in app for `⚠️ Failed to send X notification` errors.

## Done! ✅
Once migration succeeds and test notification appears, the system is ready to use.

See `docs/IN_APP_NOTIFICATIONS_GUIDE.md` for full documentation.
