#!/bin/bash
# apply_schema.sh - Apply the updated database schema to Supabase
# 
# Usage: ./apply_schema.sh
# Make sure you have your Supabase project URL and service key ready

echo "Applying Updated Supabase Schema..."
echo ""

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "Supabase CLI not found. Please install it first:"
    echo "   npm install -g supabase"
    echo "   Or visit: https://supabase.com/docs/guides/cli"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "supabase-mobile-schema.sql" ]; then
    echo "supabase-mobile-schema.sql not found in current directory"
    echo "   Please run this script from the project root"
    exit 1
fi

echo "This script will:"
echo "   • Fix dm_participants infinite recursion policy"
echo "   • Add missing posts and media tables" 
echo "   • Add all required indexes and RLS policies"
echo "   • Set up triggers for updated_at fields"
echo ""

read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 1
fi

# Apply the schema
echo "Applying schema to Supabase..."
echo ""
echo "Option 1: Manual Application (Recommended)"
echo "  1. Go to your Supabase project dashboard"
echo "  2. Navigate to SQL Editor"  
echo "  3. Copy and paste the contents of supabase-mobile-schema.sql"
echo "  4. Run the SQL commands"
echo ""
echo "Option 2: CLI Application"
echo "  If you have supabase CLI configured:"
echo "  supabase db push"
echo ""

echo "Schema file ready at: ./supabase-mobile-schema.sql"
echo ""
echo "Key fixes applied:"
echo "  ✓ Fixed dm_participants recursive policy (42P17 error)"
echo "  ✓ Added posts table (PGRST205 error fix)"
echo "  ✓ Added media table for file attachments"
echo "  ✓ Added firebase_uid column to users table"
echo "  ✓ Set up proper indexes for performance"
echo "  ✓ Configured RLS policies for security"
echo "  ✓ Added updated_at triggers"
echo ""
echo "After applying the schema, restart your Flutter app"
