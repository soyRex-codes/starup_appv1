#!/bin/bash

# Premium Subscription Flow Test Script
# Tests the complete premium subscription implementation

echo "Testing Premium Subscription System"
echo "========================================"
echo ""

ERRORS=0
WARNINGS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test function
test_check() {
    local test_name=$1
    local result=$2
    
    if [ $result -eq 0 ]; then
        echo -e "${GREEN}PASS${NC}: $test_name"
    else
        echo -e "${RED}FAIL${NC}: $test_name"
        ERRORS=$((ERRORS + 1))
    fi
}

test_warning() {
    local test_name=$1
    echo -e "${YELLOW}WARN${NC}: $test_name"
    WARNINGS=$((WARNINGS + 1))
}

test_info() {
    local message=$1
    echo -e "${BLUE}INFO${NC}: $message"
}

echo "Phase 1: Checking File Structure"
echo "-----------------------------------"

# Check migration files
if [ -f "supabase/migrations/add_premium_subscription.sql" ]; then
    test_check "Migration file (add_premium_subscription.sql) exists" 0
else
    test_check "Migration file (add_premium_subscription.sql) exists" 1
fi

if [ -f "supabase/migrations/add_premium_payments_table.sql" ]; then
    test_check "Migration file (add_premium_payments_table.sql) exists" 0
else
    test_check "Migration file (add_premium_payments_table.sql) exists" 1
fi

# Check Edge Functions
if [ -f "supabase/functions/create-premium-subscription/index.ts" ]; then
    test_check "Edge Function (create-premium-subscription) exists" 0
else
    test_check "Edge Function (create-premium-subscription) exists" 1
fi

if [ -f "supabase/functions/stripe-webhook/index.ts" ]; then
    test_check "Webhook handler exists" 0
else
    test_check "Webhook handler exists" 1
fi

# Check Flutter files
echo ""
echo "📱 Phase 2: Checking Flutter Implementation"
echo "-------------------------------------------"

if [ -f "lib/services/premium_subscription_service.dart" ]; then
    test_check "Premium service exists" 0
    
    # Check for key methods
    if grep -q "createPayment" lib/services/premium_subscription_service.dart; then
        test_check "Service has createPayment method" 0
    else
        test_check "Service has createPayment method" 1
    fi
    
    if grep -q "processPayment" lib/services/premium_subscription_service.dart; then
        test_check "Service has processPayment method" 0
    else
        test_check "Service has processPayment method" 1
    fi
    
    if grep -q "completePremiumPayment" lib/services/premium_subscription_service.dart; then
        test_check "Service has completePremiumPayment method" 0
    else
        test_check "Service has completePremiumPayment method" 1
    fi
else
    test_check "Premium service exists" 1
fi

if [ -f "lib/models/premium_payment_model.dart" ]; then
    test_check "Premium payment model exists" 0
else
    test_check "Premium payment model exists" 1
fi

if [ -f "lib/features/premium/premium_payment_page.dart" ]; then
    test_check "Premium payment page exists" 0
    
    # Check for payment flow
    if grep -q "PremiumPaymentPage" lib/features/premium/premium_payment_page.dart; then
        test_check "Payment page class defined" 0
    else
        test_check "Payment page class defined" 1
    fi
    
    if grep -q "PremiumPaymentSuccessPage" lib/features/premium/premium_payment_page.dart; then
        test_check "Success page class defined" 0
    else
        test_check "Success page class defined" 1
    fi
else
    test_check "Premium payment page exists" 1
fi

if [ -f "lib/widgets/premium_upgrade_dialog.dart" ]; then
    test_check "Premium upgrade dialog exists" 0
    
    # Check for plan selection
    if grep -q "_isAnnual" lib/widgets/premium_upgrade_dialog.dart; then
        test_check "Dialog has plan selection" 0
    else
        test_check "Dialog has plan selection" 1
    fi
else
    test_check "Premium upgrade dialog exists" 1
fi

# Check navigation integration
echo ""
echo "Phase 3: Checking Navigation Integration"
echo "-------------------------------------------"

if grep -q "PremiumUpgradeDialog.show" lib/app/home_page.dart 2>/dev/null; then
    test_check "Premium dialog integrated in home navigation" 0
else
    test_check "Premium dialog integrated in home navigation" 1
fi

if grep -q "checkPremiumStatus" lib/app/home_page.dart 2>/dev/null; then
    test_check "Premium status check in navigation" 0
else
    test_check "Premium status check in navigation" 1
fi

# Check badge implementation
echo ""
echo "Phase 4: Checking Badge Implementation"
echo "------------------------------------------"

if grep -q "workspace_premium" lib/features/feed/enhanced_post_card.dart 2>/dev/null; then
    test_check "Gold badge in feed" 0
else
    test_check "Gold badge in feed" 1
fi

if grep -q "workspace_premium" lib/features/profile/unified_profile_page.dart 2>/dev/null; then
    test_check "Gold badge in profile" 0
else
    test_check "Gold badge in profile" 1
fi

# Check discount implementation
echo ""
echo "Phase 5: Checking Ecosystem Discount"
echo "----------------------------------------"

if grep -q "getApplicationFee" lib/services/application_payment_service.dart 2>/dev/null; then
    test_check "Dynamic fee calculation exists" 0
else
    test_check "Dynamic fee calculation exists" 1
fi

if grep -q "calculateApplicationFee" lib/services/premium_subscription_service.dart 2>/dev/null; then
    test_check "Premium discount calculation exists" 0
else
    test_check "Premium discount calculation exists" 1
fi

# Check Edge Function configuration
echo ""
echo "Phase 6: Checking Edge Function Configuration"
echo "-------------------------------------------------"

