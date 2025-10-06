#!/bin/bash

# Supabase Database Migration Script
# Run this to migrate from Firebase Auth to Supabase Auth only
# 
# Usage: 
# 1. Update the CONNECTION_STRING below with your Supabase database URL
# 2. Run: chmod +x migrate_db.sh
# 3. Run: ./migrate_db.sh

# TODO: Replace with your actual Supabase database connection string
# Find this in your Supabase Dashboard > Settings > Database > Connection string
CONNECTION_STRING="postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-REF].supabase.co:5432/postgres"

echo "🚀 Starting migration from Firebase Auth to Supabase Auth only..."

# Check if psql is installed
if ! command -v psql &> /dev/null; then
    echo "❌ Error: psql is not installed. Please install PostgreSQL client tools."
    echo "   On macOS: brew install postgresql"
    echo "   Or use the Supabase Dashboard SQL Editor instead."
    exit 1
fi

# Backup reminder
echo "⚠️  IMPORTANT: Make sure you have backed up your database before proceeding!"
read -p "Have you backed up your database? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please backup your database first, then run this script again."
    exit 1
fi

# Run the migration
echo "🔄 Running migration..."
psql "$CONNECTION_STRING" -f migrate_to_supabase_auth.sql

if [ $? -eq 0 ]; then
    echo "✅ Migration completed successfully!"
    echo "🔍 Running verification queries..."
    
    # Verification
    psql "$CONNECTION_STRING" -c "SELECT 'users' as table_name, count(*) as count FROM users;"
    psql "$CONNECTION_STRING" -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'users';"
    psql "$CONNECTION_STRING" -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'posts' AND column_name = 'user_id';"
    
    echo "🎉 Migration complete! Your app should now work with Supabase Auth only."
else
    echo "❌ Migration failed. Please check the error messages above."
    echo "   You can also try running the migration manually via Supabase Dashboard."
    exit 1
fi
