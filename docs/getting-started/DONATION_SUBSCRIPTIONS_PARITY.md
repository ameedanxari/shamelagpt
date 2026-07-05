# Donation Subscriptions — iOS & Android Parity

**Date**: May 2026
**Status**: ✅ Configured
**Last Updated**: 2026-05-20

---

## Overview

Both iOS and Android apps support donation subscriptions through their respective native app store billing systems:
- **iOS**: StoreKit 2 (App Store)
- **Android**: Google Play Billing Library v8+

All product IDs, pricing, and billing periods are **synchronized across platforms**.

---

## Product Mapping & Alignment

| Donation Tier | iOS Product ID | Android Product ID | Billing Period | Price | Characters |
|---|---|---|---|---|---|
| Tier 1 (Small) | `com.shamelagpt.ios.donation.1monthly` | `com.shamelagpt.android.donation.1monthly` | 1 month | $1.00 USD | 40 ✓ |
| Tier 2 (Medium) | `com.shamelagpt.ios.donation.5monthly` | `com.shamelagpt.android.donation.5monthly` | 1 month | $5.00 USD | 40 ✓ |
| Tier 3 (Large) | `com.shamelagpt.ios.donation.10monthly` | `com.shamelagpt.android.donation.10month` | 1 month | $10.00 USD | 39 ✓ |
| Tier 4 (Annual) | `com.shamelagpt.ios.donation.100yearly` | `com.shamelagpt.android.donation.100year` | 1 year | $100.00 USD | 39 ✓ |

**Notes**:
- All product IDs ≤40 characters (Google Play limit)
- Pricing is identical across platforms
- Naming convention: `com.{platform}.donation.{amount}{period}`

---

## Implementation Status

