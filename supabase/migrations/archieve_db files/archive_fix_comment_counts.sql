-- Fix stale comment counts in posts table
-- This recalculates the comment_count for every post based on the actual number of non-deleted comments

UPDATE posts p
SET comment_count = (
  SELECT COUNT(*)
  FROM comments c
  WHERE c.post_id = p.id
  AND c.deleted_at IS NULL
);
