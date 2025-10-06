-- Instructions for manually applying database migration on Supabase

-- You need to run this SQL in your Supabase SQL editor to fix the database issues:

-- 1. Add the missing last_read_at column to participants table
ALTER TABLE participants ADD COLUMN IF NOT EXISTS last_read_at TIMESTAMPTZ;

-- 2. Update the get_or_create_direct_conversation function to handle conflicts
CREATE OR REPLACE FUNCTION get_or_create_direct_conversation(user1_id UUID, user2_id UUID)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE conv_id UUID; BEGIN
  -- Find existing direct conversation between these two users
  SELECT c.id INTO conv_id FROM conversations c
  WHERE c.type='direct'
    AND EXISTS (SELECT 1 FROM participants p1 WHERE p1.conversation_id=c.id AND p1.user_id=user1_id AND p1.left_at IS NULL)
    AND EXISTS (SELECT 1 FROM participants p2 WHERE p2.conversation_id=c.id AND p2.user_id=user2_id AND p2.left_at IS NULL)
    AND (SELECT COUNT(*) FROM participants p WHERE p.conversation_id=c.id AND p.left_at IS NULL)=2
  LIMIT 1;
  
  IF conv_id IS NOT NULL THEN 
    RETURN conv_id; 
  END IF;
  
  -- Create new conversation
  INSERT INTO conversations (type, created_by) VALUES ('direct', user1_id) RETURNING id INTO conv_id;
  
  -- Insert participants with ON CONFLICT handling
  INSERT INTO participants (conversation_id, user_id) 
  VALUES (conv_id, user1_id), (conv_id, user2_id)
  ON CONFLICT (conversation_id, user_id) DO NOTHING;
  
  RETURN conv_id; 
END; $$;

-- 3. Ensure mark_conversation_read function exists
CREATE OR REPLACE FUNCTION mark_conversation_read(conversation_id UUID, user_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE participants 
  SET last_read_at = NOW() 
  WHERE participants.conversation_id = mark_conversation_read.conversation_id 
    AND participants.user_id = mark_conversation_read.user_id 
    AND left_at IS NULL;
END; $$;

-- After running this SQL, restart your Flutter app and the messaging should work properly.
