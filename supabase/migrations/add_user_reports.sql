-- User Reports Table
-- Stores user reports of offensive/inappropriate users
CREATE TABLE IF NOT EXISTS user_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reported_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL, -- 'spam', 'harassment', 'inappropriate', 'misleading', 'hate_speech', 'violence', 'other'
  description TEXT, -- Optional additional details from reporter
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'reviewed', 'resolved', 'dismissed'
  reviewed_by UUID REFERENCES users(id), -- Admin who reviewed it
  reviewed_at TIMESTAMP WITH TIME ZONE,
  admin_notes TEXT, -- Admin's notes/decision
  action_taken TEXT, -- 'user_banned', 'user_warned', 'no_action', null
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  
  -- Prevent duplicate reports from same user for same reported user (optional, but good practice to prevent spamming)
  -- However, a user might report another user for multiple different incidents over time.
  -- Let's allow multiple reports but maybe rate limit in app logic. 
  -- For now, we won't enforce unique constraint on (reported_user_id, reporter_id) to allow reporting different incidents.
  -- But to prevent accidental double submission, maybe a short time window check or unique constraint is good.
  -- Let's stick to allowing it for now as incidents can be distinct.
  CONSTRAINT user_reports_reporter_reported_check CHECK (reporter_id != reported_user_id)
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_user_reports_reported_user_id ON user_reports(reported_user_id);
CREATE INDEX IF NOT EXISTS idx_user_reports_reporter_id ON user_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_user_reports_status ON user_reports(status);
CREATE INDEX IF NOT EXISTS idx_user_reports_created_at ON user_reports(created_at DESC);

-- RLS Policies for user_reports
ALTER TABLE user_reports ENABLE ROW LEVEL SECURITY;

-- Users can create reports
CREATE POLICY "Users can create reports"
  ON user_reports FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = reporter_id);

-- Users can view their own reports
CREATE POLICY "Users can view their own reports"
  ON user_reports FOR SELECT
  TO authenticated
  USING (auth.uid() = reporter_id);

-- Admins can view all reports
CREATE POLICY "Admins can view all reports"
  ON user_reports FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.is_admin = true
    )
  );

-- Admins can update reports (to resolve them)
CREATE POLICY "Admins can update reports"
  ON user_reports FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.is_admin = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.is_admin = true
    )
  );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_user_reports_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER update_user_reports_timestamp
  BEFORE UPDATE ON user_reports
  FOR EACH ROW
  EXECUTE FUNCTION update_user_reports_updated_at();
