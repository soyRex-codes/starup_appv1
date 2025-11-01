# In-App Notifications - Implementation Guide

## Overview
The in-app notification system provides real-time notifications for user interactions within the FounderVers app. Users receive notifications for comments, replies, and bookmarks, with a live badge showing unread count in the app header.

## Features Implemented

### ✅ Database Schema
- **Table**: `notifications` with RLS policies
- **Notification Types**: `comment`, `reply`, `dm`, `bookmark`, `collab_request`, `system`
- **Helper Functions**:
  - `get_unread_notification_count(uuid)` - Fast unread count
  - `mark_all_notifications_read(uuid)` - Bulk mark as read
  - `cleanup_old_notifications()` - Maintenance function

### ✅ Real-time Updates
- Supabase WebSocket subscriptions for live notifications
- Automatic badge updates when new notifications arrive
- Stream-based architecture with `unreadCountStream`

### ✅ UI Components
- **Bell Icon**: Header badge showing unread count (with 99+ overflow)
- **Notifications Page**: Full list view with pull-to-refresh
- **Notification Card**: Dismissible cards with avatars, icons, and timestamps
- **Actions**: Mark all read, clear read notifications

### ✅ Notification Triggers
Current triggers implemented:

1. **Comments**: When someone comments on your post
2. **Replies**: When someone replies to your comment  
3. **Bookmarks**: When someone bookmarks your post

Future triggers (ready to implement):
- Direct Messages (DM service exists)
- Collaboration Requests (when feature is implemented)

## Setup Instructions

### Step 1: Apply Database Migration

**CRITICAL**: The notification system won't work until you apply the database schema.

1. Open Supabase Dashboard → SQL Editor
2. Copy the contents of `/supabase/migrations/create_notifications_table.sql`
3. Paste and execute the migration
4. Verify table exists:
   ```sql
   SELECT * FROM notifications LIMIT 1;
   ```

### Step 2: Test the System

1. **Run the app** and login
   - Notification listener starts automatically on login
   - Check debug logs for: `✅ Notification listener started successfully`

2. **Test Comment Notification**:
   - Login as User A
   - Create a post
   - Login as User B
   - Comment on User A's post
   - Login back as User A
   - Bell icon should show badge (1)
   - Open notifications page
   - Should see: "Someone commented on your post"

3. **Test Reply Notification**:
   - Login as User A
   - Comment on someone's post
   - Login as User B (the original commenter)
   - Reply to User A's comment
   - Login back as User A
   - Should see: "Someone replied to your comment"

4. **Test Bookmark Notification**:
   - Login as User A
   - Create a post
   - Login as User B
   - Bookmark User A's post
   - Login back as User A
   - Should see: "Your post was bookmarked"

5. **Test Real-time Updates**:
   - Keep app open
   - Have another device/emulator perform action
   - Badge should update automatically without refresh

### Step 3: Verify Core Functionality

- [ ] Bell icon appears in app header
- [ ] Badge shows correct unread count
- [ ] Tapping bell opens notifications page
- [ ] Notifications display with proper formatting
- [ ] Tapping notification marks as read
- [ ] Badge decrements when notification marked read
- [ ] "Mark all as read" works
- [ ] "Clear read" removes read notifications
- [ ] Swipe to dismiss works
- [ ] Pull to refresh updates list
- [ ] Real-time badge updates work

## Architecture

### Data Flow

```
User Action (comment/bookmark)
        ↓
Service (CommentService/BookmarkService)
        ↓
NotificationService.notifyX()
        ↓
Database INSERT (notifications table)
        ↓
Supabase Real-time Event
        ↓
NotificationService.startListening()
        ↓
unreadCountStream updates
        ↓
UI Badge Rebuilds (StreamBuilder)
```

### Key Files

| File | Purpose |
|------|---------|
| `supabase/migrations/create_notifications_table.sql` | Database schema |
| `lib/models/notification.dart` | Data model with types |
| `lib/services/notification_service.dart` | CRUD + real-time subscriptions |
| `lib/widgets/notifications/notification_card.dart` | Single notification UI |
| `lib/features/notifications/notifications.dart` | Full page list view |
| `lib/app/widgets/app_header.dart` | Bell icon with badge |
| `lib/app/auth_gate.dart` | Listener startup on login |
| `lib/services/comment_service.dart` | Comment/reply triggers |
| `lib/services/bookmark_service.dart` | Bookmark triggers |

### Caching Strategy

- **Unread Count**: Cached in memory, refreshed every 30 seconds
- **Real-time Updates**: Instant via Supabase channels
- **Notifications List**: Fetched on demand with pull-to-refresh

### Security (RLS Policies)

