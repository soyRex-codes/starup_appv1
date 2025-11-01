-- =====================================================
-- BOOKMARKS FEATURE MIGRATION
-- Description: Simple bookmark/save posts feature
-- Date: 2025-10-25
-- =====================================================

-- Create bookmarks table
CREATE TABLE IF NOT EXISTS public.bookmarks (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  post_id BIGINT NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Prevent duplicate bookmarks
  UNIQUE(user_id, post_id)
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_bookmarks_user_id ON public.bookmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_post_id ON public.bookmarks(post_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_created_at ON public.bookmarks(created_at DESC);

-- Add composite index for common query patterns
CREATE INDEX IF NOT EXISTS idx_bookmarks_user_post ON public.bookmarks(user_id, post_id);

-- Enable Row Level Security
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Policy: Users can view their own bookmarks
CREATE POLICY "Users can view own bookmarks"
  ON public.bookmarks
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can create their own bookmarks
CREATE POLICY "Users can create own bookmarks"
  ON public.bookmarks
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own bookmarks
CREATE POLICY "Users can delete own bookmarks"
  ON public.bookmarks
  FOR DELETE
  USING (auth.uid() = user_id);

-- Grant necessary permissions
GRANT SELECT, INSERT, DELETE ON public.bookmarks TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE bookmarks_id_seq TO authenticated;

-- Add helpful comment
COMMENT ON TABLE public.bookmarks IS 'Stores user bookmarks/saved posts for later viewing';
