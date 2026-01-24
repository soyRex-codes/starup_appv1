#!/bin/bash

# Deploy Stripe Edge Functions
# This script deploys both payment-related Edge Functions to Supabase

echo "Deploying Stripe Edge Functions..."

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "Supabase CLI not found. Installing..."
    brew install supabase/tap/supabase
fi

# Deploy create-payment-intent function
echo "Deploying create-payment-intent..."
supabase functions deploy create-payment-intent --no-verify-jwt

# Deploy stripe-webhook function
echo "Deploying stripe-webhook..."
supabase functions deploy stripe-webhook --no-verify-jwt

echo "Deployment complete!"
echo ""
echo "Don't forget to set Supabase secrets:"
echo "   1. Go to Supabase Dashboard → Edge Functions → Secrets"
echo "   2. Add: stripe_secret_key = sk_test_..."
echo "   3. Add: stripe_webhook_secret = whsec_..."
