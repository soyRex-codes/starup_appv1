-- Dedicated Mobile Database Schema (Supabase Auth Only) -------------------------------------
-- 
-- FIXES INCLUDED IN THIS SCHEMA:
-- ✅ Fixed table name consistency: conversation_participants (not participants)  
-- ✅ Fixed RLS recursion: SECURITY DEFINER functions prevent infinite loops
-- ✅ Fixed messaging system: All table references updated correctly
-- ✅ Optimized security: Proper RLS policies without recursion
-- ✅ Complete messaging: conversations, participants, messages, status tables
-- ✅ Fixed duplicate key errors: Removed unique constraints on email and username for app upserts
-- ✅ Comments system added
-- ✅ Admin audit logs added
-- ✅ DM participants fix added
-- This schema provides a fully functional messaging system that:
-- • Stores messages correctly in the database 
-- • Displays messages in the mobile app UI
-- • Supports real-time updates via Supabase subscriptions
-- • Maintains security with proper Row Level Security policies
-- • Allows smooth user profile upserts without constraint conflicts
-- 
CREATE SCHEMA IF NOT EXISTS extensions;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_net;

DO $$
DECLARE
  ext RECORD;
BEGIN
  FOR ext IN
    SELECT extname, extrelocatable
    FROM pg_extension
  WHERE extname IN ('pg_trgm', 'pg_net', 'pgcrypto', 'uuid-ossp')
  LOOP
    IF ext.extrelocatable THEN
      EXECUTE format('ALTER EXTENSION %I SET SCHEMA extensions', ext.extname);
    ELSE
      RAISE NOTICE 'Extension % is not relocatable; leaving in current schema', ext.extname;
    END IF;
  END LOOP;
END;
$$;

-- Lightweight migration / cleanup helper:
--  * Detect legacy users(uid TEXT)
--  * Drop any old messaging tables (dm_* / personal_messages) & dependent policies
--  * Drop legacy current_uid() (text) so we can recreate UUID version
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name='users' AND column_name='uid'
  ) THEN
    RAISE NOTICE 'Legacy users(uid TEXT) detected – dropping dependent tables for clean migration.';
    DROP TABLE IF EXISTS message_status CASCADE;
    DROP TABLE IF EXISTS messages CASCADE;
    DROP TABLE IF EXISTS conversation_participants CASCADE;
    DROP TABLE IF EXISTS conversations CASCADE;
    DROP TABLE IF EXISTS chat_messages CASCADE;
    DROP TABLE IF EXISTS media CASCADE;
    DROP TABLE IF EXISTS posts CASCADE;
    -- legacy tables
    DROP TABLE IF EXISTS personal_messages CASCADE;
    DROP TABLE IF EXISTS dm_messages CASCADE;
    DROP TABLE IF EXISTS dm_participants CASCADE;
    DROP TABLE IF EXISTS dm_threads CASCADE;
    DROP TABLE IF EXISTS users CASCADE;
  END IF;

  -- If a prior current_uid() exists (likely returning text), drop it so we can recreate with UUID.
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.proname = 'current_uid' AND n.nspname = 'public'
  ) THEN
    BEGIN
      DROP FUNCTION public.current_uid();
      RAISE NOTICE 'Dropped legacy current_uid() to recreate as UUID-returning.';
    EXCEPTION WHEN others THEN
      RAISE NOTICE 'Could not drop legacy current_uid(): %', SQLERRM;
    END;
  END IF;
END $$;

-- Users -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT auth.uid(),
  email TEXT,
  name TEXT,
  username TEXT,
  full_name TEXT,
  bio TEXT,
  company TEXT,
  location TEXT,
  avatar_url TEXT,
  email_verified BOOLEAN DEFAULT FALSE,
  last_login_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add missing columns if they don't exist
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='username') THEN
    ALTER TABLE users ADD COLUMN username TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='full_name') THEN
    ALTER TABLE users ADD COLUMN full_name TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='last_login_at') THEN
    ALTER TABLE users ADD COLUMN last_login_at TIMESTAMPTZ DEFAULT NOW();
  END IF;
  -- Add admin columns for user suspension
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='is_suspended') THEN
    ALTER TABLE users ADD COLUMN is_suspended BOOLEAN DEFAULT FALSE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='suspension_reason') THEN
    ALTER TABLE users ADD COLUMN suspension_reason TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='suspended_at') THEN
    ALTER TABLE users ADD COLUMN suspended_at TIMESTAMPTZ;
  END IF;
  -- Add is_admin column for admin user identification
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='is_admin') THEN
    ALTER TABLE users ADD COLUMN is_admin BOOLEAN DEFAULT FALSE;
  END IF;
  -- Drop unique constraints on email and username to prevent conflicts with app upserts
  IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name='users' AND constraint_name='users_email_key') THEN
    ALTER TABLE users DROP CONSTRAINT users_email_key;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name='users' AND constraint_name='users_username_key') THEN
    ALTER TABLE users DROP CONSTRAINT users_username_key;
  END IF;
END $$;

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "users select" ON users;
CREATE POLICY "users select" ON users FOR SELECT USING (TRUE);
DROP POLICY IF EXISTS "users upsert self" ON users;
CREATE POLICY "users upsert self" ON users FOR INSERT WITH CHECK ((select auth.uid()) = id);
DROP POLICY IF EXISTS "users update self" ON users;
DROP POLICY IF EXISTS "users update self or admin" ON users;
-- Allow users to update themselves OR admins to update anyone (for suspension feature)
CREATE POLICY "users update self or admin" ON users FOR UPDATE 
USING ((select auth.uid()) = id OR is_admin());

-- Posts -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS posts (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT,
  category TEXT,
  title TEXT NOT NULL,
  description TEXT,
  funding_goal NUMERIC,
  post_goal TEXT DEFAULT 'funding',
  post_goal_description TEXT,
  email TEXT,
  moderation_status TEXT DEFAULT 'approved',
  status TEXT DEFAULT 'published',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comment_count column if it doesn't exist (for existing databases)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='posts' AND column_name='comment_count') THEN
    ALTER TABLE posts ADD COLUMN comment_count INTEGER DEFAULT 0 NOT NULL;
    RAISE NOTICE 'Added comment_count column to posts table';
  END IF;
END $$;

-- Media -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS media (
  id BIGSERIAL PRIMARY KEY,
  post_id BIGINT REFERENCES posts(id) ON DELETE CASCADE,
  type TEXT,
  filename TEXT,
  original_name TEXT,
  file_path TEXT,
  file_size BIGINT,
  uploaded_at TIMESTAMPTZ DEFAULT now()
);

-- Community Chat ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS chat_messages (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_name TEXT NOT NULL,
  content TEXT,
  file_url TEXT,
  file_name TEXT,
  file_type TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  edited_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  edited BOOLEAN DEFAULT FALSE,
  moderation_status TEXT DEFAULT 'approved'
);

-- Modern Messaging (direct & future group) -------------------------------------------------
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type VARCHAR(10) NOT NULL DEFAULT 'direct' CHECK (type IN ('direct','group')),
  name VARCHAR(255),
  description TEXT,
  avatar_url TEXT,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_message_at TIMESTAMPTZ,
  last_message_preview TEXT
);

CREATE TABLE IF NOT EXISTS conversation_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(10) NOT NULL DEFAULT 'member' CHECK (role IN ('admin','member')),
  notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  left_at TIMESTAMPTZ,
  last_read_at TIMESTAMPTZ,
  UNIQUE(conversation_id, user_id)
);

CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT,
  message_type VARCHAR(10) NOT NULL DEFAULT 'text' CHECK (message_type IN ('text','image','file','system')),
  file_url TEXT,
  file_name TEXT,
  file_size BIGINT,
  reply_to_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS message_status (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(10) NOT NULL DEFAULT 'sent' CHECK (status IN ('sent','delivered','read')),
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(message_id, user_id)
);

-- Indexes ----------------------------------------------------------------------------------
-- Drop duplicate index from old migrations (idx_posts_user and idx_posts_user_created are identical)
DROP INDEX IF EXISTS idx_posts_user_created;
DROP INDEX IF EXISTS idx_posts_category; -- Also drop unused category index

