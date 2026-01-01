#!/bin/bash

# ================================================
# Foundervers Structured Comments - Quick Setup
# ================================================
# This script guides you through deploying the
# Structured Comments feature to your Foundervers app
# ================================================

echo "🚀 Foundervers Structured Comments - Setup Script"
echo "=================================================="
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ] || [ ! -f "comments_schema.sql" ]; then
    echo "❌ Error: Please run this script from the Foundervers project root"
    exit 1
fi

echo "✅ Project structure verified"
echo ""

# Step 1: Database Setup
echo "📊 Step 1: Database Setup"
echo "-------------------------"
echo "⚠️  MANUAL STEP REQUIRED:"
echo ""
echo "1. Open your Supabase Dashboard: https://supabase.com/dashboard"
echo "2. Navigate to: SQL Editor"
echo "3. Copy the contents of: comments_schema.sql"
echo "4. Paste and execute in the SQL Editor"
echo ""
read -p "Have you completed the database setup? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Please complete the database setup first"
    exit 1
fi
echo "✅ Database setup confirmed"
echo ""

# Step 2: Verify Dependencies
echo "📦 Step 2: Verify Dependencies"
echo "-------------------------"
echo "Checking Flutter dependencies..."

if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

echo "Running: flutter pub get"
flutter pub get

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed"
else
    echo "❌ Failed to install dependencies"
    exit 1
fi
echo ""

# Step 3: Verify Files
echo "📁 Step 3: Verify Created Files"
echo "-------------------------"

FILES=(
    "comments_schema.sql"
    "lib/models/comment.dart"
    "lib/services/comment_service.dart"
    "lib/widgets/comments/comment_card.dart"
    "lib/widgets/comments/category_selector.dart"
    "lib/widgets/comments/comment_input.dart"
    "lib/widgets/comments/comment_thread.dart"
    "lib/widgets/comments/comment_sheet.dart"
    "STRUCTURED_COMMENTS_FEATURE.md"
)

MISSING_FILES=0
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ Missing: $file"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

if [ $MISSING_FILES -gt 0 ]; then
    echo ""
    echo "❌ $MISSING_FILES file(s) missing. Please ensure all files are created."
    exit 1
fi
echo ""

# Step 4: Run Flutter Analyze
echo "🔍 Step 4: Code Analysis"
echo "-------------------------"
echo "Running: flutter analyze"
flutter analyze lib/models/comment.dart lib/services/comment_service.dart lib/widgets/comments/

if [ $? -eq 0 ]; then
    echo "✅ Code analysis passed"
else
    echo "⚠️  Code analysis found issues (these may be warnings)"
fi
echo ""

# Step 5: Final Instructions
echo "🎉 Setup Complete!"
echo "=========================="
echo ""
echo "Next Steps:"
echo "1. Run your app: flutter run"
echo "2. Open any post in the feed"
echo "3. Tap the purple 'Comment' button"
echo "4. Test creating comments with different categories"
echo "5. Test replying to comments"
echo ""
echo "📖 For detailed documentation, see:"
echo "   STRUCTURED_COMMENTS_FEATURE.md"
echo ""
echo "🐛 Troubleshooting:"
echo "   - Comments not loading? Check Supabase RLS policies"
echo "   - Can't post? Ensure user is authenticated"
echo "   - Real-time not working? Verify Realtime is enabled in Supabase"
echo ""
echo "✨ Happy commenting!"
