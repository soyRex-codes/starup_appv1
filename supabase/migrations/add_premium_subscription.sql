-- Add premium subscription fields to users table
-- This enables premium features like Business.AI, Global Chat, and golden badge

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_premium BOOLEAN DEFAULT FALSE NOT NULL,
ADD COLUMN IF NOT EXISTS premium_expires_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS premium_subscription_type VARCHAR(20); -- 'monthly' or 'annual'

-- Index for fast premium status checks
CREATE INDEX IF NOT EXISTS idx_users_premium ON users(is_premium) WHERE is_premium = true;

-- Add comments
COMMENT ON COLUMN users.is_premium IS 'Whether user has active premium subscription';
COMMENT ON COLUMN users.premium_expires_at IS 'When premium subscription expires (NULL = lifetime premium)';
COMMENT ON COLUMN users.premium_subscription_type IS 'Type of subscription: monthly or annual';

-- Function to check if premium is still valid (can be used in policies)
CREATE OR REPLACE FUNCTION check_premium_active(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users 
    WHERE id = user_id 
    AND is_premium = true 
    AND (premium_expires_at IS NULL OR premium_expires_at > NOW())
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
