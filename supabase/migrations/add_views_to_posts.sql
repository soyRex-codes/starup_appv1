-- Add views column to posts table
-- This tracks how many times users have scrolled past/viewed each post

ALTER TABLE posts 
ADD COLUMN IF NOT EXISTS views INTEGER DEFAULT 0 NOT NULL;

-- Create index for faster view count queries (optional but recommended)
CREATE INDEX IF NOT EXISTS idx_posts_views ON posts(views DESC);

-- Add comment explaining the column
COMMENT ON COLUMN posts.views IS 'Count of how many times users have viewed this post (scroll-based tracking)';
