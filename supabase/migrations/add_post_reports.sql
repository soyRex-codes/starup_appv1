-- Post Reports Table
-- Stores user reports of offensive/inappropriate posts
CREATE TABLE IF NOT EXISTS post_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL, -- 'spam', 'harassment', 'inappropriate', 'misleading', 'hate_speech', 'violence', 'other'
  description TEXT, -- Optional additional details from reporter
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'reviewed', 'resolved', 'dismissed'
  reviewed_by UUID REFERENCES users(id), -- Admin who reviewed it
  reviewed_at TIMESTAMP WITH TIME ZONE,
  admin_notes TEXT, -- Admin's notes/decision
  action_taken TEXT, -- 'post_removed', 'user_warned', 'user_suspended', 'no_action', null
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  
  -- Prevent duplicate reports from same user for same post
  UNIQUE(post_id, reporter_id)
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_post_reports_post_id ON post_reports(post_id);
CREATE INDEX IF NOT EXISTS idx_post_reports_reporter_id ON post_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_post_reports_status ON post_reports(status);
CREATE INDEX IF NOT EXISTS idx_post_reports_created_at ON post_reports(created_at DESC);

-- RLS Policies for post_reports
ALTER TABLE post_reports ENABLE ROW LEVEL SECURITY;

-- Users can create reports
CREATE POLICY "Users can create reports"
  ON post_reports FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = reporter_id);

-- Users can view their own reports
CREATE POLICY "Users can view their own reports"
  ON post_reports FOR SELECT
  TO authenticated
  USING (auth.uid() = reporter_id);

-- Admins can view all reports
CREATE POLICY "Admins can view all reports"
  ON post_reports FOR SELECT
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
  ON post_reports FOR UPDATE
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
CREATE OR REPLACE FUNCTION update_post_reports_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER update_post_reports_timestamp
  BEFORE UPDATE ON post_reports
  FOR EACH ROW
  EXECUTE FUNCTION update_post_reports_updated_at();

-- Add report_count to posts table (for tracking)
ALTER TABLE posts ADD COLUMN IF NOT EXISTS report_count INTEGER DEFAULT 0;

-- Function to increment report count when report is created
CREATE OR REPLACE FUNCTION increment_post_report_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE posts
  SET report_count = report_count + 1
  WHERE id = NEW.post_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-increment report count
CREATE TRIGGER increment_post_report_count_trigger
  AFTER INSERT ON post_reports
  FOR EACH ROW
  EXECUTE FUNCTION increment_post_report_count();