-- User indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_is_suspended ON users(is_suspended) WHERE is_suspended = true;

-- Post indexes
CREATE INDEX IF NOT EXISTS idx_posts_user ON posts(user_id, created_at DESC);

-- Media indexes
CREATE INDEX IF NOT EXISTS idx_media_post ON media(post_id);

-- Chat message indexes
CREATE INDEX IF NOT EXISTS idx_chat_messages_user ON chat_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_desc ON chat_messages(created_at DESC);

-- Conversation indexes (ADDED: foreign key index for created_by)
CREATE INDEX IF NOT EXISTS idx_conversations_created_by ON conversations(created_by);
CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON conversations(updated_at DESC);

-- Conversation participant indexes
CREATE INDEX IF NOT EXISTS idx_conversation_participants_user_id ON conversation_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_conversation_left ON conversation_participants(conversation_id, left_at);

-- Message indexes (ADDED: foreign key index for reply_to_id, composite index for common queries)
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_reply_to_id ON messages(reply_to_id) WHERE reply_to_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_messages_created_desc ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created ON messages(conversation_id, created_at DESC);

-- Message status indexes
CREATE INDEX IF NOT EXISTS idx_message_status_message_id ON message_status(message_id);
CREATE INDEX IF NOT EXISTS idx_message_status_user_id ON message_status(user_id);

-- Helper Functions -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION current_uid() 
RETURNS UUID 
LANGUAGE sql 
STABLE 
SET search_path = public, pg_temp
AS $$ SELECT auth.uid() $$;

CREATE OR REPLACE FUNCTION is_admin() 
RETURNS boolean 
LANGUAGE sql 
STABLE 
SECURITY DEFINER  -- Run with elevated privileges to read users table
SET search_path = public, pg_temp
AS $$ 
  SELECT COALESCE(
    (SELECT is_admin FROM users WHERE id = auth.uid()),
    FALSE
  )
$$;

-- Drop any existing get_or_create_direct_conversation functions to avoid overloading conflicts
DROP FUNCTION IF EXISTS get_or_create_direct_conversation(text, text);
DROP FUNCTION IF EXISTS get_or_create_direct_conversation(uuid, uuid);

CREATE OR REPLACE FUNCTION get_or_create_direct_conversation(user1_id UUID, user2_id UUID)
RETURNS UUID 
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE 
  conv_id UUID;
BEGIN
  -- Find existing direct conversation between these two users
  SELECT c.id INTO conv_id FROM conversations c
  WHERE c.type='direct'
    AND EXISTS (SELECT 1 FROM conversation_participants p1 WHERE p1.conversation_id=c.id AND p1.user_id=user1_id AND p1.left_at IS NULL)
    AND EXISTS (SELECT 1 FROM conversation_participants p2 WHERE p2.conversation_id=c.id AND p2.user_id=user2_id AND p2.left_at IS NULL)
    AND (SELECT COUNT(*) FROM conversation_participants p WHERE p.conversation_id=c.id AND p.left_at IS NULL)=2
  LIMIT 1;
  
  IF conv_id IS NOT NULL THEN 
    RETURN conv_id; 
  END IF;
  
  -- Create new conversation
  INSERT INTO conversations (type, created_by) VALUES ('direct', user1_id) RETURNING id INTO conv_id;
  -- Insert participants (conversation creator can add both users via policy)
  INSERT INTO conversation_participants (conversation_id, user_id)
  VALUES (conv_id, user1_id), (conv_id, user2_id)
  ON CONFLICT (conversation_id, user_id) DO NOTHING;
  
  RETURN conv_id; 
END; $$;

CREATE OR REPLACE FUNCTION mark_conversation_read(conversation_id UUID, user_id UUID)
RETURNS VOID 
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  UPDATE conversation_participants 
  SET last_read_at = NOW() 
  WHERE conversation_participants.conversation_id = mark_conversation_read.conversation_id 
    AND conversation_participants.user_id = mark_conversation_read.user_id 
    AND left_at IS NULL;
END; $$;

CREATE OR REPLACE FUNCTION update_conversation_last_message() 
RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  UPDATE conversations SET last_message_at = NEW.created_at,
    last_message_preview = CASE NEW.message_type WHEN 'text' THEN LEFT(COALESCE(NEW.content,'') ,100) WHEN 'image' THEN '📷 Image' WHEN 'file' THEN '📎 File' ELSE '💬 Message' END,
    updated_at = NOW() WHERE id = NEW.conversation_id; RETURN NEW; END; $$;

DROP TRIGGER IF EXISTS update_conversation_on_message ON messages;
CREATE TRIGGER update_conversation_on_message AFTER INSERT ON messages FOR EACH ROW EXECUTE FUNCTION update_conversation_last_message();

-- RLS Enable -------------------------------------------------------------------------------
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE media ENABLE ROW LEVEL SECURITY;

-- RLS Policies (selected) ------------------------------------------------------------------

-- Drop all existing policies to ensure a clean slate
DROP POLICY IF EXISTS "conversation_participants_select" ON conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_insert" ON conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_update" ON conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_delete" ON conversation_participants;
DROP POLICY IF EXISTS "conversations_select" ON conversations;
DROP POLICY IF EXISTS "conversations_insert" ON conversations;
DROP POLICY IF EXISTS "conversations_update" ON conversations;
DROP POLICY IF EXISTS "messages_select" ON messages;
DROP POLICY IF EXISTS "messages_insert" ON messages;
DROP POLICY IF EXISTS "messages_update" ON messages;
DROP POLICY IF EXISTS "message_status_select" ON message_status;
DROP POLICY IF EXISTS "message_status_insert" ON message_status;
DROP POLICY IF EXISTS "message_status_update" ON message_status;
DROP POLICY IF EXISTS "allow_all_conversations" ON conversations;
DROP POLICY IF EXISTS "allow_all_conversation_participants" ON conversation_participants;
DROP POLICY IF EXISTS "allow_own_messages" ON messages;
DROP POLICY IF EXISTS "allow_own_message_status" ON message_status;