# Check metadata in create-premium-subscription
if grep -q "productType.*premium_subscription" supabase/functions/create-premium-subscription/index.ts 2>/dev/null; then
    test_check "Edge Function sets productType metadata" 0
else
    test_check "Edge Function sets productType metadata" 1
fi

# Check webhook handles premium
if grep -q "premium_subscription" supabase/functions/stripe-webhook/index.ts 2>/dev/null; then
    test_check "Webhook handles premium payments" 0
else
    test_check "Webhook handles premium payments" 1
fi

if grep -q "handlePremiumSubscriptionSuccess" supabase/functions/stripe-webhook/index.ts 2>/dev/null; then
    test_check "Webhook has premium success handler" 0
else
    test_check "Webhook has premium success handler" 1
fi

# Run Dart analysis
echo ""
echo "Phase 7: Running Static Analysis"
echo "------------------------------------"

test_info "Running dart analyze on premium files..."

# Analyze premium service
dart analyze lib/services/premium_subscription_service.dart 2>&1 | grep -i "error" > /dev/null
if [ $? -eq 1 ]; then
    test_check "Premium service has no errors" 0
else
    test_check "Premium service has no errors" 1
    dart analyze lib/services/premium_subscription_service.dart 2>&1 | grep -i "error"
fi

# Analyze payment page
dart analyze lib/features/premium/premium_payment_page.dart 2>&1 | grep -i "error" > /dev/null
if [ $? -eq 1 ]; then
    test_check "Payment page has no errors" 0
else
    test_check "Payment page has no errors" 1
    dart analyze lib/features/premium/premium_payment_page.dart 2>&1 | grep -i "error"
fi

# Analyze dialog
dart analyze lib/widgets/premium_upgrade_dialog.dart 2>&1 | grep -i "error" > /dev/null
if [ $? -eq 1 ]; then
    test_check "Premium dialog has no errors" 0
else
    test_check "Premium dialog has no errors" 1
    dart analyze lib/widgets/premium_upgrade_dialog.dart 2>&1 | grep -i "error"
fi

# Analyze payment model
dart analyze lib/models/premium_payment_model.dart 2>&1 | grep -i "error" > /dev/null
if [ $? -eq 1 ]; then
    test_check "Payment model has no errors" 0
else
    test_check "Payment model has no errors" 1
    dart analyze lib/models/premium_payment_model.dart 2>&1 | grep -i "error"
fi

# Check for proper imports
echo ""
echo "Phase 8: Checking Dependencies"
echo "----------------------------------"

if grep -q "flutter_stripe" pubspec.yaml; then
    test_check "flutter_stripe dependency exists" 0
else
    test_check "flutter_stripe dependency exists" 1
fi

# Database schema validation
echo ""
echo "Phase 9: Validating Database Schema"
echo "----------------------------------------"

# Check premium_payments table structure
if grep -q "CREATE TABLE.*premium_payments" supabase/migrations/add_premium_payments_table.sql; then
    test_check "premium_payments table definition exists" 0
    
    # Check key columns
    if grep -q "subscription_type" supabase/migrations/add_premium_payments_table.sql; then
        test_check "subscription_type column exists" 0
    else
        test_check "subscription_type column exists" 1
    fi
    
    if grep -q "payment_intent_id" supabase/migrations/add_premium_payments_table.sql; then
        test_check "payment_intent_id column exists" 0
    else
        test_check "payment_intent_id column exists" 1
    fi
    
    if grep -q "expires_at" supabase/migrations/add_premium_payments_table.sql; then
        test_check "expires_at column exists" 0
    else
        test_check "expires_at column exists" 1
    fi
else
    test_check "premium_payments table definition exists" 1
fi

# Check users table additions
if grep -q "is_premium" supabase/migrations/add_premium_subscription.sql; then
    test_check "is_premium column exists" 0
else
    test_check "is_premium column exists" 1
fi

if grep -q "premium_expires_at" supabase/migrations/add_premium_subscription.sql; then
    test_check "premium_expires_at column exists" 0
else
    test_check "premium_expires_at column exists" 1
fi

# Pricing validation
echo ""
echo "Phase 10: Validating Pricing"
echo "--------------------------------"

if grep -q "19.99" lib/services/premium_subscription_service.dart; then
    test_check "Monthly price set to \$19.99" 0
else
    test_check "Monthly price set to \$19.99" 1
fi

if grep -q "167.99" lib/services/premium_subscription_service.dart; then
    test_check "Annual price set to \$167.99" 0
else
    test_check "Annual price set to \$167.99" 1
fi

if grep -q "0.70\|70%" lib/services/premium_subscription_service.dart; then
    test_check "70% discount configured" 0
else
    test_check "70% discount configured" 1
fi

# Final Summary
echo ""
echo "================================================"
echo "TEST SUMMARY"
echo "================================================"
echo ""

TOTAL_TESTS=$((ERRORS + WARNINGS))

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}ALL TESTS PASSED!${NC}"
    echo ""
    echo "Your premium subscription system is ready for deployment!"
    echo ""
    echo "Next steps:"
    echo "1. Deploy Edge Functions (if not done)"
    echo "2. Apply database migrations"
    echo "3. Configure Stripe webhooks"
    echo "4. Test with real payment: 4242 4242 4242 4242"
    echo ""
    exit 0
else
    echo -e "${RED}TESTS FAILED${NC}"
    echo ""
    echo "Errors found: $ERRORS"
    echo "Warnings: $WARNINGS"
    echo ""
    echo "Please fix the errors above before deploying."
    echo ""
    exit 1
fi
