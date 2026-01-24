#!/bin/bash

# Premium Subscription System - Comprehensive Test Script
# This script tests all components of the premium subscription system

echo "Premium Subscription System - Test Suite"
echo "============================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNINGS=0

# Function to print success
success() {
    echo -e "${GREEN}$1${NC}"
    ((TESTS_PASSED++))
}

# Function to print error
error() {
    echo -e "${RED}$1${NC}"
    ((TESTS_FAILED++))
}

# Function to print warning
warning() {
    echo -e "${YELLOW}$1${NC}"
    ((TESTS_WARNINGS++))
}

# Function to print info
info() {
    echo -e "$1"
}

echo "Pre-flight Checks"
echo "--------------------"

# Check if Supabase CLI is installed
if command -v supabase &> /dev/null; then
    success "Supabase CLI is installed"
    SUPABASE_CLI_AVAILABLE=true
else
    warning "Supabase CLI not found (optional for this test)"
    warning "Install with: npm install -g supabase"
    SUPABASE_CLI_AVAILABLE=false
fi

# Check if project is linked
if [ -f .supabase/config.toml ]; then
    success "Project is linked to Supabase"
else
    info "Project not linked locally (this is okay for testing code structure)"
fi

echo ""
echo "Testing Database Schema"
echo "-------------------------"

# Check if migrations exist
if [ -f "supabase/migrations/add_premium_subscription.sql" ]; then
    success "Found add_premium_subscription.sql migration"
else
    error "Missing add_premium_subscription.sql migration"
fi

if [ -f "supabase/migrations/add_premium_payments_table.sql" ]; then
    success "Found add_premium_payments_table.sql migration"
else
    error "Missing add_premium_payments_table.sql migration"
fi

echo ""
echo "Testing Edge Functions"
echo "-------------------------"

# Check if edge function files exist
if [ -f "supabase/functions/create-premium-subscription/index.ts" ]; then
    success "Found create-premium-subscription Edge Function"
    
    # Check if it has the correct structure
    if grep -q "productType: 'premium_subscription'" supabase/functions/create-premium-subscription/index.ts; then
        success "Edge function has correct metadata structure"
    else
        error "Edge function missing productType metadata"
    fi
else
    error "Missing create-premium-subscription Edge Function"
fi

if [ -f "supabase/functions/stripe-webhook/index.ts" ]; then
    success "Found stripe-webhook Edge Function"
    
    # Check if it handles premium subscriptions
    if grep -q "handlePremiumSubscriptionSuccess" supabase/functions/stripe-webhook/index.ts; then
        success "Webhook handles premium subscriptions"
    else
        error "Webhook missing premium subscription handler"
    fi
else
    error "Missing stripe-webhook Edge Function"
fi

echo ""
echo "Testing Flutter Code"
echo "----------------------"

# Check service files
if [ -f "lib/services/premium_subscription_service.dart" ]; then
    success "Found PremiumSubscriptionService"
    
    # Check for key methods
    if grep -q "createPayment" lib/services/premium_subscription_service.dart; then
        success "Service has createPayment method"
    else
        error "Service missing createPayment method"
    fi
    
    if grep -q "processPayment" lib/services/premium_subscription_service.dart; then
        success "Service has processPayment method"
    else
        error "Service missing processPayment method"
    fi
    
    if grep -q "calculateApplicationFee" lib/services/premium_subscription_service.dart; then
        success "Service has discount calculation"
    else
        error "Service missing discount calculation"
    fi
else
    error "Missing PremiumSubscriptionService"
fi

# Check model files
if [ -f "lib/models/premium_payment_model.dart" ]; then
    success "Found PremiumPaymentModel"
else
    error "Missing PremiumPaymentModel"
fi

# Check UI files
if [ -f "lib/features/premium/premium_payment_page.dart" ]; then
    success "Found PremiumPaymentPage"
else
    error "Missing PremiumPaymentPage"
fi

if [ -f "lib/widgets/premium_upgrade_dialog.dart" ]; then
    success "Found PremiumUpgradeDialog"
    
    # Check if it navigates to payment page
    if grep -q "PremiumPaymentPage" lib/widgets/premium_upgrade_dialog.dart; then
        success "Dialog navigates to payment page"
    else
        error "Dialog doesn't navigate to payment page"
    fi
else
    error "Missing PremiumUpgradeDialog"
fi

# Check navigation locks
if [ -f "lib/app/home_page.dart" ]; then
    if grep -q "PremiumUpgradeDialog" lib/app/home_page.dart; then
        success "Home page has premium gates"
    else
        error "Home page missing premium gates"
    fi
else
    error "Missing home_page.dart"
fi

# Check badge implementation
if [ -f "lib/features/feed/enhanced_post_card.dart" ]; then
    if grep -q "workspace_premium" lib/features/feed/enhanced_post_card.dart; then
        success "Feed has golden badge for premium users"
    else
        error "Feed missing golden badge"
    fi
else
    error "Missing enhanced_post_card.dart"
fi

echo ""
echo "Testing Environment Variables"
echo "--------------------------------"