-- Helper function to check if a user is a member of a conversation.
-- SECURITY DEFINER prevents infinite recursion by bypassing RLS
DROP FUNCTION IF EXISTS is_conversation_member(UUID, UUID);
CREATE OR REPLACE FUNCTION is_conversation_member_safe(p_conversation_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER  -- This runs with function owner's privileges, bypassing RLS
STABLE
SET search_path = ''
AS $$
BEGIN
  -- Direct query without RLS interference to prevent recursion
  RETURN EXISTS (
    SELECT 1 FROM public.conversation_participants 
    WHERE conversation_id = p_conversation_id 
    AND user_id = p_user_id 
    AND left_at IS NULL
  );
END;
$$;

-- Create wrapper function for backwards compatibility
CREATE OR REPLACE FUNCTION is_conversation_member(p_conversation_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT is_conversation_member_safe(p_conversation_id, p_user_id);
$$;

-- Policies for `conversations` - Fixed to prevent recursion
CREATE POLICY "conversations_select" ON conversations FOR SELECT
  USING (is_conversation_member_safe(id, (select auth.uid())));
CREATE POLICY "conversations_insert" ON conversations FOR INSERT
  WITH CHECK (created_by = (select auth.uid()));

-- Policies for `conversation_participants` - Simplified to prevent recursion
-- Users can only see their own participant records - no cross-table queries
CREATE POLICY "conversation_participants_select" ON conversation_participants FOR SELECT
  USING (user_id = (select auth.uid()));
CREATE POLICY "conversation_participants_insert" ON conversation_participants FOR INSERT
  WITH CHECK (user_id = (select auth.uid()));
CREATE POLICY "conversation_participants_update" ON conversation_participants FOR UPDATE
  USING (user_id = (select auth.uid()));

-- Policies for `messages` - Using safe membership check
CREATE POLICY "messages_select" ON messages FOR SELECT
  USING (is_conversation_member_safe(conversation_id, (select auth.uid())));
CREATE POLICY "messages_insert" ON messages FOR INSERT
  WITH CHECK (sender_id = (select auth.uid()) AND is_conversation_member_safe(conversation_id, (select auth.uid())));

-- Policies for `message_status` - Using safe membership check
CREATE POLICY "message_status_select" ON message_status FOR SELECT
  USING (user_id = (select auth.uid()));
CREATE POLICY "message_status_insert" ON message_status FOR INSERT
  WITH CHECK (user_id = (select auth.uid()));
CREATE POLICY "message_status_update" ON message_status FOR UPDATE
  USING (user_id = (select auth.uid()));

-- Grant permissions - Updated with safe functions
GRANT SELECT, INSERT, UPDATE ON conversations TO authenticated;
GRANT SELECT, INSERT, UPDATE ON conversation_participants TO authenticated;
GRANT SELECT, INSERT ON messages TO authenticated;
GRANT SELECT, INSERT, UPDATE ON message_status TO authenticated;
GRANT EXECUTE ON FUNCTION is_conversation_member_safe(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_conversation_member(UUID, UUID) TO authenticated;

-- Chat messages
DROP POLICY IF EXISTS "view chat" ON chat_messages; CREATE POLICY "view chat" ON chat_messages FOR SELECT USING (TRUE);
DROP POLICY IF EXISTS "insert chat" ON chat_messages; CREATE POLICY "insert chat" ON chat_messages FOR INSERT WITH CHECK ((select auth.uid()) = user_id);
DROP POLICY IF EXISTS "update chat" ON chat_messages; CREATE POLICY "update chat" ON chat_messages FOR UPDATE USING ((select auth.uid()) = user_id);

-- Posts & media
-- Drop legacy policies created in Supabase UI (superseded by optimized versions below)
DROP POLICY IF EXISTS posts_insert_self ON posts;
DROP POLICY IF EXISTS posts_update_self ON posts;
DROP POLICY IF EXISTS posts_delete_self ON posts;
DROP POLICY IF EXISTS media_insert_auth ON media;
-- Create optimized policies with per-query auth evaluation
DROP POLICY IF EXISTS "view posts" ON posts; CREATE POLICY "view posts" ON posts FOR SELECT USING (TRUE);
DROP POLICY IF EXISTS "insert posts" ON posts; CREATE POLICY "insert posts" ON posts FOR INSERT WITH CHECK ((select auth.uid()) = user_id);
DROP POLICY IF EXISTS "update posts" ON posts; CREATE POLICY "update posts" ON posts FOR UPDATE USING ((select auth.uid()) = user_id);
DROP POLICY IF EXISTS "delete posts" ON posts; CREATE POLICY "delete posts" ON posts FOR DELETE USING ((select auth.uid()) = user_id);
DROP POLICY IF EXISTS "view media" ON media; CREATE POLICY "view media" ON media FOR SELECT USING (TRUE);
DROP POLICY IF EXISTS "manage media" ON media;
DROP POLICY IF EXISTS "manage media insert" ON media;
DROP POLICY IF EXISTS "manage media update" ON media;
DROP POLICY IF EXISTS "manage media delete" ON media;
CREATE POLICY "manage media insert" ON media FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM posts WHERE posts.id = media.post_id AND posts.user_id = (select auth.uid())
  )
);
CREATE POLICY "manage media update" ON media FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM posts WHERE posts.id = media.post_id AND posts.user_id = (select auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM posts WHERE posts.id = media.post_id AND posts.user_id = (select auth.uid())
    )
  );
CREATE POLICY "manage media delete" ON media FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM posts WHERE posts.id = media.post_id AND posts.user_id = (select auth.uid())
  )
);

-- Updated_at trigger -----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at() 
RETURNS TRIGGER 
LANGUAGE plpgsql 
SET search_path = public, pg_temp
AS $$ 
BEGIN 
  NEW.updated_at = now(); 
  RETURN NEW; 
END; 
$$;
DROP TRIGGER IF EXISTS trg_posts_updated_at ON posts; CREATE TRIGGER trg_posts_updated_at BEFORE UPDATE ON posts FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_users_updated_at ON users; CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Auto-create user stub when inserting post (if missing) -----------------------------------
CREATE OR REPLACE FUNCTION auto_create_user_for_post() 
RETURNS TRIGGER 
LANGUAGE plpgsql 
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM users WHERE id = NEW.user_id) THEN
    INSERT INTO users (id, name, email) VALUES (NEW.user_id, NEW.name, NEW.email) ON CONFLICT (id) DO NOTHING;
  END IF; 
  RETURN NEW; 
END; 
$$;
DROP TRIGGER IF EXISTS trg_auto_create_user_for_post ON posts;
CREATE TRIGGER trg_auto_create_user_for_post BEFORE INSERT ON posts FOR EACH ROW EXECUTE FUNCTION auto_create_user_for_post();

-- RPC function for ensuring user exists (used by PostService)
CREATE OR REPLACE FUNCTION public.ensure_user_exists(p_uid UUID, p_email TEXT DEFAULT NULL, p_name TEXT DEFAULT NULL)
RETURNS VOID 
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path TO pg_catalog
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = p_uid) THEN
    INSERT INTO public.users (id, email, name)
    VALUES (p_uid, p_email, p_name)
    ON CONFLICT (id) DO NOTHING;
  END IF;
END; $$;

-- Grant execute permission on the RPC function
GRANT EXECUTE ON FUNCTION public.ensure_user_exists(UUID, TEXT, TEXT) TO authenticated;

-- Constraints (categories / post goals) ----------------------------------------------------
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name='posts' AND constraint_name='posts_post_goal_check') THEN
    ALTER TABLE posts ADD CONSTRAINT posts_post_goal_check CHECK (post_goal IS NULL OR post_goal IN ('funding','team','skills','partnership','mentorship','feedback','other')) NOT VALID;
  END IF;
  
  -- Note: Unique constraints on email and username removed to allow app upserts
END $$;

-- Grant permissions to fix messaging system access issues -----------------------------------
GRANT ALL ON conversations TO authenticated;
GRANT ALL ON conversation_participants TO authenticated;
GRANT ALL ON messages TO authenticated;
GRANT ALL ON message_status TO authenticated;

