-- Enable pg_cron extension for scheduling jobs
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;

-- Schedule the cleanup job to run every night at 3 AM
-- This calls the existing cleanup_old_notifications() function
SELECT cron.schedule(
  'cleanup-old-notifications', -- Job name
  '0 3 * * *',                -- Cron schedule (3:00 AM daily)
  $$SELECT cleanup_old_notifications()$$
);

-- Schedule the admin notification cleanup job to run every night at 3:30 AM
-- This calls the existing cleanup_old_admin_notifications() function
SELECT cron.schedule(
  'cleanup-old-admin-notifications', -- Job name
  '30 3 * * *',                     -- Cron schedule (3:30 AM daily)
  $$SELECT cleanup_old_admin_notifications()$$
);

-- Grant usage to postgres user (required for pg_cron)
GRANT USAGE ON SCHEMA cron TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA cron TO postgres;
