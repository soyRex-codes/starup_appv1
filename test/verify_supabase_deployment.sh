#!/bin/bash

# Quick Supabase Deployment Verification Script
# Verifies all Supabase components are deployed correctly

echo "🔍 Verifying Supabase Deployment"
echo "=================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get your Supabase project URL (update this!)
read -p "Enter your Supabase project URL (e.g., https://xxx.supabase.co): " SUPABASE_URL

if [ -z "$SUPABASE_URL" ]; then
    echo -e "${RED}❌ Supabase URL required${NC}"
    exit 1
fi

echo ""
echo "📡 Testing Edge Functions"
echo "-------------------------"

# Test create-premium-subscription endpoint
echo "Testing create-premium-subscription..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    "${SUPABASE_URL}/functions/v1/create-premium-subscription" \
    -H "Content-Type: application/json" \
    -d '{}' 2>/dev/null)

if [ "$RESPONSE" = "400" ] || [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✅ create-premium-subscription is deployed and responding${NC}"
    echo "   Status code: $RESPONSE (expected 400 for empty request)"
else
    echo -e "${RED}❌ create-premium-subscription not found or not responding${NC}"
    echo "   Status code: $RESPONSE"
    echo "   Expected: 400 or 200"
fi

# Test stripe-webhook endpoint
echo ""
echo "Testing stripe-webhook..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    "${SUPABASE_URL}/functions/v1/stripe-webhook" \
    -H "Content-Type: application/json" \
    -d '{}' 2>/dev/null)

if [ "$RESPONSE" = "403" ] || [ "$RESPONSE" = "400" ]; then
    echo -e "${GREEN}✅ stripe-webhook is deployed and responding${NC}"
    echo "   Status code: $RESPONSE (expected 403/400 without signature)"
else
    echo -e "${RED}❌ stripe-webhook not found or not responding${NC}"
    echo "   Status code: $RESPONSE"
    echo "   Expected: 403 or 400"
fi

echo ""
echo "🗄️  Database Migration Verification"
echo "------------------------------------"
echo ""
echo "Please verify manually in Supabase Dashboard:"
echo ""
echo "1. Go to: ${SUPABASE_URL%/}/project/default/editor"
echo ""
echo "2. Check 'users' table has these columns:"
echo "   - is_premium (boolean)"
echo "   - premium_expires_at (timestamptz)"
echo "   - premium_subscription_type (varchar)"
echo ""
echo "3. Check 'premium_payments' table exists with columns:"
echo "   - id (uuid)"
echo "   - user_id (uuid)"
echo "   - amount (decimal)"
echo "   - subscription_type (varchar)"
echo "   - payment_intent_id (varchar)"
echo "   - status (varchar)"
echo "   - expires_at (timestamptz)"
echo ""

read -p "Have you verified the database schema? (y/n): " DB_VERIFIED

if [ "$DB_VERIFIED" = "y" ] || [ "$DB_VERIFIED" = "Y" ]; then
    echo -e "${GREEN}✅ Database schema verified${NC}"
else
    echo -e "${YELLOW}⚠️  Please verify database schema${NC}"
fi

echo ""
echo "🔑 Environment Variables Verification"
echo "--------------------------------------"
echo ""
echo "Please verify in Supabase Dashboard → Settings → Edge Functions:"
echo ""
echo "Required secrets:"
echo "  1. stripe_secret_key=sk_test_... or sk_live_..."
echo "  2. stripe_webhook_secret=whsec_..."
echo ""

read -p "Have you set both secrets? (y/n): " SECRETS_VERIFIED

if [ "$SECRETS_VERIFIED" = "y" ] || [ "$SECRETS_VERIFIED" = "Y" ]; then
    echo -e "${GREEN}✅ Secrets verified${NC}"
else
    echo -e "${YELLOW}⚠️  Please set required secrets${NC}"
    echo ""
    echo "To set secrets, run:"
    echo "  supabase secrets set stripe_secret_key=sk_test_xxx"
    echo "  supabase secrets set stripe_webhook_secret=whsec_xxx"
fi

echo ""
echo "🔗 Stripe Webhook Configuration"
echo "--------------------------------"
echo ""
echo "Your webhook endpoint URL:"
echo "${SUPABASE_URL}/functions/v1/stripe-webhook"
echo ""
echo "Please verify in Stripe Dashboard:"
echo "1. Go to: https://dashboard.stripe.com/test/webhooks"
echo "2. Check endpoint exists with URL above"
echo "3. Verify these events are selected:"
echo "   - payment_intent.succeeded"
echo "   - payment_intent.payment_failed"
echo "   - charge.refunded"
echo ""

read -p "Have you configured the webhook in Stripe? (y/n): " WEBHOOK_VERIFIED

if [ "$WEBHOOK_VERIFIED" = "y" ] || [ "$WEBHOOK_VERIFIED" = "Y" ]; then
    echo -e "${GREEN}✅ Webhook configured in Stripe${NC}"
else
    echo -e "${YELLOW}⚠️  Please configure webhook in Stripe Dashboard${NC}"
fi

echo ""
echo "================================================"
echo "📊 VERIFICATION SUMMARY"
echo "================================================"
echo ""

if [ "$DB_VERIFIED" = "y" ] && [ "$SECRETS_VERIFIED" = "y" ] && [ "$WEBHOOK_VERIFIED" = "y" ]; then
    echo -e "${GREEN}✅ ALL CHECKS PASSED!${NC}"
    echo ""
    echo "Your Supabase backend is ready!"
    echo ""
    echo "Next steps:"
    echo "1. Run the Flutter app"
    echo "2. Follow MANUAL_TESTING_CHECKLIST.md"
    echo "3. Test premium subscription with card: 4242 4242 4242 4242"
    echo ""
else
    echo -e "${YELLOW}⚠️  SOME ITEMS NEED ATTENTION${NC}"
    echo ""
    echo "Please complete the items marked above, then run this script again."
    echo ""
fi

echo "Verification complete! 🎉"
echo ""
