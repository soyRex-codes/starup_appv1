-- Add views column to posts table
-- This tracks how many times users have scrolled past/viewed each post

ALTER TABLE posts 
ADD COLUMN IF NOT EXISTS views INTEGER DEFAULT 0 NOT NULL;

-- Create index for faster view count queries (optional but recommended)
CREATE INDEX IF NOT EXISTS idx_posts_views ON posts(views DESC);

-- Add comment explaining the column
COMMENT ON COLUMN posts.views IS 'Count of how many times users have viewed this post (scroll-based tracking)';

-- Create RPC function to increment views in bulk
-- This function takes an array of post IDs and increments their views by 1
CREATE OR REPLACE FUNCTION increment_post_views(post_ids UUID[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE posts
  SET views = views + 1
  WHERE id = ANY(post_ids);
END;
$$;
