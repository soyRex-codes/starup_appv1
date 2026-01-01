#!/bin/bash

# Deploy Premium Subscription Edge Function
# This script deploys the create-premium-subscription Edge Function to Supabase

echo "🚀 Deploying Premium Subscription Edge Function..."
echo ""

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Please install it first:"
    echo "   npm install -g supabase"
    exit 1
fi

# Deploy the function
echo "📦 Deploying create-premium-subscription..."
supabase functions deploy create-premium-subscription --no-verify-jwt

if [ $? -eq 0 ]; then
    echo "✅ Premium subscription function deployed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Run migrations: supabase db push (or apply via Supabase Dashboard)"
    echo "2. Test the payment flow in the app"
    echo "3. Verify premium activation works correctly"
else
    echo "❌ Deployment failed. Check the error above."
    exit 1
fi