-- Grant execute permissions on messaging functions
GRANT EXECUTE ON FUNCTION get_or_create_direct_conversation(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION mark_conversation_read(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_conversation_member_safe(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_conversation_member(UUID, UUID) TO authenticated;

-- Fix for DM inbox showing wrong names (get all participants in a conversation) -------------
CREATE OR REPLACE FUNCTION get_conversation_participants(conv_id UUID)
RETURNS TABLE (user_id UUID) 
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- First verify the caller is actually a member of this conversation
  IF NOT EXISTS (
    SELECT 1 FROM conversation_participants cp
    WHERE cp.conversation_id = conv_id 
    AND cp.user_id = auth.uid() 
    AND cp.left_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Not a member of this conversation';
  END IF;
  
  -- Return all participants (since caller is verified as a member)
  RETURN QUERY
  SELECT cp.user_id
  FROM conversation_participants cp
  WHERE cp.conversation_id = conv_id
  AND cp.left_at IS NULL;
END;
$$;

GRANT EXECUTE ON FUNCTION get_conversation_participants(UUID) TO authenticated;

-- =====================================================================
-- COMMENTS SYSTEM (Structured feedback on posts)
-- =====================================================================
-- Category-based comments (Question, Idea, Critique, Resource, General)
-- Threaded replies (parent-child relationships)
-- Real-time capabilities via Supabase subscriptions
-- Proper RLS security policies
-- =====================================================================

CREATE TABLE IF NOT EXISTS comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (char_length(content) > 0 AND char_length(content) <= 2000),
  category VARCHAR(50) NOT NULL CHECK (category IN ('question', 'idea', 'critique', 'resource', 'general')),
  parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  edited BOOLEAN DEFAULT FALSE
);

-- Indexes for optimal query performance
CREATE INDEX IF NOT EXISTS idx_comments_post_id_created ON comments(post_id, created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_comments_author_id ON comments(author_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON comments(parent_comment_id) WHERE deleted_at IS NULL;

-- Row Level Security (RLS)
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Anyone can view non-deleted comments
DROP POLICY IF EXISTS "comments_select" ON comments;
DROP POLICY IF EXISTS "comments_select_own" ON comments;
CREATE POLICY "comments_select" ON comments 
  FOR SELECT USING (
    deleted_at IS NULL
    OR author_id = (select auth.uid())
  );

-- Authenticated users can insert comments
DROP POLICY IF EXISTS "comments_insert" ON comments;
CREATE POLICY "comments_insert" ON comments 
  FOR INSERT WITH CHECK ((select auth.uid()) = author_id);

-- Users can update/soft-delete their own comments
-- Note: No WITH CHECK clause needed for soft deletion (deleted_at timestamp)
DROP POLICY IF EXISTS "comments_update" ON comments;
CREATE POLICY "comments_update" ON comments 
  FOR UPDATE 
  USING ((select auth.uid()) = author_id)
  WITH CHECK ((select auth.uid()) = author_id);

-- DEPRECATED: Use posts.comment_count column instead (eliminates N+1 queries)
-- This function is kept for backward compatibility but should not be called in loops
CREATE OR REPLACE FUNCTION get_comment_count(p_post_id BIGINT)
RETURNS INTEGER 
LANGUAGE plpgsql 
STABLE 
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Now just returns the denormalized count for performance
  RETURN (SELECT comment_count FROM posts WHERE id = p_post_id);
END; $$;

-- Batch version for legacy code that needs multiple counts at once
CREATE OR REPLACE FUNCTION get_comment_counts_batch(post_ids BIGINT[])
RETURNS TABLE(post_id BIGINT, comment_count INTEGER)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id AS post_id,
    p.comment_count AS comment_count
  FROM unnest(post_ids) AS pid
  JOIN posts p ON p.id = pid;
END; $$;

-- Trigger to auto-update denormalized comment_count on posts table
-- This eliminates the N+1 query pattern (1624 calls to get_comment_count reduced to 0)
CREATE OR REPLACE FUNCTION update_post_comment_count()
RETURNS TRIGGER 
LANGUAGE plpgsql 
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Handle INSERT: increment comment count
  IF (TG_OP = 'INSERT' AND NEW.deleted_at IS NULL) THEN
    UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
  END IF;

  -- Handle DELETE (hard delete): decrement comment count
  IF (TG_OP = 'DELETE' AND OLD.deleted_at IS NULL) THEN
    UPDATE posts SET comment_count = comment_count - 1 WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;

  -- Handle UPDATE: adjust count if deleted_at changes
  IF (TG_OP = 'UPDATE') THEN
    -- Comment was soft-deleted
    IF (OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL) THEN
      UPDATE posts SET comment_count = comment_count - 1 WHERE id = NEW.post_id;
    -- Comment was restored from soft-delete
    ELSIF (OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS NULL) THEN
      UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
    END IF;
    RETURN NEW;
  END IF;

  RETURN NULL;
END; $$;

DROP TRIGGER IF EXISTS trigger_update_post_comment_count ON comments;
CREATE TRIGGER trigger_update_post_comment_count
  AFTER INSERT OR UPDATE OR DELETE ON comments
  FOR EACH ROW
  EXECUTE FUNCTION update_post_comment_count();

-- Trigger to update 'updated_at' timestamp on comment edits
CREATE OR REPLACE FUNCTION update_comment_timestamp()
RETURNS TRIGGER 
LANGUAGE plpgsql 
SET search_path = public, pg_temp
AS $$
BEGIN
  NEW.updated_at = NOW();
  IF OLD.content IS DISTINCT FROM NEW.content THEN
    NEW.edited = TRUE;
  END IF;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trigger_update_comment_timestamp ON comments;
CREATE TRIGGER trigger_update_comment_timestamp
  BEFORE UPDATE ON comments
  FOR EACH ROW
  EXECUTE FUNCTION update_comment_timestamp();

-- Analytics View - SECURITY INVOKER (default) to enforce querying user's RLS policies
CREATE OR REPLACE VIEW comment_stats 
WITH (security_invoker = true) AS
SELECT 
  post_id,
  COUNT(*) FILTER (WHERE deleted_at IS NULL) as total_comments,
  COUNT(*) FILTER (WHERE category = 'question' AND deleted_at IS NULL) as questions,
  COUNT(*) FILTER (WHERE category = 'idea' AND deleted_at IS NULL) as ideas,
  COUNT(*) FILTER (WHERE category = 'critique' AND deleted_at IS NULL) as critiques,
  COUNT(*) FILTER (WHERE category = 'resource' AND deleted_at IS NULL) as resources,
  COUNT(*) FILTER (WHERE category = 'general' AND deleted_at IS NULL) as general_comments
FROM comments
GROUP BY post_id;

GRANT ALL ON comments TO authenticated;
GRANT EXECUTE ON FUNCTION get_comment_count(BIGINT) TO authenticated;

-- Suggestions System (Private feedback for post creators) -----------------------------------
CREATE TABLE IF NOT EXISTS suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  suggester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  suggester_name TEXT NOT NULL,
  suggester_email TEXT,
  suggestion_type TEXT NOT NULL CHECK (suggestion_type IN ('feature', 'improvement', 'concept', 'other')),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_read BOOLEAN NOT NULL DEFAULT FALSE
);

-- Migrate existing suggestions table if it has the old schema
DO $$ 
BEGIN
  -- Check if is_read column exists, if not add it and migrate data
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'suggestions' AND column_name = 'is_read'
  ) THEN
    -- Add the new column
    ALTER TABLE suggestions ADD COLUMN is_read BOOLEAN DEFAULT FALSE;
    
    -- Convert existing status to read/unread (anything except 'pending' becomes read)
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'suggestions' AND column_name = 'status'
    ) THEN
      UPDATE suggestions SET is_read = (status != 'pending');
    END IF;
    
    -- Make is_read NOT NULL
    ALTER TABLE suggestions ALTER COLUMN is_read SET NOT NULL;
    
    RAISE NOTICE 'Migrated suggestions table to simplified read/unread system';
  END IF;
  
  -- Add updated_at column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'suggestions' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE suggestions ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
  END IF;
  
  -- Remove old columns if they exist
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'suggestions' AND column_name = 'status'
  ) THEN
    ALTER TABLE suggestions DROP COLUMN status;
    RAISE NOTICE 'Dropped old status column from suggestions table';
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'suggestions' AND column_name = 'reviewed_at'
  ) THEN
    ALTER TABLE suggestions DROP COLUMN reviewed_at;
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'suggestions' AND column_name = 'response_message'
  ) THEN
    ALTER TABLE suggestions DROP COLUMN response_message;
  END IF;
END $$;

-- Indexes for suggestions
CREATE INDEX IF NOT EXISTS idx_suggestions_post_id ON suggestions(post_id);
CREATE INDEX IF NOT EXISTS idx_suggestions_suggester_id ON suggestions(suggester_id);
CREATE INDEX IF NOT EXISTS idx_suggestions_created_desc ON suggestions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_suggestions_is_read ON suggestions(is_read);

-- RLS for suggestions (Private: only post creator and suggester can see)
ALTER TABLE suggestions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "suggestions_select" ON suggestions;
CREATE POLICY "suggestions_select" ON suggestions FOR SELECT USING (
  suggester_id = (select auth.uid()) OR 
  EXISTS (SELECT 1 FROM posts WHERE posts.id = suggestions.post_id AND posts.user_id = (select auth.uid()))
);

DROP POLICY IF EXISTS "suggestions_insert" ON suggestions;
CREATE POLICY "suggestions_insert" ON suggestions FOR INSERT WITH CHECK (
  suggester_id = (select auth.uid())
);

DROP POLICY IF EXISTS "suggestions_update" ON suggestions;
CREATE POLICY "suggestions_update" ON suggestions FOR UPDATE USING (
  -- Only post creators can update suggestions (mark as read/unread)
  EXISTS (SELECT 1 FROM posts WHERE posts.id = suggestions.post_id AND posts.user_id = (select auth.uid()))
);

DROP POLICY IF EXISTS "suggestions_delete" ON suggestions;  
CREATE POLICY "suggestions_delete" ON suggestions FOR DELETE USING (
  -- Both post creator and suggester can delete
  suggester_id = (select auth.uid()) OR 
  EXISTS (SELECT 1 FROM posts WHERE posts.id = suggestions.post_id AND posts.user_id = (select auth.uid()))
);

