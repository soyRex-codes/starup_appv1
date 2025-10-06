# Messaging System Setup Guide

## 🗄️ Database Setup

### Step 1: Execute SQL Migration

Copy and paste the following SQL into your Supabase SQL Editor:

```sql
-- Enable Row Level Security
ALTER DEFAULT PRIVILEGES REVOKE ALL ON TABLES FROM public;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

-- Create conversations table
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type VARCHAR(10) NOT NULL DEFAULT 'direct' CHECK (type IN ('direct', 'group')),
  name VARCHAR(255), -- Only for group conversations
  description TEXT, -- Only for group conversations
  avatar_url TEXT, -- Only for group conversations
  created_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create participants table
CREATE TABLE IF NOT EXISTS participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role VARCHAR(10) NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  notifications_enabled BOOLEAN NOT NULL DEFAULT true,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(conversation_id, user_id)
);

-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT, -- Nullable for non-text messages
  message_type VARCHAR(10) NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'system')),
  file_url TEXT, -- For image and file messages
  file_name TEXT, -- Original filename for file messages
  file_size BIGINT, -- File size in bytes
  metadata JSONB, -- Additional message metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create message_status table for delivery tracking
CREATE TABLE IF NOT EXISTS message_status (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status VARCHAR(10) NOT NULL DEFAULT 'sent' CHECK (status IN ('sent', 'delivered', 'read')),
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(message_id, user_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_participants_user_id ON participants(user_id);
CREATE INDEX IF NOT EXISTS idx_participants_conversation_id ON participants(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_message_status_message_id ON message_status(message_id);
CREATE INDEX IF NOT EXISTS idx_message_status_user_id ON message_status(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON conversations(updated_at DESC);

-- Enable Realtime for live updates
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE participants;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE message_status;

-- Row Level Security Policies

-- Conversations: Users can only see conversations they're part of
CREATE POLICY "Users can view conversations they participate in" ON conversations
FOR SELECT USING (
  id IN (SELECT conversation_id FROM participants WHERE user_id = auth.uid())
);

CREATE POLICY "Users can create conversations" ON conversations
FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY "Participants can update conversations" ON conversations
FOR UPDATE USING (
  id IN (SELECT conversation_id FROM participants WHERE user_id = auth.uid())
);

-- Participants: Users can see participants in conversations they're part of
CREATE POLICY "Users can view participants in their conversations" ON participants
FOR SELECT USING (
  conversation_id IN (SELECT conversation_id FROM participants WHERE user_id = auth.uid())
);

CREATE POLICY "Users can add participants to conversations they created" ON participants
FOR INSERT WITH CHECK (
  conversation_id IN (
    SELECT id FROM conversations 
    WHERE created_by = auth.uid()
  )
);

CREATE POLICY "Users can remove themselves from conversations" ON participants
FOR DELETE USING (user_id = auth.uid());

-- Messages: Users can only see messages in conversations they're part of
CREATE POLICY "Users can view messages in their conversations" ON messages
FOR SELECT USING (
  conversation_id IN (SELECT conversation_id FROM participants WHERE user_id = auth.uid())
);

CREATE POLICY "Users can send messages to conversations they're part of" ON messages
FOR INSERT WITH CHECK (
  sender_id = auth.uid() AND
  conversation_id IN (SELECT conversation_id FROM participants WHERE user_id = auth.uid())
);

CREATE POLICY "Users can update their own messages" ON messages
FOR UPDATE USING (sender_id = auth.uid());

-- Message Status: Users can only see status for messages in their conversations
CREATE POLICY "Users can view message status in their conversations" ON message_status
FOR SELECT USING (
  message_id IN (
    SELECT m.id FROM messages m
    JOIN participants p ON m.conversation_id = p.conversation_id
    WHERE p.user_id = auth.uid()
  )
);

CREATE POLICY "Users can create message status for themselves" ON message_status
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own message status" ON message_status
FOR UPDATE USING (user_id = auth.uid());

-- Helper function to get or create direct conversation
CREATE OR REPLACE FUNCTION get_or_create_direct_conversation(other_user_id UUID)
RETURNS UUID AS $$
DECLARE
  conv_id UUID;
  current_user_id UUID := auth.uid();
BEGIN
  -- Check if conversation already exists
  SELECT c.id INTO conv_id
  FROM conversations c
  JOIN participants p1 ON c.id = p1.conversation_id AND p1.user_id = current_user_id
  JOIN participants p2 ON c.id = p2.conversation_id AND p2.user_id = other_user_id
  WHERE c.type = 'direct'
  LIMIT 1;
  
  IF conv_id IS NOT NULL THEN
    RETURN conv_id;
  END IF;
  
  -- Create new conversation
  INSERT INTO conversations (type, created_by)
  VALUES ('direct', current_user_id)
  RETURNING id INTO conv_id;
  
  -- Add both participants
  INSERT INTO participants (conversation_id, user_id) VALUES
  (conv_id, current_user_id),
  (conv_id, other_user_id);
  
  RETURN conv_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to update conversation timestamp
CREATE OR REPLACE FUNCTION update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations 
  SET updated_at = NOW() 
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update conversation timestamp on new message
DROP TRIGGER IF EXISTS update_conversation_on_message ON messages;
CREATE TRIGGER update_conversation_on_message
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_timestamp();

-- Enable RLS on all tables
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_status ENABLE ROW LEVEL SECURITY;
```

### Step 2: Test Database Connection

1. Open your app and navigate to Menu → "Test Messaging (Debug)"
2. Click "Test DB" button to verify connection
3. If successful, you should see a message confirming the database is connected

### Step 3: Test Messaging

1. Click "Test with Self" to create a conversation with yourself
2. Send test messages to verify the system works
3. Check real-time updates by opening the conversation in another tab/device

## 🚨 Common Issues

### Authentication Issues
- Ensure Firebase Auth and Supabase Auth are properly synced
- Check that the user is logged in to both systems

### Database Errors
- Verify all SQL statements executed successfully
- Check Supabase logs for any RLS policy issues
- Ensure the authenticated user has proper permissions

### Real-time Issues
- Verify Realtime is enabled in Supabase dashboard
- Check that the publication includes all messaging tables

## ✅ Success Indicators

- [ ] Database tables created successfully
- [ ] Test DB connection works
- [ ] Can create conversations
- [ ] Can send and receive messages
- [ ] Real-time updates work
- [ ] Unread counts update properly

## 🔧 Troubleshooting Commands

```bash
# Check Flutter dependencies
flutter pub get

# Clean build cache
flutter clean && flutter pub get

# Check for compilation errors
flutter analyze

# Run in debug mode with logs
flutter run --debug
```
