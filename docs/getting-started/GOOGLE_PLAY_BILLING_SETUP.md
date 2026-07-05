# Google Play Billing Setup Guide — Donation Subscriptions

**Date**: May 2026
**Target**: Android donation subscriptions via Google Play Billing Library
**Status**: Configuration & Testing Reference

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Google Play Console Configuration](#google-play-console-configuration)
3. [Subscription Product Setup](#subscription-product-setup)
4. [Testing & Validation](#testing--validation)
5. [Troubleshooting](#troubleshooting)
6. [Production Rollout Checklist](#production-rollout-checklist)

---

## Prerequisites

### Required Access
- **Google Play Console** admin/developer account for ShamelaGPT
- **Android app** uploaded to internal testing track (minimum)
- **Signing key** configured in Play Console (matches build key)
- **Developer account** registered with Google Play

### Verify in Play Console
1. Go to **Settings > App signing** — confirm signing key is set
2. Go to **Release > Internal testing** — ensure app is uploaded
3. Go to **Monetization > Products** — verify "Subscriptions" section exists

---

## Google Play Console Configuration

### Step 1: Access Monetization Settings

1. Open [Google Play Console](https://play.google.com/console)
2. Select **ShamelaGPT** app
3. In left sidebar, click **Monetization** (or **Monetize** if new)
4. Ensure **Products > Subscriptions** is visible

### Step 2: Create Test License Accounts

**Navigate**: Monetization → **Settings → License Testing**

1. **Add test accounts** (email addresses for QA/testing):
   ```
   test-donation-qa@yourcompany.com
   test-donation-dev@yourcompany.com
   ```
   - Click **Add license testers**
   - Enter email(s)
   - Save

2. **Effect**: These accounts can:
   - Purchase subscriptions without payment method
   - See test transactions in Play Console
   - Use real Google Play Billing flow (no charge)

---

## Subscription Product Setup

### Step 3: Create Subscription Products

**Navigate**: Monetization → **Products → Subscriptions**

#### Product 1: Monthly Donation ($1)

1. Click **Create subscription**
2. **Product ID**: `com.shamelagpt.android.donation.1monthly` (40 characters)
3. **Default language**: English
4. **Title**: "Monthly Donation - $1"
5. **Description**: "Support ShamelaGPT with a $1 monthly donation. Auto-renews."
6. **Billing period**:
   - Select **1 month** (dropdown)
   - Recurrence type: **Recurring**
7. **Pricing**:
   - Default price: **$1.00 USD**
   - Click **Manage pricing** for per-country adjustments (optional)
8. **Subscription offer**:
   - No free trial (leave blank)
   - Grace period: **3 days** (auto-enabled)
9. **Status**: Set to **Active**
10. **Save**

#### Product 2: Monthly Donation ($5)

1. Repeat steps 1-10, but:
   - **Product ID**: `com.shamelagpt.android.donation.5monthly` (40 characters)
   - **Title**: "Monthly Donation - $5"
   - **Default price**: **$5.00 USD**

#### Product 3: Monthly Donation ($10)

1. Repeat steps 1-10, but:
   - **Product ID**: `com.shamelagpt.android.donation.10month` (39 characters)
   - **Title**: "Monthly Donation - $10"
   - **Default price**: **$10.00 USD**

#### Product 4: Yearly Donation ($100)

1. Repeat steps 1-10, but:
   - **Product ID**: `com.shamelagpt.android.donation.100year` (39 characters)
   - **Title**: "Yearly Donation - $100"
   - **Billing period**: **1 year** (dropdown)
   - **Default price**: **$100.00 USD**

### Step 4: Verify All Products

**Navigate**: Monetization → **Products → Subscriptions**

Verify all four appear in the list:
- ✅ `com.shamelagpt.android.donation.1monthly` — **Active**
- ✅ `com.shamelagpt.android.donation.5monthly` — **Active**
- ✅ `com.shamelagpt.android.donation.10month` — **Active**
- ✅ `com.shamelagpt.android.donation.100year` — **Active**

---

## Testing & Validation

### Step 5: Set Up Android Test Environment

#### Option A: Use Internal Testing Track (Recommended)

1. **Upload debug/release APK**:
   ```bash
   cd shamelagpt-android
   ./gradlew bundleRelease  # Creates .aab
   ```

2. **In Play Console**, go to **Release > Internal testing**
   - Click **Create new release**
   - Upload the `.aab` file
   - Add internal testers (same as license test accounts)
   - **Review and roll out**

#### Option B: Use Signed APK Directly

1. **Generate signed APK**:
   ```bash
   ./gradlew assembleRelease  # Creates .apk
   ```

2. **Install on test device**:
   ```bash
   adb install -r app/build/outputs/apk/release/app-release.apk
   ```

### Step 6: Test Purchase Flow

#### Prerequisites
- Test device/emulator connected
- App installed from Play Console (not direct APK — required for billing)
- Signed in with **test license account** (from Step 2)

#### Test Scenario 1: Load Products

1. Open ShamelaGPT app
2. Navigate to **Settings → Support / Donate**
3. **Expected**: Donation buttons appear with product names and prices:
   - "$1/month"
   - "$5/month"
   - "$10/month"
   - "$100/year"
4. **Verify**: All four products load without errors   - Prices should show: $1, $5, $10, $100   - Check **Logcat** for `GooglePlayDonationBillingService`:
     ```
     event=products.loaded valid=4 unfetched=0
     ```

#### Test Scenario 2: Initiate Purchase

1. Tap **"$5/month"** donation button
2. **Expected**: Google Play billing sheet appears
3. **Verify**:
   - Product name shown correctly
   - Price displayed ($5.00)
   - "Subscribe" button visible
   - **Logcat**:
     ```
     event=purchase.launch productId=com.shamelagpt.android.donation.5monthly code=0
     ```

#### Test Scenario 3: Complete Purchase (Test Account)

1. On billing sheet, tap **Subscribe**
2. **Expected**:
   - Transaction processes (no actual charge — test account)
   - Billing sheet closes
   - App returns to donation screen
3. **Verify**:
   - **Logcat**:
     ```
     event=purchase.acknowledged code=0
     event=purchase.completed productId=com.shamelagpt.android.donation.5monthly
     ```
   - UI shows "Active donation: $5/month" or similar indicator
   - Purchase state in app reflects active subscription

#### Test Scenario 4: Query Active Donation

1. Close and restart app
2. Navigate to **Settings → Donate**
3. **Expected**: App displays active subscription:
   - "You have an active $5/month donation"
   - Or indicator badge on donation button
4. **Verify**:
   - **Logcat**:
     ```
     event=status.loaded purchaseCount=1 activeProductId=com.shamelagpt.android.donation.5monthly
     ```

#### Test Scenario 5: Cancel Subscription

1. On test device, go to **Settings > Apps > Google Play Store > Storage > Manage Space > Delete data**
   - (Or: **Settings > Accounts > Google > Select account > Manage Google account > Payments > Manage your Google Play purchases**)
2. Find ShamelaGPT subscription in your purchase history
3. Select it and click **"Cancel subscription"**
4. Reopen ShamelaGPT Donate screen
5. **Expected**: Active donation indicator disappears

---

## Validation Checklist

### In-App Validation
- [ ] All 4 products load without errors
- [ ] Product names match Play Console exactly
- [ ] Prices display correctly for all locales (if multi-region)
- [ ] Purchase flow completes (test account)
- [ ] Active subscription persists after app restart
- [ ] Error handling works (e.g., network failure)

### Play Console Validation

**Navigate**: Monetization → **Reports → Subscriptions**

- [ ] Test purchase appears in "Current subscribers" (if using test account)
- [ ] Event logs show purchase timestamps
- [ ] No errors in "Subscription issues" section

**Navigate**: Settings → **License Testing**

- [ ] Test account listed as active tester
- [ ] Timestamp shows recent access

### Logcat Validation
- [ ] No crashes related to `GooglePlayDonationBillingService`
- [ ] Product loading: `event=products.loaded valid=4`
- [ ] Purchase: `event=purchase.launch` → `event=purchase.acknowledged`
- [ ] Status query: `event=status.loaded`

---

## Troubleshooting

### Issue: Products Not Loading
**Symptom**: Donation screen shows "Unable to load products"

**Causes & Fixes**:
1. **Play Console product IDs don't match code**
   - Verify exact spelling (case-sensitive):
     - Code: `com.shamelagpt.android.donation.1monthly`
     - Play Console: Must be identical
   - **Important**: Product IDs must be ≤40 characters (Google Play limit)
   - Check [DonationViewModel.kt#L161-L165](../../shamelagpt-android/app/src/main/java/com/shamelagpt/android/presentation/settings/DonationViewModel.kt#L161)

2. **App not using release signing key**
   - Only **production-signed apps** can query real products
   - Debug APK cannot access subscriptions
   - Solution: Install from Play Console internal testing track

3. **Test account not added to license testing**
   - Go to **Settings → License Testing**
   - Ensure test email is listed
   - Sign out and back in with test account

4. **Subscriptions not activated**
   - Go to **Monetization → Products → Subscriptions**
   - Check each product status = **Active**

**Debug**:
```bash
adb logcat | grep "GooglePlayDonationBillingService"
# Look for: event=products.connectionFailure OR event=products.failure
```

---

### Issue: "Item Unavailable" Error During Purchase

**Symptom**: Tap donation button → sheet appears → error "This item is unavailable"

**Causes & Fixes**:
1. **Subscription not active in Play Console**
   - Go to **Monetization → Products → Subscriptions**
   - Click each product, verify status = **Active**

2. **Billing client not properly initialized**
   - Check code: [GooglePlayDonationBillingService.kt#L45-L54](../../shamelagpt-android/app/src/main/java/com/shamelagpt/android/data/billing/GooglePlayDonationBillingService.kt#L45)
   - Ensure `BillingClient` is connected before purchase

3. **Test account has restrictions**
   - Remove from license testing, re-add
   - Or use different test account

**Debug**:
```bash
adb logcat | grep -E "purchase.launch|ITEM_UNAVAILABLE"
```

---

### Issue: Purchase Goes to "Pending" State

**Symptom**: After purchase, status shows "PENDING" instead of "PURCHASED"

**Causes**:
- Normal for test accounts — payment verification takes time
- Or user hasn't completed payment method setup

**Fix**:
- Wait 1-2 minutes and refresh app
- Check Play Store app > Account > Manage purchases
- Manually acknowledge if needed (your code does this automatically)

---

### Issue: Can't See Subscription in Play Store App

**Symptom**: Purchased subscription doesn't appear in **Play Store > Account > Subscriptions**

**Causes**:
1. Test account purchases may not display immediately
2. Subscriptions portal only shows "installed app" subscriptions

**Fix**:
- Wait 24 hours for test data to sync
- Or check in **Play Console → Reports → Subscriptions**

---

## Production Rollout Checklist

### Pre-Production
- [ ] All 4 subscription products created and active in Play Console
- [ ] License testing accounts added and tested
- [ ] App signed with production key
- [ ] All logcat validation checks pass
- [ ] No crashes in crash logs
- [ ] UX flow is intuitive (button labels, error messages clear)

### During Production Release
1. **Set subscriptions to "Active" in Play Console** (do this when app is live)
2. **Deploy app to production track** (Release/Staged rollout)
3. **Monitor** for 24–48 hours:
   - Play Console → Crash analytics
   - Play Console → ANR (Android Not Responding)
   - User feedback/ratings

### Post-Production
- [ ] Monitor subscription conversion rate (Play Console → Reports → Subscriptions)
- [ ] Track churn/cancellations
- [ ] Respond to user reviews mentioning billing
- [ ] Prepare refund/support policy (if needed)

---

## Reference: Product ID Mapping

| Use Case | iOS | Android | Android Chars |
|----------|-----|------|---|
| $1/month | `com.shamelagpt.ios.donation.1monthly` | `com.shamelagpt.android.donation.1monthly` | 40 ✓ |
| $5/month | `com.shamelagpt.ios.donation.5monthly` | `com.shamelagpt.android.donation.5monthly` | 40 ✓ |
| $10/month | `com.shamelagpt.ios.donation.10monthly` | `com.shamelagpt.android.donation.10month` | 39 ✓ |
| $100/year | `com.shamelagpt.ios.donation.100yearly` | `com.shamelagpt.android.donation.100year` | 39 ✓ |

---

## Additional Resources

- **Google Play Billing Library Docs**: https://developer.android.com/google/play/billing/integrate
- **Create and manage subscriptions**: https://support.google.com/googleplay/android-developer/answer/140504
- **Testing Guide**: https://developer.android.com/google/play/billing/test
- **Play Console Help**: https://support.google.com/googleplay/android-developer

---

## Support

For issues or questions:
1. Check [TROUBLESHOOTING_ANDROID.md](TROUBLESHOOTING_ANDROID.md) first
2. Review logcat output with `GooglePlayDonationBillingService` tag
3. Verify product IDs character-by-character in Play Console vs. code
4. Consult [GooglePlayDonationBillingService.kt](../../shamelagpt-android/app/src/main/java/com/shamelagpt/android/data/billing/GooglePlayDonationBillingService.kt) implementation