### iOS (StoreKit 2)
**Location**: [DonationViewModel.swift](../../shamelagpt-ios/shamelagpt/Presentation/Scenes/Settings/DonationViewModel.swift#L15)

```swift
static let productIDs: [String] = [
    "com.shamelagpt.ios.donation.1monthly",
    "com.shamelagpt.ios.donation.5monthly",
    "com.shamelagpt.ios.donation.10monthly",
    "com.shamelagpt.ios.donation.100yearly"
]
```

**Status**: ✅ Implemented
**Testing**: Via App Store Connect Sandbox

---

### Android (Google Play Billing)
**Location**: [DonationViewModel.kt](../../shamelagpt-android/app/src/main/java/com/shamelagpt/android/presentation/settings/DonationViewModel.kt#L161)

```kotlin
companion object {
    val productIds = listOf(
        "com.shamelagpt.android.donation.1monthly",
        "com.shamelagpt.android.donation.5monthly",
        "com.shamelagpt.android.donation.10month",
        "com.shamelagpt.android.donation.100year"
    )
}
```

**Status**: ✅ Implemented
**Testing**: Via Google Play Console License Testing

---

## Configuration Verification

### App Store Connect (iOS)
**Navigate**: App Store Connect → ShamelaGPT → In-App Purchases

- [ ] ✅ `com.shamelagpt.ios.donation.1monthly` — Active
- [ ] ✅ `com.shamelagpt.ios.donation.5monthly` — Active
- [ ] ✅ `com.shamelagpt.ios.donation.10monthly` — Active
- [ ] ✅ `com.shamelagpt.ios.donation.100yearly` — Active

**Pricing**: All matched to USD base prices
**Renewal**: Annual renews yearly, others renew monthly

---

### Google Play Console (Android)
**Navigate**: Play Console → ShamelaGPT → Monetization → Products → Subscriptions

- [ ] ✅ `com.shamelagpt.android.donation.1monthly` — Active
- [ ] ✅ `com.shamelagpt.android.donation.5monthly` — Active
- [ ] ✅ `com.shamelagpt.android.donation.10month` — Active
- [ ] ✅ `com.shamelagpt.android.donation.100year` — Active

**Pricing**: All matched to USD base prices
**Renewal**: Annual renews yearly, others renew monthly

---

## User Experience Parity

### iOS Flow
1. **Settings → Support / Donate**
2. Products load from App Store Connect
3. User selects a donation tier
4. StoreKit billing sheet appears
5. User completes payment (or test purchase)
6. Purchase acknowledged, active donation shown

**Code**: [DonationView.swift](../../shamelagpt-ios/shamelagpt/Presentation/Scenes/Settings/DonationView.swift)

---

### Android Flow
1. **Settings → Donate**
2. Products load from Google Play Billing
3. User selects a donation tier
4. Google Play billing sheet appears
5. User completes payment (or test purchase)
6. Purchase acknowledged, active donation shown

**Code**: [DonationSheet.kt](../../shamelagpt-android/app/src/main/java/com/shamelagpt/android/presentation/settings/DonationSheet.kt)

---

## Testing Parity

### Test Account Setup

**iOS**:
- Go to **Settings > App Store > Sandbox Account**
- Use test account from App Store Connect
- Sandbox purchases do NOT charge

**Android**:
- Go to **Settings > License Testing** in Play Console
- Add test accounts (e.g., your dev email)
- Test purchases do NOT charge

---

### Test Scenarios (Both Platforms)

1. **Product Loading**
   - Open Donate screen
   - Verify all 4 products load with correct names and prices
   - Logcat/Console: Check for no errors

2. **Purchase Flow**
   - Select a donation tier
   - Billing sheet appears
   - Product details match (name, price)
   - Complete purchase flow

3. **Active Donation Display**
   - Close and reopen app
   - Active donation should persist
   - UI shows current subscription status

4. **Subscription Cancellation**
   - Via App Store (iOS) or Google Play (Android)
   - Reopen app
   - Donation status should clear

---

## Reference: Naming Conventions

### Why Different Suffixes?

| Tier | iOS | Android | Reason |
|---|---|---|---|
| $1 & $5 | `{amount}monthly` | `{amount}monthly` | Consistent 30-day billing |
| $10 | `10monthly` | `10month` | Minor length optimization (fits 40-char limit) |
| $100 | `100yearly` | `100year` | Single annual billing |

**Decision**: Keep `monthly` consistent for $1 & $5; use `month` and `year` abbreviations only where needed to stay under 40-character limit.

---

## Known Differences (Platform-Required)

| Aspect | iOS | Android | Reason |
|---|---|---|---|
| **Billing System** | StoreKit 2 | Google Play Billing v8+ | Native platform requirements |
| **Purchase Flow** | In-app modal | In-app modal | Platform UI standards |
| **Renewal** | Auto-renewal consent form | Auto-renewal opt-in | Platform policy |
| **Cancellation** | Via Settings app | Via Play Store or app | Platform workflow |
| **Server Sync** | Server-side verification | Server-side verification | Security best practice |

---

## Support & Troubleshooting

### iOS Issues
- See: [TROUBLESHOOTING_IOS.md](./TROUBLESHOOTING_IOS.md)
- Reference: [DonationViewModelTests.swift](../../shamelagpt-ios/shamelagptTests/DonationViewModelTests.swift)

### Android Issues
- See: [TROUBLESHOOTING_ANDROID.md](./TROUBLESHOOTING_ANDROID.md)
- Reference: [DonationViewModelTest.kt](../../shamelagpt-android/app/src/test/java/com/shamelagpt/android/presentation/settings/DonationViewModelTest.kt)
- Setup: [GOOGLE_PLAY_BILLING_SETUP.md](./GOOGLE_PLAY_BILLING_SETUP.md)

---

## Parity Checklist (Pre-Release)

- [ ] iOS product IDs all configured and active in App Store Connect
- [ ] Android product IDs all configured and active in Google Play Console
- [ ] Prices match exactly across platforms ($1, $5, $10, $100)
- [ ] Billing periods match (monthly for $1/$5/$10, yearly for $100)
- [ ] Test purchases work on both platforms
- [ ] Active subscriptions persist after app restart (both)
- [ ] Cancellation updates UI correctly (both)
- [ ] Error states handled gracefully (both)
- [ ] Logcat/Console shows no billing-related crashes
- [ ] Release notes document donation feature for both platforms

---

## Future Considerations

- [ ] Server-side subscription status verification
- [ ] Cross-platform subscription management (web dashboard)
- [ ] Custom billing periods or flexible tiers
- [ ] Promotional offers or discounts
- [ ] Subscription tier-based features (if monetized)

---

**Last Verified**: 2026-05-20
**Next Review**: After production release