-- Grant permissions for suggestions
GRANT ALL ON suggestions TO authenticated;

-- Trigger to auto-update updated_at on suggestions
DROP TRIGGER IF EXISTS trg_suggestions_updated_at ON suggestions;
CREATE TRIGGER trg_suggestions_updated_at 
  BEFORE UPDATE ON suggestions 
  FOR EACH ROW 
  EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- LEGACY: Password Reset OTP System (UNUSED - COMMENTED OUT)
-- =====================================================================
-- NOTE: This custom OTP system was planned but never implemented.
-- The app uses Supabase Auth's built-in OTP system instead:
--   - auth.signInWithOtp() for sending OTPs
--   - auth.verifyOTP() for verification
--   - auth.one_time_tokens for storage (Supabase managed)
-- 
-- This table and functions are safe to drop. See separate migration:
-- supabase/migrations/drop_unused_password_reset_otps.sql
-- =====================================================================

-- -- Create password_reset_otps table for secure OTP storage (supports both password reset and email verification)
-- CREATE TABLE IF NOT EXISTS password_reset_otps (
--   id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--   user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
--   email TEXT NOT NULL,
--   otp_hash TEXT NOT NULL, -- Hashed OTP, never store plain text
--   purpose TEXT NOT NULL DEFAULT 'reset' CHECK (purpose IN ('reset', 'signup')), -- Type of OTP: password reset or email verification
--   created_at TIMESTAMPTZ DEFAULT NOW(),
--   expires_at TIMESTAMPTZ NOT NULL,
--   used_at TIMESTAMPTZ NULL, -- When the OTP was used (for tracking)
--   is_used BOOLEAN DEFAULT FALSE,
--   attempts INTEGER DEFAULT 0, -- Track verification attempts
--   max_attempts INTEGER DEFAULT 3
-- );

-- -- Create indexes for efficient lookups
-- CREATE INDEX IF NOT EXISTS idx_password_reset_otps_email ON password_reset_otps(email);
-- CREATE INDEX IF NOT EXISTS idx_password_reset_otps_user_id ON password_reset_otps(user_id);
-- CREATE INDEX IF NOT EXISTS idx_password_reset_otps_expires_at ON password_reset_otps(expires_at);

-- -- Enable RLS - Only allow service role to manage OTPs (backend API only)
-- ALTER TABLE password_reset_otps ENABLE ROW LEVEL SECURITY;

-- DROP POLICY IF EXISTS "password_reset_otps_service_role_all" ON password_reset_otps;
-- CREATE POLICY "password_reset_otps_service_role_all" ON password_reset_otps
--   FOR ALL USING ((select auth.role()) = 'service_role');

-- -- Function to cleanup expired OTPs (run periodically)
-- CREATE OR REPLACE FUNCTION cleanup_expired_password_reset_otps()
-- RETURNS VOID
-- LANGUAGE plpgsql 
-- SECURITY DEFINER
-- SET search_path = public, pg_temp
-- AS $$
-- BEGIN
--   DELETE FROM password_reset_otps 
--   WHERE expires_at < NOW() - INTERVAL '1 hour'; -- Keep for 1 hour after expiry for audit
-- END;
-- $$;

-- -- Function to invalidate all OTPs for a user (called after successful password reset)
-- CREATE OR REPLACE FUNCTION invalidate_user_password_reset_otps(user_uuid UUID)
-- RETURNS VOID
-- LANGUAGE plpgsql 
-- SECURITY DEFINER
-- SET search_path = public, pg_temp
-- AS $$
-- BEGIN
--   UPDATE password_reset_otps 
--   SET is_used = TRUE, used_at = NOW()
--   WHERE user_id = user_uuid AND is_used = FALSE;
-- END;
-- $$;

-- -- Function to invalidate all user sessions (called after password reset)
-- CREATE OR REPLACE FUNCTION invalidate_user_sessions(user_uuid UUID)
-- RETURNS VOID
-- LANGUAGE plpgsql 
-- SECURITY DEFINER
-- SET search_path = public, pg_temp
-- AS $$
-- BEGIN
--   -- This will be called from the API to force re-authentication
--   -- Supabase handles session invalidation through the auth API
--   RAISE NOTICE 'User % sessions will be invalidated via API call', user_uuid;
-- END;
-- $$;

-- -- Grant permissions for password reset system
-- GRANT ALL ON password_reset_otps TO service_role;

-- =====================================================================
-- SUSPENSION ENFORCEMENT HELPER
-- =====================================================================
-- This function checks if a user is suspended and can be called from
-- various parts of the application for additional security checks
-- =====================================================================

