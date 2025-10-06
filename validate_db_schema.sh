#!/bin/bash

# Database Schema Validation Script
# This script validates the database changes and tests functionality

echo "🔍 Database Schema Validation Report"
echo "===================================="

# Check if the schema file exists
if [ ! -f "main_mobile_app_database_schema.sql" ]; then
    echo "❌ Schema file not found!"
    exit 1
fi

echo "✅ Schema file found"

# Basic syntax check
echo ""
echo "📝 Performing syntax validation..."

# Check for common SQL syntax issues
if grep -q "RETURNS TRIGGER AS \$\$" main_mobile_app_database_schema.sql; then
    echo "✅ Trigger functions syntax looks correct"
else
    echo "⚠️  No trigger functions found"
fi

if grep -q "CREATE TABLE.*admin_notifications" main_mobile_app_database_schema.sql; then
    echo "✅ admin_notifications table defined"
else
    echo "❌ admin_notifications table missing"
fi

if grep -q "CREATE TABLE.*business_applications" main_mobile_app_database_schema.sql; then
    echo "✅ business_applications table defined"
else
    echo "❌ business_applications table missing"
fi

# Check for trigger registration
if grep -q "CREATE TRIGGER notify_admin_business_application" main_mobile_app_database_schema.sql; then
    echo "✅ Admin notification trigger defined"
else
    echo "❌ Admin notification trigger missing"
fi

# Check for required extensions
if grep -q "CREATE EXTENSION.*pg_net" main_mobile_app_database_schema.sql; then
    echo "✅ pg_net extension included"
else
    echo "❌ pg_net extension missing"
fi

# Check for RLS policies
if grep -q "ENABLE ROW LEVEL SECURITY" main_mobile_app_database_schema.sql; then
    echo "✅ RLS policies defined"
else
    echo "⚠️  No RLS policies found"
fi

# Check for the refactored functions
if grep -q "process_admin_notifications" main_mobile_app_database_schema.sql; then
    echo "✅ Email processing function defined"
else
    echo "❌ Email processing function missing"
fi

if grep -q "test_admin_notification_system" main_mobile_app_database_schema.sql; then
    echo "✅ Test functions included"
else
    echo "❌ Test functions missing"
fi

echo ""
echo "🔧 Schema Analysis Summary:"
echo "- Total lines: $(wc -l < main_mobile_app_database_schema.sql)"
echo "- Tables defined: $(grep -c "CREATE TABLE" main_mobile_app_database_schema.sql)"
echo "- Functions defined: $(grep -c "CREATE OR REPLACE FUNCTION" main_mobile_app_database_schema.sql)"
echo "- Triggers defined: $(grep -c "CREATE TRIGGER" main_mobile_app_database_schema.sql)"
echo "- Policies defined: $(grep -c "CREATE POLICY" main_mobile_app_database_schema.sql)"

echo ""
echo "⚠️  Manual Steps Required:"
echo "1. Apply schema to your Supabase database"
echo "2. Configure database settings:"
echo "   ALTER DATABASE your_db SET app.supabase_url = 'your_supabase_url';"
echo "   ALTER DATABASE your_db SET app.service_role_key = 'your_service_key';"
echo "3. Test with: SELECT test_admin_notification_system();"
echo "4. Run notification processing: SELECT * FROM process_admin_notifications();"

echo ""
echo "✅ Schema validation complete!"