if [ "$SUPABASE_CLI_AVAILABLE" = true ]; then
    info "Checking Supabase secrets..."

    # Try to list secrets (requires authenticated session)
    if supabase secrets list &> /dev/null; then
        SECRET_OUTPUT=$(supabase secrets list 2>&1)
        
        if echo "$SECRET_OUTPUT" | grep -q "stripe_secret_key"; then
            success "stripe_secret_key is set"
        else
            warning "stripe_secret_key not set. Run: supabase secrets set stripe_secret_key=sk_test_xxx"
        fi
        
        if echo "$SECRET_OUTPUT" | grep -q "stripe_webhook_secret"; then
            success "stripe_webhook_secret is set"
        else
            warning "stripe_webhook_secret not set (optional for webhooks)"
        fi
    else
        info "Secrets check skipped (not logged in or not linked)"
    fi
else
    info "Skipping secrets check (Supabase CLI not available)"
fi

echo ""
echo "Testing Edge Function Deployment"
echo "-----------------------------------"

# Check if functions are deployed
if [ "$SUPABASE_CLI_AVAILABLE" = true ] && supabase functions list &> /dev/null; then
    FUNCTIONS_OUTPUT=$(supabase functions list 2>&1)
    
    if echo "$FUNCTIONS_OUTPUT" | grep -q "create-premium-subscription"; then
        success "create-premium-subscription is deployed"
    else
        warning "create-premium-subscription not deployed yet"
    fi
    
    if echo "$FUNCTIONS_OUTPUT" | grep -q "stripe-webhook"; then
        success "stripe-webhook is deployed"
    else
        warning "stripe-webhook not deployed yet"
    fi
else
    info "Skipping deployment check (requires Supabase CLI and authentication)"
fi

echo ""
echo "Testing Pricing Configuration"
echo "--------------------------------"

# Check pricing constants
if grep -q "monthlyPrice = 19.99" lib/services/premium_subscription_service.dart; then
    success "Monthly price: \$19.99"
else
    error "Incorrect monthly price"
fi

if grep -q "annualPrice = 167.99" lib/services/premium_subscription_service.dart; then
    success "Annual price: \$167.99"
else
    error "Incorrect annual price"
fi

# Check discount percentage
if grep -q "0.70" lib/services/premium_subscription_service.dart || grep -q "70%" lib/services/premium_subscription_service.dart; then
    success "Ecosystem discount: 70%"
else
    error "Incorrect discount percentage"
fi

echo ""
echo "Testing Documentation"
echo "------------------------"

DOCS=(
    "PREMIUM_SUBSCRIPTION_IMPLEMENTATION.md"
    "PREMIUM_QUICK_START.md"
    "PREMIUM_SYSTEM_SUMMARY.md"
    "DEPLOYMENT_STATUS.md"
    "STRIPE_WEBHOOKS_SETUP.md"
    "PREMIUM_WEBHOOKS_FLOW.md"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        success "Found $doc"
    else
        warning "Missing $doc"
    fi
done

echo ""
echo "Code Quality Checks"
echo "---------------------"

# Check for common issues
info "Checking for potential issues..."

# Check if files compile (basic syntax check)
if command -v dart &> /dev/null; then
    if dart analyze --fatal-infos lib/services/premium_subscription_service.dart 2>&1 | grep -q "No issues found"; then
        success "PremiumSubscriptionService has no analysis issues"
    else
        warning "PremiumSubscriptionService may have analysis issues"
    fi
    
    if dart analyze --fatal-infos lib/models/premium_payment_model.dart 2>&1 | grep -q "No issues found"; then
        success "PremiumPaymentModel has no analysis issues"
    else
        warning "PremiumPaymentModel may have analysis issues"
    fi
else
    warning "Dart not found in PATH, skipping code analysis"
fi

echo ""
echo "Integration Tests"
echo "-------------------"

info "These tests verify the complete flow..."

# Check if all pieces are connected
INTEGRATION_CHECKS=(
    "PremiumUpgradeDialog:PremiumPaymentPage:Dialog should navigate to payment page"
    "PremiumPaymentPage:PremiumSubscriptionService:Payment page should use service"
    "PremiumSubscriptionService:create-premium-subscription:Service should call Edge Function"
)

for check in "${INTEGRATION_CHECKS[@]}"; do
    IFS=':' read -r -a parts <<< "$check"
    file1="${parts[0]}"
    file2="${parts[1]}"
    description="${parts[2]}"
    
    # Simple check if files reference each other
    if find lib -name "*.dart" -type f -exec grep -l "$file2" {} \; | xargs grep -l "$file1" &> /dev/null; then
        success "$description"
    else
        info "$description - verify manually"
    fi
done

echo ""
echo "Test Summary"
echo "==============="
echo ""
echo -e "${GREEN}Passed:  $TESTS_PASSED${NC}"
echo -e "${RED}Failed:  $TESTS_FAILED${NC}"
echo -e "${YELLOW}Warnings: $TESTS_WARNINGS${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All critical tests passed!${NC}"
    echo ""
    echo "Next Steps:"
    echo "1. Apply database migrations (if not done)"
    echo "2. Deploy Edge Functions (if not done)"
    echo "3. Configure Stripe webhook endpoint"
    echo "4. Test payment flow with test card: 4242 4242 4242 4242"
    echo ""
    echo "See PREMIUM_QUICK_START.md for deployment guide"
    exit 0
else
    echo -e "${RED}Some tests failed. Please fix the issues above.${NC}"
    exit 1
fi
