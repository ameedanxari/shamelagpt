# Google Play Console Setup — Quick Reference Card

**App**: ShamelaGPT
**Date**: 2026-05-20
**Purpose**: Fast checklist for creating donation subscriptions

---

## Product IDs to Create (Copy-Paste Safe)

```
com.shamelagpt.android.donation.1monthly
com.shamelagpt.android.donation.5monthly
com.shamelagpt.android.donation.10month
com.shamelagpt.android.donation.100year
```

---

## Step-by-Step Setup

### 1. Go to Monetization > Products > Subscriptions
```
https://play.google.com/console/u/0/developers
→ Select ShamelaGPT app
→ Left sidebar: Monetization
→ Products > Subscriptions
```

### 2. Create First Product ($1/month)

| Field | Value |
|-------|-------|
| **Product ID** | `com.shamelagpt.android.donation.1monthly` |
| **Title** | Monthly Donation - $1 |
| **Description** | Support ShamelaGPT with a $1 monthly donation. Auto-renews. |
| **Billing period** | 1 month |
| **Default price** | $1.00 USD |
| **Free trial** | (leave blank) |
| **Grace period** | 3 days |
| **Status** | Active |

### 3. Create Second Product ($5/month)

| Field | Value |
|-------|-------|
| **Product ID** | `com.shamelagpt.android.donation.5monthly` |
| **Title** | Monthly Donation - $5 |
| **Description** | Support ShamelaGPT with a $5 monthly donation. Auto-renews. |
| **Billing period** | 1 month |
| **Default price** | $5.00 USD |
| **Free trial** | (leave blank) |
| **Grace period** | 3 days |
| **Status** | Active |

### 4. Create Third Product ($10/month)

| Field | Value |
|-------|-------|
| **Product ID** | `com.shamelagpt.android.donation.10month` |
| **Title** | Monthly Donation - $10 |
| **Description** | Support ShamelaGPT with a $10 monthly donation. Auto-renews. |
| **Billing period** | 1 month |
| **Default price** | $10.00 USD |
| **Free trial** | (leave blank) |
| **Grace period** | 3 days |
| **Status** | Active |

### 5. Create Fourth Product ($100/year)

| Field | Value |
|-------|-------|
| **Product ID** | `com.shamelagpt.android.donation.100year` |
| **Title** | Yearly Donation - $100 |
| **Description** | Support ShamelaGPT with a $100 annual donation. Auto-renews yearly. |
| **Billing period** | 1 year |
| **Default price** | $100.00 USD |
| **Free trial** | (leave blank) |
| **Grace period** | 3 days |
| **Status** | Active |

### 6. Verify All 4 Are Active

**Navigate**: Monetization → Products → Subscriptions

You should see:
- ✅ `com.shamelagpt.android.donation.1monthly` (Active)
- ✅ `com.shamelagpt.android.donation.5monthly` (Active)
- ✅ `com.shamelagpt.android.donation.10month` (Active)
- ✅ `com.shamelagpt.android.donation.100year` (Active)

### 7. Set Up Test Accounts

**Navigate**: Monetization → Settings → License Testing

1. Click **Add license testers**
2. Enter test email addresses:
   ```
   your-test-email@gmail.com
   qa-tester@yourcompany.com
   ```
3. Save

---

## Testing Checklist

### On Android Device (Signed in with Test Account)

- [ ] Open ShamelaGPT app (installed from Play Console internal testing)
- [ ] Go to **Settings > Donate**
- [ ] All 4 products appear with correct names and prices
- [ ] Tap one product → Google Play billing sheet appears
- [ ] Product details match (name, price, period)
- [ ] Tap **Subscribe** → transaction completes (no charge for test account)
- [ ] Billing sheet closes → app shows active donation
- [ ] Close app completely and reopen
- [ ] Donation still shows as active

### In Play Console

- [ ] Go to **Reports > Subscriptions**
- [ ] Your test purchase appears under "Current subscribers"
- [ ] No errors in "Subscription issues"

---

## Character Count Verification

| Product ID | Characters | Status |
|-----------|-----------|--------|
| `com.shamelagpt.android.donation.1monthly` | 40 | ✓ |
| `com.shamelagpt.android.donation.5monthly` | 40 | ✓ |
| `com.shamelagpt.android.donation.10month` | 39 | ✓ |
| `com.shamelagpt.android.donation.100year` | 39 | ✓ |

All ≤ 40 characters (Google Play limit) ✅

---

## Common Mistakes to Avoid

❌ **Don't do these**:

1. **Wrong product ID spelling** (case-sensitive)
   - ❌ `com.shamelagpt.android.donation.1Monthly` (capital M)
   - ✅ `com.shamelagpt.android.donation.1monthly` (lowercase)

2. **Mismatched product ID between Play Console and code**
   - The Android app expects these exact IDs
   - If Play Console IDs differ, products won't load

3. **Setting status to "Inactive"**
   - Must be **Active** before app can query them
   - Test first in Internal Testing track

4. **Free trial for donations**
   - Leave blank (no trial period)
   - Donations should not have delays

5. **Exceeding 40 characters**
   - Google Play rejects IDs > 40 chars
   - Our IDs are all ≤39 chars ✓

---

## If Products Don't Load

### Check 1: Product IDs Match Exactly

**Code location**: `shamelagpt-android/app/src/main/java/com/shamelagpt/android/presentation/settings/DonationViewModel.kt` (lines 161-166)

**Play Console**: Monetization → Products → Subscriptions

Compare character-by-character (case-sensitive).

### Check 2: App Signed with Production Key

- Debug APKs cannot access real products
- Must install from Play Console Internal Testing track (not local APK)

### Check 3: Signed in with Test Account

- Go to device **Settings > Accounts > Google**
- Should show test email from License Testing setup

### Check 4: Products Are Active

- Play Console → Products → Subscriptions
- Each product status = **Active**

### Check 5: Logcat

```bash
adb logcat | grep "GooglePlayDonationBillingService"
```

Look for:
- `event=products.loaded valid=4` (all 4 loaded ✓)
- `event=products.failure` (products missing/inactive ✗)
- `event=status.connectionFailure` (not signed in or debug APK ✗)

---

## Reference Links

- **Google Play Console**: https://play.google.com/console
- **Billing Library Docs**: https://developer.android.com/google/play/billing
- **Setup Guide**: See [GOOGLE_PLAY_BILLING_SETUP.md](./GOOGLE_PLAY_BILLING_SETUP.md)
- **iOS Parity**: See [DONATION_SUBSCRIPTIONS_PARITY.md](./DONATION_SUBSCRIPTIONS_PARITY.md)

---

## Success Indicators ✅

When everything is set up correctly, you'll see:

1. **In App** (Settings > Donate):
   - 4 donation buttons with names and prices
   - Tapping a button opens Google Play billing
   - After purchase, UI shows active subscription

2. **In Play Console** (Reports > Subscriptions):
   - Test purchases appear immediately
   - "Current subscribers" count increases

3. **In Logcat**:
   ```
   event=products.loaded valid=4 unfetched=0
   event=purchase.launch productId=com.shamelagpt.android.donation.5monthly code=0
   event=purchase.acknowledged code=0
   event=purchase.completed productId=com.shamelagpt.android.donation.5monthly
   ```

---

**Estimated Setup Time**: 15-20 minutes
**Testing Time**: 10-15 minutes
**Total**: ~30 minutes

Good luck! 🚀
