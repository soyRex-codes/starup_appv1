-- =====================================================================
-- PUSH NOTIFICATIONS SYSTEM
-- =====================================================================
-- This schema adds support for storing FCM tokens to enable push notifications.
-- It works in conjunction with the 'notifications' table (Unified Pipeline).
-- =====================================================================

-- User Devices Table --------------------------------------------------
-- Stores FCM tokens for each user's devices
CREATE TABLE IF NOT EXISTS user_devices (
  user_id UUID REFERENCES auth.users ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  platform TEXT, -- 'android', 'ios', 'web'
  app_version TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, fcm_token)
);

-- Indexes for Performance ---------------------------------------------
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON user_devices(user_id);

-- RLS Policies --------------------------------------------------------
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can manage their own devices" ON user_devices;

-- Users can insert, update, delete their own devices
CREATE POLICY "Users can manage their own devices"
  ON user_devices
  FOR ALL
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- Comments ------------------------------------------------------------
COMMENT ON TABLE user_devices IS 'Stores FCM tokens for user devices to enable push notifications';
