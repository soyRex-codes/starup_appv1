-- =====================================================================
-- IN-APP NOTIFICATIONS SYSTEM
-- =====================================================================
-- This schema adds an in-app notification system for user activity:
-- • Comment notifications (someone commented on your post)
-- • Reply notifications (someone replied to your comment)
-- • DM notifications (new direct message received)
-- • Bookmark notifications (someone bookmarked your post)
-- • Collaboration request notifications
-- • Real-time capabilities via Supabase subscriptions
-- • Proper RLS security policies
-- =====================================================================

-- Notifications Table -------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL CHECK (type IN ('comment', 'reply', 'dm', 'bookmark', 'collab_request', 'system')),
  title TEXT NOT NULL CHECK (char_length(title) > 0 AND char_length(title) <= 200),
  message TEXT NOT NULL CHECK (char_length(message) > 0 AND char_length(message) <= 500),
  
  -- Related entities (nullable)
  related_post_id BIGINT REFERENCES posts(id) ON DELETE CASCADE,
  related_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  related_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  related_conversation_id TEXT, -- For DM notifications
  
  -- Metadata
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Optional action URL for deep linking
  action_url TEXT
);

-- Indexes for Performance ---------------------------------------------
-- Most common query: get unread notifications for a user, ordered by date
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread 
  ON notifications(user_id, read, created_at DESC) 
  WHERE read = FALSE;

-- Query all notifications for a user (read + unread)
CREATE INDEX IF NOT EXISTS idx_notifications_user_created 
  ON notifications(user_id, created_at DESC);

-- Query by type (e.g., show only DMs)
CREATE INDEX IF NOT EXISTS idx_notifications_type 
  ON notifications(type, created_at DESC);

-- Query notifications for a specific post
CREATE INDEX IF NOT EXISTS idx_notifications_post 
  ON notifications(related_post_id, created_at DESC) 
  WHERE related_post_id IS NOT NULL;

-- RLS Policies --------------------------------------------------------
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for clean reapplication)
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
DROP POLICY IF EXISTS "System can insert notifications" ON notifications;
DROP POLICY IF EXISTS "Authenticated users can create notifications" ON notifications;
DROP POLICY IF EXISTS "Users can delete their own notifications" ON notifications;

-- Users can only see their own notifications
CREATE POLICY "Users can view their own notifications"
  ON notifications
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Users can mark their own notifications as read
CREATE POLICY "Users can update their own notifications"
  ON notifications
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Any authenticated user can create notifications (required for cross-user notifications)
CREATE POLICY "Authenticated users can create notifications"
  ON notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Users can delete their own notifications
CREATE POLICY "Users can delete their own notifications"
  ON notifications
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Helper Functions ----------------------------------------------------

-- Function to create notifications (bypasses RLS via security definer)
CREATE OR REPLACE FUNCTION create_notification(
  p_user_id UUID,
  p_type VARCHAR(50),
  p_title TEXT,
  p_message TEXT,
  p_related_post_id BIGINT DEFAULT NULL,
  p_related_comment_id UUID DEFAULT NULL,
  p_related_user_id UUID DEFAULT NULL,
  p_related_conversation_id TEXT DEFAULT NULL,
  p_action_url TEXT DEFAULT NULL
)
RETURNS notifications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_notification notifications%ROWTYPE;
BEGIN
  INSERT INTO notifications (
    user_id,
    type,
    title,
    message,
    related_post_id,
    related_comment_id,
    related_user_id,
    related_conversation_id,
    action_url
  )
  VALUES (
    p_user_id,
    p_type,
    p_title,
    p_message,
    p_related_post_id,
    p_related_comment_id,
    p_related_user_id,
    p_related_conversation_id,
    p_action_url
  )
  RETURNING * INTO new_notification;

  RETURN new_notification;
END;
$$;

GRANT EXECUTE ON FUNCTION create_notification(
  UUID,
  VARCHAR,
  TEXT,
  TEXT,
  BIGINT,
  UUID,
  UUID,
  TEXT,
  TEXT
) TO authenticated;

-- Function to get unread count for a user
CREATE OR REPLACE FUNCTION get_unread_notification_count(target_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::INTEGER
    FROM notifications
    WHERE user_id = target_user_id
      AND read = FALSE
  );
END;
$$;

-- Function to mark all notifications as read for a user
CREATE OR REPLACE FUNCTION mark_all_notifications_read(target_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  updated_count INTEGER;
BEGIN
  UPDATE notifications
  SET read = TRUE
  WHERE user_id = target_user_id
    AND read = FALSE;
  
  GET DIAGNOSTICS updated_count = ROW_COUNT;
  RETURN updated_count;
END;
$$;

-- Function to clean old read notifications (older than 30 days)
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM notifications
  WHERE read = TRUE
    AND created_at < NOW() - INTERVAL '30 days';
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

-- Trigger to auto-update updated_at (if we add this column later)
-- CREATE OR REPLACE FUNCTION update_notifications_updated_at()
-- RETURNS TRIGGER AS $$
-- BEGIN
--   NEW.updated_at = NOW();
--   RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER notifications_updated_at
--   BEFORE UPDATE ON notifications
--   FOR EACH ROW
--   EXECUTE FUNCTION update_notifications_updated_at();

-- Grant Permissions ---------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON notifications TO authenticated;
GRANT EXECUTE ON FUNCTION get_unread_notification_count(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION mark_all_notifications_read(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_old_notifications() TO authenticated;

-- Comments ------------------------------------------------------------
COMMENT ON TABLE notifications IS 'In-app notifications for user activity and engagement';
COMMENT ON COLUMN notifications.type IS 'Notification type: comment, reply, dm, bookmark, collab_request, system';
COMMENT ON COLUMN notifications.read IS 'Whether the user has read this notification';
COMMENT ON COLUMN notifications.related_post_id IS 'Post ID if notification is related to a post';
COMMENT ON COLUMN notifications.related_comment_id IS 'Comment ID if notification is related to a comment';
COMMENT ON COLUMN notifications.related_user_id IS 'User who triggered the notification';
COMMENT ON COLUMN notifications.action_url IS 'Deep link URL for navigation (optional)';

-- Sample Notifications (for testing) ----------------------------------
-- Uncomment to insert test data after applying migration

-- INSERT INTO notifications (user_id, type, title, message, related_user_id)
-- VALUES 
--   (
--     (SELECT id FROM users LIMIT 1),
--     'comment',
--     'New comment on your post',
--     'John Doe commented on "Looking for a co-founder"',
--     (SELECT id FROM users OFFSET 1 LIMIT 1)
--   ),
--   (
--     (SELECT id FROM users LIMIT 1),
--     'reply',
--     'Someone replied to your comment',
--     'Sarah replied: "Great idea! I''m interested"',
--     (SELECT id FROM users OFFSET 2 LIMIT 1)
--   );

-- =====================================================================
-- DEPLOYMENT INSTRUCTIONS
-- =====================================================================
-- 1. Copy this file's contents
-- 2. Go to Supabase Dashboard → SQL Editor
-- 3. Create new query and paste
-- 4. Run the query
-- 5. Verify in Database → Tables that 'notifications' table exists
-- 6. Test with: SELECT * FROM notifications;
-- =====================================================================
