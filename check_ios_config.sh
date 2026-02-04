#!/bin/bash

echo "🔍 iOS Subscription Configuration Checker"
echo "=========================================="
echo ""

PROJECT_ROOT="/Users/mrbebo/Documents/Github/billing_test_app"
cd "$PROJECT_ROOT" || exit 1

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass() {
    echo -e "${GREEN}✅ $1${NC}"
}

check_fail() {
    echo -e "${RED}❌ $1${NC}"
}

check_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check 1: StoreKit Configuration File
echo "1. Checking StoreKit configuration file..."
if [ -f "Configuration.storekit" ]; then
    check_pass "Configuration.storekit exists"
    
    # Check if it contains the correct product ID
    if grep -q "billing_test_monthly_ios" "Configuration.storekit"; then
        check_pass "Product ID 'billing_test_monthly_ios' found in StoreKit config"
    else
        check_fail "Product ID 'billing_test_monthly_ios' NOT found in StoreKit config"
    fi
else
    check_fail "Configuration.storekit NOT found"
fi
echo ""

# Check 2: Entitlements File
echo "2. Checking iOS entitlements..."
if [ -f "ios/Runner/Runner.entitlements" ]; then
    check_pass "Runner.entitlements exists"
    
    # Check if it contains in-app purchase capability
    if grep -q "com.apple.developer.in-app-payments" "ios/Runner/Runner.entitlements"; then
        check_pass "In-App Purchase capability configured"
    else
        check_fail "In-App Purchase capability NOT configured"
    fi
else
    check_fail "Runner.entitlements NOT found"
fi
echo ""

# Check 3: Product ID in Code
echo "3. Checking product ID in main.dart..."
if [ -f "lib/main.dart" ]; then
    if grep -q "billing_test_monthly_ios" "lib/main.dart"; then
        check_pass "iOS product ID 'billing_test_monthly_ios' found in code"
    else
        check_warn "iOS product ID 'billing_test_monthly_ios' NOT found in code"
    fi
else
    check_fail "lib/main.dart NOT found"
fi
echo ""

# Check 4: in_app_purchase dependency
echo "4. Checking Flutter dependencies..."
if [ -f "pubspec.yaml" ]; then
    if grep -q "in_app_purchase:" "pubspec.yaml"; then
        check_pass "in_app_purchase plugin found in pubspec.yaml"
        grep "in_app_purchase:" pubspec.yaml | sed 's/^/    /'
    else
        check_fail "in_app_purchase plugin NOT found in pubspec.yaml"
    fi
else
    check_fail "pubspec.yaml NOT found"
fi
echo ""

# Check 5: Info.plist
echo "5. Checking Info.plist..."
if [ -f "ios/Runner/Info.plist" ]; then
    check_pass "Info.plist exists"
else
    check_fail "Info.plist NOT found"
fi
echo ""

# Check 6: Xcode workspace
echo "6. Checking Xcode workspace..."
if [ -d "ios/Runner.xcworkspace" ]; then
    check_pass "Xcode workspace exists"
else
    check_fail "Xcode workspace NOT found - run 'pod install' in ios directory"
fi
echo ""

# Summary
echo "=========================================="
echo "📋 NEXT STEPS:"
echo "=========================================="
echo ""
echo "If all checks passed, you need to:"
echo "1. Open Xcode: open ios/Runner.xcworkspace"
echo "2. Add Configuration.storekit to Xcode project"
echo "3. Add Runner.entitlements to Xcode project"
echo "4. Add In-App Purchase capability in Xcode"
echo "5. Enable StoreKit Configuration in scheme settings"
echo ""
echo "📖 See IOS_SETUP_GUIDE.md for detailed instructions"
echo ""
