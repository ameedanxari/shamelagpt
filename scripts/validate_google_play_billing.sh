#!/usr/bin/env bash

# Google Play Billing Setup Validator
# Validates Android donation subscription configuration
# Usage: ./scripts/validate_google_play_billing.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT" || exit 1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
VALIDATION_FAILURES=0

echo "==============================================="
echo "Google Play Billing Setup Validator"
echo "==============================================="
echo ""

# Check 1: Verify product IDs in code
echo "[1/5] Checking product IDs in DonationViewModel.kt..."
ANDROID_PRODUCT_IDS_FILE="shamelagpt-android/app/src/main/java/com/shamelagpt/android/presentation/settings/DonationViewModel.kt"

if [ ! -f "$ANDROID_PRODUCT_IDS_FILE" ]; then
    echo -e "${RED}✗ File not found: $ANDROID_PRODUCT_IDS_FILE${NC}"
    exit 1
fi

EXPECTED_IDS=(
    "com.shamelagpt.android.donation.1monthly"
    "com.shamelagpt.android.donation.5monthly"
    "com.shamelagpt.android.donation.10month"
    "com.shamelagpt.android.donation.100year"
)

MISSING_IDS=0
for id in "${EXPECTED_IDS[@]}"; do
    length=${#id}
    if grep -Fq "\"$id\"" "$ANDROID_PRODUCT_IDS_FILE" && [ "$length" -le 40 ]; then
        echo -e "${GREEN}✓ Found: $id ($length characters)${NC}"
    else
        echo -e "${RED}✗ Missing or invalid: $id ($length characters)${NC}"
        MISSING_IDS=$((MISSING_IDS + 1))
    fi
done

if [ $MISSING_IDS -eq 0 ]; then
    echo -e "${GREEN}✓ All product IDs present${NC}"
else
    echo -e "${RED}✗ $MISSING_IDS product IDs missing${NC}"
    VALIDATION_FAILURES=$((VALIDATION_FAILURES + MISSING_IDS))
fi
echo ""

# Check 2: Verify billing service implementation
echo "[2/5] Checking GooglePlayDonationBillingService implementation..."
BILLING_SERVICE="shamelagpt-android/app/src/main/java/com/shamelagpt/android/data/billing/GooglePlayDonationBillingService.kt"

if [ ! -f "$BILLING_SERVICE" ]; then
    echo -e "${RED}✗ File not found: $BILLING_SERVICE${NC}"
    exit 1
fi

BILLING_CHECKS=(
    "BillingClient.newBuilder"
    "queryProductDetailsAsync"
    "launchBillingFlow"
    "acknowledgePurchase"
    "ProductType.SUBS"
)

BILLING_MISSING=0
for check in "${BILLING_CHECKS[@]}"; do
    if grep -Fq "$check" "$BILLING_SERVICE"; then
        echo -e "${GREEN}✓ Found: $check${NC}"
    else
        echo -e "${RED}✗ Missing: $check${NC}"
        BILLING_MISSING=$((BILLING_MISSING + 1))
    fi
done

if [ $BILLING_MISSING -eq 0 ]; then
    echo -e "${GREEN}✓ Billing service properly implemented${NC}"
else
    echo -e "${RED}✗ $BILLING_MISSING implementation items missing${NC}"
    VALIDATION_FAILURES=$((VALIDATION_FAILURES + BILLING_MISSING))
fi
echo ""

# Check 3: Verify domain model
echo "[3/5] Checking domain billing models..."
DOMAIN_BILLING="shamelagpt-android/app/src/main/java/com/shamelagpt/android/domain/billing/"

if [ ! -d "$DOMAIN_BILLING" ]; then
    echo -e "${RED}✗ Domain billing directory not found${NC}"
    exit 1
fi

DOMAIN_FILES=("DonationBillingService.kt")
DOMAIN_MISSING=0

for file in "${DOMAIN_FILES[@]}"; do
    if [ -f "$DOMAIN_BILLING$file" ]; then
        echo -e "${GREEN}✓ Found: $file${NC}"
    else
        echo -e "${RED}✗ Missing: $file${NC}"
        DOMAIN_MISSING=$((DOMAIN_MISSING + 1))
    fi
done

if [ $DOMAIN_MISSING -eq 0 ]; then
    echo -e "${GREEN}✓ Domain billing models present${NC}"
else
    VALIDATION_FAILURES=$((VALIDATION_FAILURES + DOMAIN_MISSING))
fi
echo ""

# Check 4: Verify build.gradle dependencies
echo "[4/5] Checking Google Play Billing dependency..."
BUILD_GRADLE="shamelagpt-android/gradle/libs.versions.toml"

if [ ! -f "$BUILD_GRADLE" ]; then
    echo -e "${YELLOW}⚠ Not checking libs.versions.toml (alternative configuration)${NC}"
else
    if grep -Eq 'play-billing|com\.android\.billingclient' "$BUILD_GRADLE"; then
        echo -e "${GREEN}✓ Google Play Billing dependency configured${NC}"
    else
        echo -e "${RED}✗ Could not verify Google Play Billing dependency${NC}"
        VALIDATION_FAILURES=$((VALIDATION_FAILURES + 1))
    fi
fi
echo ""

# Check 5: Verify test setup
echo "[5/5] Checking test files..."
TEST_FILE="shamelagpt-android/app/src/test/java/com/shamelagpt/android/presentation/settings/DonationViewModelTest.kt"

if [ ! -f "$TEST_FILE" ]; then
    echo -e "${RED}✗ Test file not found: $TEST_FILE${NC}"
    VALIDATION_FAILURES=$((VALIDATION_FAILURES + 1))
else
    TEST_CHECKS=("productIds" "loadProducts")

    TEST_MISSING=0
    for check in "${TEST_CHECKS[@]}"; do
        if grep -Fq "$check" "$TEST_FILE"; then
            echo -e "${GREEN}✓ Found in tests: $check${NC}"
        else
            echo -e "${YELLOW}⚠ Missing in tests: $check${NC}"
            TEST_MISSING=$((TEST_MISSING + 1))
        fi
    done

    for id in "${EXPECTED_IDS[@]}"; do
        if grep -Fq "\"$id\"" "$TEST_FILE"; then
            echo -e "${GREEN}✓ Test covers: $id${NC}"
        else
            echo -e "${RED}✗ Test missing: $id${NC}"
            TEST_MISSING=$((TEST_MISSING + 1))
        fi
    done

    if [ "$TEST_MISSING" -ne 0 ]; then
        VALIDATION_FAILURES=$((VALIDATION_FAILURES + TEST_MISSING))
    fi
fi
echo ""

# Summary
echo "==============================================="
echo "Validation Summary"
echo "==============================================="
echo ""
echo "Next Steps:"
echo "1. Go to Google Play Console → ShamelaGPT app"
echo "2. Monetization → Products → Subscriptions"
echo "3. Create 4 subscription products (see GOOGLE_PLAY_BILLING_SETUP.md)"
echo "4. Add test license accounts: Settings → License Testing"
echo "5. Build and test: ./gradlew bundleRelease"
echo ""
if [ "$VALIDATION_FAILURES" -eq 0 ]; then
    echo -e "${GREEN}✓ Code validation complete${NC}"
    exit 0
fi

echo -e "${RED}✗ Code validation failed with $VALIDATION_FAILURES issue(s)${NC}"
exit 1
