-- Create user_blocks table
CREATE TABLE IF NOT EXISTS user_blocks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blocker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(blocker_id, blocked_id)
);

-- Enable RLS
ALTER TABLE user_blocks ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Users can block others
CREATE POLICY "Users can block others" ON user_blocks
    FOR INSERT WITH CHECK (auth.uid() = blocker_id);

-- Users can unblock others
CREATE POLICY "Users can unblock others" ON user_blocks
    FOR DELETE USING (auth.uid() = blocker_id);

-- Users can view their own blocks
CREATE POLICY "Users can view their own blocks" ON user_blocks
    FOR SELECT USING (auth.uid() = blocker_id);

-- Create a helper function to check if a user is blocked (useful for other RLS policies)
CREATE OR REPLACE FUNCTION is_blocked_by(target_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_blocks
    WHERE blocker_id = target_user_id AND blocked_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a helper function to check if I have blocked a user
CREATE OR REPLACE FUNCTION has_blocked(target_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_blocks
    WHERE blocker_id = auth.uid() AND blocked_id = target_user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
