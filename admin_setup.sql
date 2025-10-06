-- Admin system database setup for FounderVers
-- Run this in your Supabase SQL editor

-- Add admin columns to users table if they don't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_suspended BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS suspension_reason TEXT,
ADD COLUMN IF NOT EXISTS suspended_at TIMESTAMPTZ;

-- Create admin audit logs table
CREATE TABLE IF NOT EXISTS admin_audit_logs (
    id BIGSERIAL PRIMARY KEY,
    admin_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    details JSONB,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for efficient querying
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_admin_id ON admin_audit_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_timestamp ON admin_audit_logs(timestamp);

-- Enable RLS on admin_audit_logs
ALTER TABLE admin_audit_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Only admins can access audit logs
CREATE POLICY "Admin audit logs access" ON admin_audit_logs
FOR ALL USING (
    auth.jwt() ->> 'email' IN (
        'admin@foundervers.com',
        'rajkushwaha0213@gmail.com'
    )
);

-- Grant permissions
GRANT ALL ON admin_audit_logs TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE admin_audit_logs_id_seq TO authenticated;

-- Comment the tables
COMMENT ON TABLE admin_audit_logs IS 'Audit trail for admin actions';
COMMENT ON COLUMN admin_audit_logs.action IS 'Type of admin action performed';
COMMENT ON COLUMN admin_audit_logs.details IS 'JSON details about the action';