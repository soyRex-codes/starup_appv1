-- Step 1: Drop old constraint
ALTER TABLE notifications 
DROP CONSTRAINT IF EXISTS notifications_type_check;

-- Step 2: Add new constraint with 'broadcast' type
ALTER TABLE notifications 
ADD CONSTRAINT notifications_type_check 
CHECK (type IN ('comment', 'reply', 'dm', 'bookmark', 'collab_request', 'system', 'broadcast'));

-- Step 3: Create RPC to create broadcast notifications for all users
CREATE OR REPLACE FUNCTION create_broadcast_notifications(title TEXT, body TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  count INTEGER;
BEGIN
  -- Verify admin status
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Forbidden: Only admins can send broadcasts';
  END IF;

  -- Insert notification for every user
  WITH inserted AS (
    INSERT INTO notifications (user_id, type, title, message, created_at)
    SELECT id, 'broadcast', title, body, NOW()
    FROM users
    RETURNING 1
  )
  SELECT count(*) INTO count FROM inserted;
  
  RETURN count;
END;
$$;

GRANT EXECUTE ON FUNCTION create_broadcast_notifications(TEXT, TEXT) TO authenticated;