```sql
-- Users can only see their own notifications
CREATE POLICY "Users can view own notifications"
ON notifications FOR SELECT
USING (auth.uid() = user_id);

-- Service can insert notifications for any user
CREATE POLICY "Service can create notifications"
ON notifications FOR INSERT
WITH CHECK (true);

-- Users can update their own notifications
CREATE POLICY "Users can update own notifications"
ON notifications FOR UPDATE
USING (auth.uid() = user_id);

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications"
ON notifications FOR DELETE
USING (auth.uid() = user_id);
```

## Adding New Notification Types

To add a new notification type (e.g., "like" notifications):

### 1. Add to Enum (if needed)
```dart
// lib/models/notification.dart
enum NotificationType {
  comment('💬'),
  reply('↩️'),
  dm('✉️'),
  bookmark('🔖'),
  collabRequest('🤝'),
  like('❤️'),  // NEW
  system('🔔');
  
  final String icon;
  const NotificationType(this.icon);
}
```

### 2. Add Helper Method
```dart
// lib/services/notification_service.dart
static Future<void> notifyLike({
  required String postOwnerId,
  required String likerName,
  required int postId,
  required String postTitle,
  required String likerId,
}) async {
  if (postOwnerId == likerId) return; // Don't notify yourself
  
  await create(
    userId: postOwnerId,
    type: NotificationType.like,
    title: 'Your post was liked',
    message: '$likerName liked "$postTitle"',
    relatedPostId: postId,
    relatedUserId: likerId,
    actionUrl: '/post/$postId',
  );
}
```

### 3. Add Trigger in Service
```dart
// In your like service
await _client.from('likes').insert({...});

// Notify post owner
_notifyPostOwner(postId, likerId);
```

### 4. Add Helper Method
```dart
void _notifyPostOwner(int postId, String likerId) async {
  try {
    final currentUser = await _client
        .from('users')
        .select('display_name')
        .eq('id', likerId)
        .maybeSingle();

    final likerName = currentUser?['display_name'] ?? 'Someone';

    final post = await _client
        .from('posts')
        .select('user_id, title, content')
        .eq('id', postId)
        .maybeSingle();

    if (post != null && post['user_id'] != likerId) {
      final postTitle = (post['title'] as String?)?.isNotEmpty == true
          ? post['title']
          : (post['content'] as String?)?.substring(0, 50) ?? 'your post';

      await NotificationService.notifyLike(
        postOwnerId: post['user_id'],
        likerName: likerName,
        postId: postId,
        postTitle: postTitle,
        likerId: likerId,
      );
    }
  } catch (e) {
    debugPrint('⚠️ Failed to send like notification: $e');
  }
}
```

## Performance Considerations

### Database Indexes
The migration includes optimized indexes:
```sql
-- Fast unread queries
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, read, created_at DESC);

-- Fast type filtering
CREATE INDEX idx_notifications_type ON notifications(type);

-- Fast post-related queries
CREATE INDEX idx_notifications_post_id ON notifications(related_post_id);
```

### Cleanup
Old notifications should be cleaned periodically:
```sql
-- Run this weekly (can be automated with pg_cron)
SELECT cleanup_old_notifications();
```

This removes read notifications older than 30 days and unread notifications older than 90 days.

## Troubleshooting

### Badge Not Updating
1. Check notification listener started: Look for `✅ Notification listener started successfully` in logs
2. Verify Supabase real-time is enabled: Check Supabase Dashboard → Database → Replication
3. Check RLS policies: Users must be authenticated

### Notifications Not Created
1. Verify migration applied: `SELECT * FROM notifications LIMIT 1;`
2. Check service logs: Look for `⚠️ Failed to send X notification` messages
3. Verify foreign keys: Post/comment/user IDs must exist

### Real-time Not Working
1. Check Supabase plan: Free tier has real-time enabled
2. Verify network: WebSocket connections may be blocked by firewalls
3. Check subscription: Look for `❌ Notification listener error` in logs

## Future Enhancements

### Planned (Not Implemented)
- Push notifications (FCM) for background/killed app states
- Email notifications for critical actions
- Notification preferences (mute types, frequency)
- Grouped notifications ("John and 5 others commented")
- Rich media in notifications (thumbnails)

### Migration Path to Push Notifications
The current in-app system is designed to work alongside push notifications:

1. Keep `NotificationService` as single source of truth
2. Add `DeviceService` for FCM token management
3. Create Supabase Edge Function to send push when notification created
4. Push notification taps can deep link to in-app notification

See `FINAL_DEPLOYMENT_PLAN.md` for full TIER 2 implementation details.

## Estimated Time Investment

- **Setup**: 5 minutes (apply migration, test)
- **Adding New Type**: 15 minutes per type
- **Debugging**: Varies (most issues are RLS or real-time config)

## Contact

For questions or issues, check:
- `docs/TROUBLESHOOTING_GUIDE.md`
- Supabase logs in Dashboard → Logs
- Debug logs in app (filter for "Notification")
