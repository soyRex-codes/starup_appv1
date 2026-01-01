#!/bin/bash

# FounderVers iOS Build Script
# This script automates the iOS release build process

set -e  # Exit on error

echo "🚀 FounderVers iOS Release Build Script"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "Error: pubspec.yaml not found. Run this script from the project root."
    exit 1
fi

# Step 1: Check for production environment file
echo "📋 Step 1: Checking environment configuration..."
if [ ! -f ".env.production" ]; then
    print_error ".env.production file not found!"
    echo "Please create .env.production with your production keys."
    exit 1
fi

# Check for Stripe production key
if grep -q "pk_test_" ".env.production"; then
    print_warning "WARNING: .env.production contains TEST Stripe key!"
    echo "Please update to LIVE Stripe key before App Store submission."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
print_success "Environment configuration checked"

# Step 2: Clean previous builds
echo ""
echo "🧹 Step 2: Cleaning previous builds..."
flutter clean
print_success "Clean complete"

# Step 3: Get dependencies
echo ""
echo "📦 Step 3: Getting Flutter dependencies..."
flutter pub get
print_success "Dependencies installed"

# Step 4: Generate launcher icons
echo ""
echo "🎨 Step 4: Generating launcher icons..."
if flutter pub run flutter_launcher_icons; then
    print_success "Launcher icons generated"
else
    print_warning "Launcher icon generation failed (non-critical)"
fi

# Step 5: Run Flutter analyze
echo ""
echo "🔍 Step 5: Running Flutter analyze..."
if flutter analyze; then
    print_success "No analysis issues found"
else
    print_warning "Analysis found some issues. Review and fix if critical."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 6: Install iOS dependencies
echo ""
echo "📱 Step 6: Installing iOS CocoaPods dependencies..."
cd ios
pod install
cd ..
print_success "iOS dependencies installed"

# Step 7: Extract Stripe publishable key from .env.production
echo ""
echo "🔑 Step 7: Extracting Stripe publishable key..."
STRIPE_PK=$(grep "^STRIPE_PUBLISHABLE_KEY=" .env.production | cut -d'=' -f2 | tr -d '\r\n"' )
if [ -z "$STRIPE_PK" ]; then
    print_error "STRIPE_PUBLISHABLE_KEY not found in .env.production!"
    exit 1
fi
print_success "Stripe key extracted (${STRIPE_PK:0:12}...)"

# Step 8: Build iOS release with dart-define
echo ""
echo "🔨 Step 8: Building iOS release..."
echo "This may take several minutes..."
if flutter build ios --release --no-codesign \
    --dart-define=STRIPE_PUBLISHABLE_KEY="$STRIPE_PK"; then
    print_success "iOS release build complete!"
else
    print_error "iOS build failed!"
    exit 1
fi

# Step 9: Summary
echo ""
echo "========================================"
echo "✅ Build Complete!"
echo "========================================"
echo ""
echo "Next Steps:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Select 'Any iOS Device (arm64)' as destination"
echo "3. Product → Archive (⌘B + Shift)"
echo "4. Upload to App Store Connect"
echo ""
echo "Bundle ID: com.foundervers.mobile"
echo "Version: $(grep 'version:' pubspec.yaml | awk '{print $2}')"
echo ""
print_warning "Remember to verify Stripe LIVE keys in .env.production!"
echo ""