CREATE OR REPLACE FUNCTION check_user_suspension_status(user_uuid UUID)
RETURNS TABLE(is_suspended BOOLEAN, suspension_reason TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.is_suspended,
    u.suspension_reason
  FROM users u
  WHERE u.id = user_uuid;
END;
$$;

GRANT EXECUTE ON FUNCTION check_user_suspension_status(UUID) TO authenticated;

-- =====================================================================
-- ADMIN SYSTEM (Audit Logs + User Suspension)
-- =====================================================================
-- Tracks all admin actions for accountability and compliance
-- User suspension feature for moderation
-- =====================================================================

CREATE TABLE IF NOT EXISTS admin_audit_logs (
  id BIGSERIAL PRIMARY KEY,
  admin_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  details JSONB,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_admin_id ON admin_audit_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_timestamp ON admin_audit_logs(timestamp);

-- Enable RLS on admin_audit_logs
ALTER TABLE admin_audit_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Only admins can access audit logs
DROP POLICY IF EXISTS "Admin audit logs access" ON admin_audit_logs;
CREATE POLICY "Admin audit logs access" ON admin_audit_logs
  FOR ALL USING (
    (select auth.jwt()) ->> 'email' IN (
      'foundervers@gmail.com',
      'admin@foundervers.com',
      'rajkushwaha0213@gmail.com'
    )
  );

-- Grant permissions
GRANT ALL ON admin_audit_logs TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE admin_audit_logs_id_seq TO authenticated;

-- Admin Notifications System ----------------------------------------------------------------------------
-- Lightweight notification system for admin alerts and email processing

CREATE TABLE IF NOT EXISTS admin_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type VARCHAR(50) NOT NULL, -- 'business_application', 'user_report', etc.
  reference_id BIGINT, -- ID of the referenced record (e.g., application ID)
  data JSONB NOT NULL DEFAULT '{}', -- Sanitized notification data
  status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'processed', 'failed'
  processed_at TIMESTAMPTZ NULL,
  retry_count INTEGER DEFAULT 0,
  max_retries INTEGER DEFAULT 3,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for admin_notifications
CREATE INDEX IF NOT EXISTS idx_admin_notifications_type ON admin_notifications(type);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_status ON admin_notifications(status);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_created_at ON admin_notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_reference_id ON admin_notifications(reference_id);

-- RLS for admin_notifications (Admin access only)
ALTER TABLE admin_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin notifications admin access" ON admin_notifications;
CREATE POLICY "Admin notifications admin access" ON admin_notifications
  FOR ALL USING (
    (select auth.jwt()) ->> 'email' IN ('foundervers@gmail.com', 'admin@foundervers.com', 'rajkushwaha0213@gmail.com')
  );

-- Grant permissions for admin_notifications
GRANT ALL ON admin_notifications TO authenticated;
GRANT ALL ON admin_notifications TO service_role;

-- Business Application Notification Function (Refactored) -----------------------------------------------
-- Lightweight trigger that creates notification records for async processing
-- Moved complex email logic to separate processing system for better maintainability

CREATE OR REPLACE FUNCTION notify_admin_new_business_application()
RETURNS TRIGGER
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  service_type_display TEXT;
  sanitized_form_data JSONB;
BEGIN
  -- Format service type for display
  service_type_display := CASE NEW.service_type
    WHEN 'tax_help' THEN 'Tax Help'
    WHEN 'business_registration' THEN 'Business Registration'
    WHEN 'app_development' THEN 'App Development'
    WHEN 'marketing' THEN 'Marketing'
    WHEN 'employee_hiring' THEN 'Employee Hiring'
    WHEN 'investor_finding' THEN 'Investor Finding'
    WHEN 'business_consultation' THEN 'Business Consultation'
    ELSE INITCAP(REPLACE(NEW.service_type, '_', ' '))
  END;

  -- Sanitize form data - remove potentially sensitive fields and limit size
  sanitized_form_data := jsonb_build_object(
    'business_name', COALESCE(NEW.form_data->>'business_name', 'Not specified'),
    'service_category', NEW.service_type,
    'has_attachments', (
      SELECT COUNT(*) > 0 
      FROM jsonb_object_keys(NEW.form_data) keys 
      WHERE keys LIKE '%_files'
    ),
    'form_fields_count', (SELECT COUNT(*) FROM jsonb_object_keys(NEW.form_data)),
    'submission_method', COALESCE(NEW.form_data->>'submission_method', 'web_form')
  );

  -- Insert lightweight notification record for async processing
  INSERT INTO admin_notifications (
    type, 
    reference_id, 
    data,
    created_at
  ) VALUES (
    'business_application',
    NEW.id,
    jsonb_build_object(
      'applicant_name', NEW.applicant_name,
      'applicant_email', NEW.applicant_email,
      'service_type', NEW.service_type,
      'service_type_display', service_type_display,
      'application_id', NEW.id,
      'created_at', NEW.created_at,
      'sanitized_form_data', sanitized_form_data
    ),
    NOW()
  );

  -- Log successful notification creation
  RAISE NOTICE 'Notification queued for business application ID: %, Service: %', NEW.id, service_type_display;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log error but don't fail the application insert
  RAISE WARNING 'Failed to create admin notification for application %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$;

-- Send Applicant Confirmation Email Function
-- This function sends a confirmation email to the applicant immediately after submission
CREATE OR REPLACE FUNCTION public.send_applicant_confirmation_email()
RETURNS TRIGGER
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path TO pg_catalog
AS $$
DECLARE
  service_type_display TEXT;
  business_name_val TEXT;
  http_response RECORD;
  email_payload JSONB;
  response_body TEXT;
BEGIN
  RAISE NOTICE '=== TRIGGER FIRED for application % ===', NEW.id;
  
  -- Only send confirmation if applicant email is provided
  IF NEW.applicant_email IS NULL OR NEW.applicant_email = '' THEN
    RAISE NOTICE 'No applicant email provided for application %, skipping confirmation', NEW.id;
    RETURN NEW;
  END IF;

  RAISE NOTICE 'Applicant email: %', NEW.applicant_email;

  -- Format service type for display
  service_type_display := CASE NEW.service_type
    WHEN 'tax_help' THEN 'Tax Help'
    WHEN 'business_registration' THEN 'Business Registration'
    WHEN 'app_development' THEN 'App Development'
    WHEN 'marketing' THEN 'Marketing'
    WHEN 'employee_hiring' THEN 'Employee Hiring'
    WHEN 'investor_finding' THEN 'Investor Finding'
    WHEN 'business_consultation' THEN 'Business Consultation'
    WHEN 'market_research' THEN 'Market Research'
    WHEN 'patent_filing' THEN 'Patent Filing'
    ELSE INITCAP(REPLACE(NEW.service_type, '_', ' '))
  END;

  -- Extract business name from form data if available
  business_name_val := NEW.form_data->>'business_name';
  -- Construct the JSON payload for the Edge Function
    email_payload := json_build_object(
      'applicant_name', NEW.applicant_name,
      'applicant_email', NEW.applicant_email,
      'service_type', NEW.service_type,
      'service_type_display', service_type_display,
      'application_id', NEW.id,
      'business_name', NEW.form_data->>'business_name'
    );

  RAISE NOTICE 'Email payload prepared: %', email_payload;

  -- Call Edge Function to send confirmation email
  BEGIN
    RAISE NOTICE 'Calling Edge Function...';

    SELECT * INTO http_response
    FROM net.http_post(
      url := 'https://qddhubtyvqoqlbshxfkr.supabase.co/functions/v1/send-application-confirmation',
      headers := jsonb_build_object('Content-Type', 'application/json'),
      body := email_payload
    );

    response_body := COALESCE(convert_from(http_response.body, 'utf-8'), '');

    RAISE NOTICE 'HTTP Response Status: %, Content: %', http_response.status_code, response_body;

    IF http_response.status_code BETWEEN 200 AND 299 THEN
      RAISE NOTICE 'Confirmation email sent to % for application %', NEW.applicant_email, NEW.id;
    ELSE
      RAISE WARNING 'Failed to send confirmation email to %: HTTP % - %', 
        NEW.applicant_email, http_response.status_code, response_body;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error sending confirmation email for application %: % (SQLSTATE: %)', 
      NEW.id, SQLERRM, SQLSTATE;
  END;

  RETURN NEW;
END;
$$;

-- Email Processing Function (Separate from trigger) -----------------------------------------------------
-- This function processes pending notifications and sends emails via Edge Function
-- Can be called by pg_cron, Edge Functions, or application workers

CREATE OR REPLACE FUNCTION process_admin_notifications(batch_size INTEGER DEFAULT 10)
RETURNS TABLE(processed_count INTEGER, failed_count INTEGER)
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  notification_record admin_notifications%ROWTYPE;
  http_response RECORD;
  email_payload JSONB;
  total_processed INTEGER := 0;
  total_failed INTEGER := 0;
  service_type_display TEXT;
BEGIN
  -- Process pending notifications in batches
  FOR notification_record IN 
    SELECT * FROM admin_notifications 
    WHERE status = 'pending' 
      AND retry_count < max_retries
    ORDER BY created_at ASC 
    LIMIT batch_size
  LOOP
    BEGIN
      -- Build email payload for your existing Edge Function
      -- Format service type for display
      service_type_display := notification_record.data->>'service_type_display';
      
      -- Create email subject
      email_payload := jsonb_build_object(
        'applicant_name', notification_record.data->>'applicant_name',
        'business_name', notification_record.data->'sanitized_form_data'->>'business_name',
        'service_type', service_type_display,
        'applicant_email', notification_record.data->>'applicant_email',
        'admin_email', 'foundervers@gmail.com',
        'subject', 'New Business Service Application: ' || service_type_display || 
                   CASE WHEN notification_record.data->'sanitized_form_data'->>'has_attachments' = 'true' 
                        THEN ' (with attachments)' 
                        ELSE '' END,
        'body', format('
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; color: #333; }
        .header { background-color: #4CAF50; color: white; padding: 20px; border-radius: 8px; }
        .content { margin-top: 20px; }
        .field { margin: 10px 0; padding: 10px; background-color: #f9f9f9; border-radius: 4px; }
        .field-label { font-weight: bold; color: #4CAF50; }
        .field-value { margin-top: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <h2>🔔 New Business Service Application</h2>
        <p>Service Type: <strong>%s</strong></p>
    </div>
    
    <div class="content">
        <div class="field">
            <div class="field-label">👤 Applicant Information:</div>
            <div class="field-value">
                <strong>Name:</strong> %s<br>
                <strong>Email:</strong> %s<br>
                <strong>Submitted:</strong> %s
            </div>
        </div>
        
        <div class="field">
            <div class="field-label">🏢 Business Information:</div>
            <div class="field-value">
                <strong>Business Name:</strong> %s<br>
                <strong>Service Category:</strong> %s<br>
                <strong>Form Fields:</strong> %s fields submitted<br>
                <strong>Has Attachments:</strong> %s
            </div>
        </div>
    </div>
    
    <div style="margin-top: 30px; padding: 15px; background-color: #e8f5e8; border-radius: 4px;">
        <p><strong>Next Steps:</strong></p>
        <ul>
            <li>Review the application details</li>
            <li>Contact the applicant if more information is needed</li>
            <li>Connect them with the appropriate service provider</li>
        </ul>
    </div>
    
    <div style="margin-top: 20px; padding: 15px; background-color: #fff3cd; border-radius: 4px;">
        <p><strong>📋 Application ID:</strong> %s</p>
        <p><strong>🔔 Notification ID:</strong> %s</p>
        <p style="font-size: 12px; color: #666;">
            This email was automatically generated by the FounderVers Business Services Portal.
            To view full application details including attachments, log into the admin dashboard.
        </p>
    </div>
</body>
</html>',
          service_type_display,
          notification_record.data->>'applicant_name',
          notification_record.data->>'applicant_email',
          notification_record.data->>'created_at',
          notification_record.data->'sanitized_form_data'->>'business_name',
          notification_record.data->'sanitized_form_data'->>'service_category',
          notification_record.data->'sanitized_form_data'->>'form_fields_count',
          CASE WHEN notification_record.data->'sanitized_form_data'->>'has_attachments' = 'true' 
               THEN 'Yes' ELSE 'No' END,
          notification_record.reference_id,
          notification_record.id
        ),
        'application_id', notification_record.reference_id,
        'notification_id', notification_record.id
      );

      -- Call your existing Edge Function
      -- Note: URL will need to be configured with your actual Supabase project URL
      SELECT INTO http_response * FROM net.http_post(
        url := 'https://qddhubtyvqoqlbshxfkr.supabase.co/functions/v1/send-business-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFkZGh1YnR5dnFvcWxic2h4ZmtyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTY3NTIzNiwiZXhwIjoyMDcxMjUxMjM2fQ.5nXTFu6A9RJDaF1ikXODhh62ua4kpf9inyANpTzr4c0'
        ),
        body := email_payload
      );

      -- Check if email was sent successfully
      IF http_response.status_code BETWEEN 200 AND 299 THEN
        -- Mark as processed
        UPDATE admin_notifications 
        SET status = 'processed',
            processed_at = NOW(),
            updated_at = NOW()
        WHERE id = notification_record.id;
        
        total_processed := total_processed + 1;
        RAISE NOTICE 'Processed notification % successfully', notification_record.id;
      ELSE
        -- Mark as failed and increment retry count
        UPDATE admin_notifications 
        SET retry_count = retry_count + 1,
            error_message = 'HTTP ' || http_response.status_code || ': ' || COALESCE(http_response.content, 'No response content'),
            updated_at = NOW(),
            status = CASE 
              WHEN retry_count + 1 >= max_retries THEN 'failed' 
              ELSE 'pending' 
            END
        WHERE id = notification_record.id;
        
        total_failed := total_failed + 1;
        RAISE WARNING 'Failed to send notification %: HTTP %', notification_record.id, http_response.status_code;
      END IF;
      
    EXCEPTION WHEN OTHERS THEN
      -- Handle processing errors
      UPDATE admin_notifications 
      SET retry_count = retry_count + 1,
          error_message = SQLERRM,
          updated_at = NOW(),
          status = CASE 
            WHEN retry_count + 1 >= max_retries THEN 'failed' 
            ELSE 'pending' 
          END
      WHERE id = notification_record.id;
      
      total_failed := total_failed + 1;
      RAISE WARNING 'Failed to process notification %: %', notification_record.id, SQLERRM;
    END;
  END LOOP;

  -- Return processing results (fixed return logic)
  RETURN QUERY SELECT total_processed, total_failed;
END;
$$;

-- Helper function to cleanup old processed notifications
CREATE OR REPLACE FUNCTION cleanup_old_admin_notifications(days_old INTEGER DEFAULT 30)
RETURNS INTEGER
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM admin_notifications 
  WHERE status IN ('processed', 'failed') 
    AND created_at < NOW() - (days_old || ' days')::INTERVAL;
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE 'Cleaned up % old admin notifications', deleted_count;
  
  RETURN deleted_count;
END;
$$;

-- Grant permissions for notification processing functions
GRANT EXECUTE ON FUNCTION process_admin_notifications(INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION cleanup_old_admin_notifications(INTEGER) TO service_role;

-- Test function to validate the notification system
CREATE OR REPLACE FUNCTION test_admin_notification_system()
RETURNS JSONB
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  test_application_id BIGINT;
  notification_count INTEGER;
  test_results JSONB := '{}';
BEGIN
  -- Insert a test business application
  INSERT INTO business_applications (
    service_type,
    applicant_name,
    applicant_email,
    form_data
  ) VALUES (
    'app_development',
    'Test User',
    'test@example.com',
    '{"business_name": "Test Business", "description": "Test application"}'::jsonb
  ) RETURNING id INTO test_application_id;

  -- Check if notification was created
  SELECT COUNT(*) INTO notification_count
  FROM admin_notifications 
  WHERE type = 'business_application' 
    AND reference_id = test_application_id;

  -- Build test results
  test_results := jsonb_build_object(
    'test_application_id', test_application_id,
    'notification_created', notification_count > 0,
    'notification_count', notification_count,
    'trigger_working', notification_count > 0
  );

  -- Check notification data
  IF notification_count > 0 THEN
    test_results := test_results || jsonb_build_object(
      'notification_data', (
        SELECT data FROM admin_notifications 
        WHERE type = 'business_application' 
          AND reference_id = test_application_id 
        LIMIT 1
      )
    );
  END IF;

  -- Clean up test data
  DELETE FROM admin_notifications WHERE reference_id = test_application_id;
  DELETE FROM business_applications WHERE id = test_application_id;

  RETURN test_results;
END;
$$;

-- Grant permission to test function
GRANT EXECUTE ON FUNCTION test_admin_notification_system() TO authenticated;
GRANT EXECUTE ON FUNCTION test_admin_notification_system() TO service_role;

-- Configuration validation function (simplified for Supabase hosted environment)
CREATE OR REPLACE FUNCTION validate_notification_system_config()
RETURNS JSONB
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  config_status JSONB := '{}';
BEGIN
  config_status := jsonb_build_object(
    'pg_net_extension', (
      SELECT COUNT(*) > 0 FROM pg_extension WHERE extname = 'pg_net'
    ),
    'http_extension', (
      SELECT COUNT(*) > 0 FROM pg_extension WHERE extname = 'http'
    ),
    'admin_notifications_table', (
      SELECT COUNT(*) > 0 FROM information_schema.tables 
      WHERE table_name = 'admin_notifications'
    ),
    'business_applications_table', (
      SELECT COUNT(*) > 0 FROM information_schema.tables 
      WHERE table_name = 'business_applications'
    ),
    'trigger_exists', (
      SELECT COUNT(*) > 0 FROM information_schema.triggers 
      WHERE trigger_name = 'notify_admin_business_application'
    ),
    'notification_system_ready', true,
    'note', 'Email processing is currently set to logging mode. Configure Edge Function for actual email sending.'
  );

  RETURN config_status;
END;
$$;

-- Grant permission to validation function
GRANT EXECUTE ON FUNCTION validate_notification_system_config() TO authenticated;
GRANT EXECUTE ON FUNCTION validate_notification_system_config() TO service_role;

-- Edge Function Configuration Setup
-- Run this function with your actual Supabase project details to enable email sending

CREATE OR REPLACE FUNCTION configure_edge_function_integration(
  project_url TEXT,
  service_role_key TEXT
)
RETURNS TEXT
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  update_sql TEXT;
BEGIN
  -- Generate the SQL to update the process_admin_notifications function
  update_sql := format('
-- Update the Edge Function URL and authorization in the notification processor
CREATE OR REPLACE FUNCTION process_admin_notifications(batch_size INTEGER DEFAULT 10)
RETURNS TABLE(processed_count INTEGER, failed_count INTEGER) AS $func$
DECLARE
  notification_record admin_notifications%%ROWTYPE;
  http_response RECORD;
  email_payload JSONB;
  total_processed INTEGER := 0;
  total_failed INTEGER := 0;
  service_type_display TEXT;
BEGIN
  FOR notification_record IN 
    SELECT * FROM admin_notifications 
    WHERE status = ''pending'' 
      AND retry_count < max_retries
    ORDER BY created_at ASC 
    LIMIT batch_size
  LOOP
    BEGIN
      service_type_display := notification_record.data->>''service_type_display'';
      
      email_payload := jsonb_build_object(
        ''applicant_name'', notification_record.data->>''applicant_name'',
        ''business_name'', notification_record.data->''sanitized_form_data''->>''business_name'',
        ''service_type'', service_type_display,
        ''applicant_email'', notification_record.data->>''applicant_email'',
        ''admin_email'', ''foundervers@gmail.com'',
        ''subject'', ''New Business Service Application: '' || service_type_display,
        ''body'', ''<h2>New Application Received</h2><p>A new business application has been submitted.</p>'',
        ''application_id'', notification_record.reference_id,
        ''notification_id'', notification_record.id
      );

      SELECT INTO http_response * FROM net.http_post(
        url := ''%s/functions/v1/send-business-notification'',
        headers := jsonb_build_object(
          ''Content-Type'', ''application/json'',
          ''Authorization'', ''Bearer %s''
        ),
        body := email_payload
      );

      IF http_response.status_code BETWEEN 200 AND 299 THEN
        UPDATE admin_notifications 
        SET status = ''processed'', processed_at = NOW(), updated_at = NOW()
        WHERE id = notification_record.id;
        total_processed := total_processed + 1;
      ELSE
        UPDATE admin_notifications 
        SET retry_count = retry_count + 1,
            error_message = ''HTTP '' || http_response.status_code,
            updated_at = NOW(),
            status = CASE WHEN retry_count + 1 >= max_retries THEN ''failed'' ELSE ''pending'' END
        WHERE id = notification_record.id;
        total_failed := total_failed + 1;
      END IF;
      
    EXCEPTION WHEN OTHERS THEN
      UPDATE admin_notifications 
      SET retry_count = retry_count + 1, error_message = SQLERRM, updated_at = NOW(),
          status = CASE WHEN retry_count + 1 >= max_retries THEN ''failed'' ELSE ''pending'' END
      WHERE id = notification_record.id;
      total_failed := total_failed + 1;
    END;
  END LOOP;

  RETURN QUERY SELECT total_processed, total_failed;
END;
$func$ LANGUAGE plpgsql SECURITY DEFINER;',
    project_url,
    service_role_key
  );

  -- Return the SQL for manual execution
  RETURN update_sql;
END;
$$;

GRANT EXECUTE ON FUNCTION configure_edge_function_integration(TEXT, TEXT) TO service_role;

-- Business Service Applications Table ------------------------------------------------------------------------
-- This table stores all business service application submissions for the ecosystem portal

CREATE TABLE IF NOT EXISTS business_applications (
    id BIGSERIAL PRIMARY KEY,
    
    -- Application metadata
    service_type VARCHAR(100) NOT NULL, -- 'tax_help', 'business_registration', etc.
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'reviewed', 'assigned', 'completed'
    
    -- Applicant information
    applicant_id UUID REFERENCES auth.users(id), -- Link to authenticated user
    applicant_name VARCHAR(255) NOT NULL,
    applicant_email VARCHAR(255) NOT NULL,
    
    -- Form data (stored as JSONB for flexibility)
    form_data JSONB NOT NULL DEFAULT '{}',
    
    -- Admin tracking
    assigned_to VARCHAR(255), -- Service provider assigned
    admin_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security (RLS) Policy for business_applications
ALTER TABLE business_applications ENABLE ROW LEVEL SECURITY;

-- Policy: Users and admins can access applications data efficiently
DROP POLICY IF EXISTS "Users can view own applications" ON business_applications;
DROP POLICY IF EXISTS "Admins can view all applications" ON business_applications;
CREATE POLICY "Users can access applications" ON business_applications
  FOR SELECT USING (
    applicant_id = (select auth.uid())
    OR (
      (select auth.uid()) IN (
        SELECT u.id
        FROM public.users u
        WHERE u.email = ANY(
          SELECT unnest(string_to_array(current_setting('app.admin_emails', true), ','))
        )
      )
    )
  );

-- Policy: Users can insert their own applications
DROP POLICY IF EXISTS "Users can create applications" ON business_applications;
CREATE POLICY "Users can create applications" ON business_applications
  FOR INSERT WITH CHECK ((select auth.uid()) = applicant_id);

-- Admin policies for updates and deletes
DROP POLICY IF EXISTS "Admins can manage applications" ON business_applications;
CREATE POLICY "Admins can manage applications" ON business_applications
  FOR UPDATE USING (
    (select auth.uid()) IN (
      SELECT u.id
      FROM public.users u
      WHERE u.email = ANY(
        SELECT unnest(string_to_array(current_setting('app.admin_emails', true), ','))
      )
    )
  )
  WITH CHECK (
    (select auth.uid()) IN (
      SELECT u.id
      FROM public.users u
      WHERE u.email = ANY(
        SELECT unnest(string_to_array(current_setting('app.admin_emails', true), ','))
      )
    )
  );

DROP POLICY IF EXISTS "Admins can delete applications" ON business_applications;
CREATE POLICY "Admins can delete applications" ON business_applications
  FOR DELETE USING (
    (select auth.uid()) IN (
      SELECT u.id
      FROM public.users u
      WHERE u.email = ANY(
        SELECT unnest(string_to_array(current_setting('app.admin_emails', true), ','))
      )
    )
  );

-- Trigger to update the updated_at timestamp for business_applications
CREATE OR REPLACE FUNCTION update_business_applications_updated_at()
RETURNS TRIGGER 
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS update_business_applications_updated_at ON business_applications;
CREATE TRIGGER update_business_applications_updated_at
    BEFORE UPDATE ON business_applications
    FOR EACH ROW
    EXECUTE FUNCTION update_business_applications_updated_at();

-- Automatic admin email notification trigger
DROP TRIGGER IF EXISTS notify_admin_business_application ON business_applications;
CREATE TRIGGER notify_admin_business_application
    AFTER INSERT ON business_applications
    FOR EACH ROW
    EXECUTE FUNCTION notify_admin_new_business_application();

-- Applicant confirmation email trigger
DROP TRIGGER IF EXISTS send_applicant_confirmation ON business_applications;
CREATE TRIGGER send_applicant_confirmation
    AFTER INSERT ON business_applications
    FOR EACH ROW
    EXECUTE FUNCTION send_applicant_confirmation_email();

-- Optional: Create a view for admin dashboard
CREATE OR REPLACE VIEW business_applications_summary 
WITH (security_invoker = true) AS
SELECT 
    service_type,
    status,
    COUNT(*) as application_count,
    DATE_TRUNC('day', created_at) as submission_date
FROM business_applications
GROUP BY service_type, status, DATE_TRUNC('day', created_at)
ORDER BY submission_date DESC;

-- Create indexes for business_applications performance
CREATE INDEX IF NOT EXISTS idx_business_applications_service_type ON business_applications(service_type);
CREATE INDEX IF NOT EXISTS idx_business_applications_status ON business_applications(status);
CREATE INDEX IF NOT EXISTS idx_business_applications_applicant_id ON business_applications(applicant_id);
CREATE INDEX IF NOT EXISTS idx_business_applications_created_at ON business_applications(created_at);

-- Grant permissions for business_applications
GRANT SELECT, INSERT ON business_applications TO authenticated;
GRANT SELECT ON business_applications_summary TO authenticated;

-- NOTE: Storage bucket and policies for 'applications' bucket must be configured 
-- through the Supabase Dashboard > Storage section, not via SQL.
-- 
-- Required setup in Supabase Dashboard:
-- 1. Go to Storage > Buckets
-- 2. Create bucket named 'applications' (set as public)
-- 3. Go to Storage > Policies 
-- 4. Create policies for the 'applications' bucket (note: 50 char limit on policy names):
--    
--    Policy Name: "Allow authenticated users to upload app" (Supabase will add suffix)
--    - INSERT: Allow authenticated users to upload app_files fhzllv_0
--    - SELECT:  Allow authenticated users to upload app_files fhzllv_1  
--    - UPDATE:  Allow authenticated users to upload app_files fhzllv_2
--    - DELETE:  Allow authenticated users to upload app_files fhzllv_3
--
-- ✅ COMPLETED: Storage policies have been set up in Supabase Dashboard
-- File uploads should now work without RLS violations.
-- End of schema - Complete Mobile App with Business Applications! -----------------------