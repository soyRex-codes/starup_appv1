-- =====================================================================
-- FOUNDERVERS STRUCTURED COMMENTS SYSTEM
-- =====================================================================
-- This schema adds a sophisticated comments system with:
-- • Category-based comments (Question, Idea, Critique, Resource, General)
-- • Threaded replies (parent-child relationships)
-- • Real-time capabilities via Supabase subscriptions
-- • Proper RLS security policies
-- =====================================================================

-- Comments Table -------------------------------------------------------
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

-- Indexes for optimal query performance --------------------------------
CREATE INDEX IF NOT EXISTS idx_comments_post_id_created ON comments(post_id, created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_comments_author_id ON comments(author_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON comments(parent_comment_id) WHERE deleted_at IS NULL;

-- Row Level Security (RLS) ---------------------------------------------
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Anyone can view non-deleted comments
DROP POLICY IF EXISTS "comments_select" ON comments;
CREATE POLICY "comments_select" ON comments 
  FOR SELECT USING (deleted_at IS NULL);

-- Authenticated users can insert comments
DROP POLICY IF EXISTS "comments_insert" ON comments;
CREATE POLICY "comments_insert" ON comments 
  FOR INSERT WITH CHECK (auth.uid() = author_id AND deleted_at IS NULL);

-- Users can update/soft-delete their own comments
DROP POLICY IF EXISTS "comments_update" ON comments;
CREATE POLICY "comments_update" ON comments 
  FOR UPDATE USING (auth.uid() = author_id);

-- Helper Functions -----------------------------------------------------

-- Function to get comment count for a post
CREATE OR REPLACE FUNCTION get_comment_count(p_post_id BIGINT)
RETURNS INTEGER LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::INTEGER 
    FROM comments 
    WHERE post_id = p_post_id 
      AND deleted_at IS NULL
  );
END; $$;

-- Trigger to update 'updated_at' timestamp on comment edits
CREATE OR REPLACE FUNCTION update_comment_timestamp()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
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

-- Analytics View (Optional - for future insights) ---------------------
CREATE OR REPLACE VIEW comment_stats AS
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

-- =====================================================================
-- DEPLOYMENT INSTRUCTIONS:
-- 1. Run this SQL in your Supabase SQL Editor
-- 2. Verify tables are created: SELECT * FROM comments LIMIT 1;
-- 3. Test RLS: Try inserting/selecting as authenticated user
-- =====================================================================
