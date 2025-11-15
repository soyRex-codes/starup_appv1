# 🚀 Edge Function Integration Guide

Your existing `send-business-notification` Edge Function is excellent! Now let's integrate it with the database notification system.

## 📋 Step 1: Apply the Updated Schema

Copy and paste the updated `main_mobile_app_database_schema.sql` into your Supabase SQL Editor and run it.

## 🔧 Step 2: Configure Edge Function Integration

In your Supabase SQL Editor, run this command with your actual project details:

```sql
SELECT configure_edge_function_integration(
  'https://your-project-ref.supabase.co',
  'your-service-role-key-here'
);
```

This will return SQL code. **Copy that SQL code and run it** to update the notification processor.

## 🧪 Step 3: Test the Complete System

### Test notification creation:
```sql
SELECT test_admin_notification_system();
```

### Process pending notifications (this will call your Edge Function):
```sql
SELECT * FROM process_admin_notifications(1);
```

### Check results:
```sql
-- View processed notifications
SELECT id, type, status, processed_at, error_message 
FROM admin_notifications 
ORDER BY created_at DESC 
LIMIT 5;
```

## 📧 Step 4: Monitor Your Edge Function

1. Go to **Supabase Dashboard > Edge Functions**
2. Click on **send-business-notification**
3. Check the **Logs** tab to see email processing

## 🔄 Step 5: Set Up Automated Processing (Optional)

Create a scheduled function to process notifications automatically:

```sql
-- This would need to be set up via pg_cron or external scheduler
SELECT cron.schedule(
  'process-admin-notifications',
  '*/5 * * * *',  -- Every 5 minutes
  'SELECT process_admin_notifications(10);'
);
```

## 📊 Step 6: Admin Dashboard Queries

### View all pending notifications:
```sql
SELECT 
  id,
  type,
  reference_id,
  data->>'applicant_name' as applicant,
  data->>'service_type_display' as service,
  created_at,
  retry_count
FROM admin_notifications 
WHERE status = 'pending'
ORDER BY created_at DESC;
```

### View processing statistics:
```sql
SELECT 
  status,
  COUNT(*) as count,
  AVG(retry_count) as avg_retries
FROM admin_notifications 
GROUP BY status;
```

## 🎯 What Happens Now

1. **User submits business application** → Trigger creates notification in `admin_notifications`
2. **Notification processor runs** → Calls your `send-business-notification` Edge Function
3. **Edge Function processes** → Sends email via your configured SMTP
4. **Database updates** → Marks notification as processed/failed
5. **Admin gets email** → With all application details

## 🔧 Your Edge Function Receives

Your existing Edge Function will receive this payload:
```json
{
  "applicant_name": "John Doe",
  "business_name": "Example Business",
  "service_type": "App Development", 
  "applicant_email": "john@example.com",
  "admin_email": "foundervers@gmail.com",
  "subject": "New Business Service Application: App Development",
  "body": "<html>...</html>",
  "application_id": 123,
  "notification_id": "uuid-here"
}
```

## ✅ Integration Benefits

- ✅ **Reliable**: Database triggers never fail due to email issues
- ✅ **Scalable**: Batch processing with retry logic
- ✅ **Secure**: Sanitized data prevents PII exposure
- ✅ **Monitorable**: Full audit trail of all notifications
- ✅ **Maintainable**: Easy to modify email templates in Edge Function

Your existing Edge Function doesn't need any changes - it's already perfect for this integration! 🎉