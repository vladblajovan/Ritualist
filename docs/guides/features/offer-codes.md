# Offer Codes System

**Last Updated:** 2025-11-19
**Status:** Phase 3 Complete (UI/UX) - Phase 4 Blocked (Production requires Apple Developer Program)

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Offer Code Types](#offer-code-types)
4. [Shared Features](#shared-features)
5. [Redemption Flows](#redemption-flows)
6. [Code Examples](#code-examples)
7. [Testing](#testing)
8. [Production Setup](#production-setup)

---

## Overview

The Ritualist offer codes system provides a flexible promotional framework for subscription products, supporting:

- **Free Trials** - Grant immediate subscription access
- **Discount Vouchers** - Apply price reductions at purchase time
- **Upgrade Codes** - Grant access to premium tiers

### Key Capabilities

✅ **Flexible Expiration** - Optional expiration dates
✅ **Usage Limits** - Track and limit total redemptions
✅ **Eligibility Rules** - Restrict to new subscribers
✅ **Product Targeting** - Each code tied to specific product
✅ **Discount Configuration** - Percentage or fixed amount discounts
✅ **Duration Control** - Apply discounts for N billing cycles

---

## Architecture

### Entity Structure

All offer codes use the unified `OfferCode` entity:

```swift
public struct OfferCode: Identifiable, Codable, Equatable {
    // Core Properties
    let id: String                    // Code users enter (e.g., "RITUALIST2025")
    let displayName: String           // Internal reference name
    let productId: String             // StoreKit product ID
    let offerType: OfferType          // .freeTrial, .discount, or .upgrade

    // Optional Features
    let discount: OfferDiscount?      // Discount config (for .discount type only)
    let expirationDate: Date?         // Code becomes invalid after this date
    let isActive: Bool                // Admin can deactivate without deleting

    // Eligibility & Limits
    let isNewSubscribersOnly: Bool    // Restrict to first-time subscribers
    let maxRedemptions: Int?          // Total allowed uses (nil = unlimited)
    var redemptionCount: Int          // Current usage count
}
```

### Validation Logic

All codes share the same validation:

```swift
var isValid: Bool {
    isActive &&                    // Not deactivated by admin
    !isExpired &&                  // Hasn't passed expiration date
    !isRedemptionLimitReached      // Hasn't hit max uses
}
```

---

## Offer Code Types

### 1. Free Trial Codes (`.freeTrial`)

**Purpose:** Grant immediate subscription access without payment.

**Configuration:**
```swift
OfferCode(
    id: "RITUALIST2025",
    displayName: "Launch Promo 2025",
    productId: StoreKitProductID.annual,
    offerType: .freeTrial,
    expirationDate: Date().addingTimeInterval(90 * 24 * 60 * 60),  // 90 days
    isNewSubscribersOnly: true
)
```

**Redemption Behavior:**
- ✅ Grants subscription immediately
- ✅ User gets premium features right away
- ❌ No discount configuration needed
- ❌ No ActiveDiscount stored

**Use Cases:**
- Onboarding promotions
- Influencer partnerships
- Marketing campaigns
- Beta tester access

---

### 2. Discount Vouchers (`.discount`)

**Purpose:** Apply price reduction when user purchases.

**Configuration:**
```swift
OfferCode(
    id: "WELCOME50",
    displayName: "Welcome 50% Off",
    productId: StoreKitProductID.monthly,
    offerType: .discount,
    discount: OfferDiscount(
        type: .percentage,     // or .fixed
        value: 50,             // 50% or $50
        duration: 3            // billing cycles (nil for one-time)
    ),
    expirationDate: Date().addingTimeInterval(60 * 24 * 60 * 60)  // 60 days
)
```

**Discount Types:**

**Percentage Discount:**
```swift
OfferDiscount(type: .percentage, value: 50, duration: 3)
// Result: 50% off for first 3 billing cycles
```

**Fixed Amount Discount:**
```swift
OfferDiscount(type: .fixed, value: 20.00, duration: nil)
// Result: $20 off (one-time for lifetime purchases)
```

**Redemption Behavior:**
- ❌ Does NOT grant subscription immediately
- ✅ Stores `ActiveDiscount` (valid for 24 hours)
- ✅ Shows discount in UI (banner, pricing)
- ✅ Applied when user purchases
- ✅ Cleared after successful purchase

**Use Cases:**
- Flash sales
- Seasonal promotions
- Retention offers
- Referral rewards

---

### 3. Upgrade Codes (`.upgrade`)

**Purpose:** Grant immediate access to premium tier.

**Configuration:**
```swift
OfferCode(
    id: "GOUPGRADE",
    displayName: "Instant Annual Upgrade",
    productId: StoreKitProductID.annual,
    offerType: .upgrade
)
```

**Redemption Behavior:**
- ✅ Grants subscription immediately
- ✅ Typically upgrades to higher tier
- ❌ No discount configuration needed

**Use Cases:**
- Special upgrade promotions
- Bundle deals
- Loyalty rewards

---

## Shared Features

### Feature Matrix

| Feature | Free Trial | Discount | Upgrade |
|---------|-----------|----------|---------|
| **Grants immediate subscription** | ✅ Yes | ❌ No | ✅ Yes |
| **Stores ActiveDiscount** | ❌ No | ✅ Yes | ❌ No |
| **Shows in UI before purchase** | ❌ No | ✅ Yes | ❌ No |
| **Has discount config** | ❌ No | ✅ Yes | ❌ No |
| **Expiration date** | ✅ Optional | ✅ Optional | ✅ Optional |
| **Max redemptions** | ✅ Optional | ✅ Optional | ✅ Optional |
| **New subscribers only** | ✅ Optional | ✅ Optional | ✅ Optional |
| **Redemption tracking** | ✅ Yes | ✅ Yes | ✅ Yes |

### Expiration Dates

All code types support optional expiration:

```swift
// Expires in 90 days
expirationDate: Date().addingTimeInterval(90 * 24 * 60 * 60)

// Never expires
expirationDate: nil
```

### Redemption Limits

All code types support usage limits:

```swift
// Limited to 100 uses
maxRedemptions: 100
redemptionCount: 0  // Tracks current usage

// Unlimited uses
maxRedemptions: nil
```

### Eligibility Rules

All code types support subscriber restrictions:

```swift
// Only new subscribers can redeem
isNewSubscribersOnly: true

// Any user can redeem
isNewSubscribersOnly: false
```

---

## Redemption Flows

### Free Trial / Upgrade Flow (One-Phase)

```
┌─────────────────────────────────────┐
│ User enters code "RITUALIST2025"    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Validate code                       │
│ - Is active?                        │
│ - Not expired?                      │
│ - Not at limit?                     │
│ - User eligible?                    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Grant Subscription Immediately      │
│ subscriptionService.mockPurchase()  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ User is Premium ✅                  │
│ DONE                                │
└─────────────────────────────────────┘
```

### Discount Voucher Flow (Two-Phase)

```
Phase 1: Redemption
┌─────────────────────────────────────┐
│ User enters code "WELCOME50"        │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Validate code                       │
│ - Is active?                        │
│ - Not expired?                      │
│ - Not at limit?                     │
│ - User eligible?                    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Store ActiveDiscount                │
│ activeDiscountService.set()         │
│ (Valid for 24 hours)                │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Show Discount in UI                 │
│ - Banner: "50% OFF applied!"        │
│ - Pricing: ~~$9.99~~ $4.99          │
│ - Badge: "Save $5.00"               │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ User browses products               │
│ (User still FREE at this point)     │
└──────────────┬──────────────────────┘
               │
               │
Phase 2: Purchase
               │
               ▼
┌─────────────────────────────────────┐
│ User clicks "Purchase"              │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Check for ActiveDiscount            │
│ discount = getActiveDiscount()      │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Apply Discount to Price             │
│ $9.99 → $4.99                       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Process Purchase                    │
│ subscriptionService.mockPurchase()  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Clear ActiveDiscount                │
│ activeDiscountService.clear()       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ User is Premium ✅                  │
│ DONE                                │
└─────────────────────────────────────┘
```

---

## Code Examples

### Redeeming a Code

```swift
// User enters code
let codeId = "WELCOME50"

do {
    // Redeem through paywall service
    let success = try await paywallService.redeemOfferCode(codeId)

    if success {
        // Check redemption state
        switch paywallService.offerCodeRedemptionState {
        case .success(let code, let productId):
            print("✅ Redeemed: \(code) for \(productId)")

        case .failed(let message):
            print("❌ Failed: \(message)")

        case .validating:
            print("⏳ Validating...")

        case .redeeming:
            print("⏳ Redeeming...")

        case .idle:
            break
        }
    }
} catch {
    // Handle specific errors
    switch error as? PaywallError {
    case .offerCodeExpired:
        print("Code has expired")

    case .offerCodeRedemptionLimitReached:
        print("Code has reached its redemption limit")

    case .offerCodeAlreadyRedeemed:
        print("You've already redeemed this code")

    case .offerCodeNotEligible:
        print("You're not eligible for this offer")

    case .offerCodeInvalid:
        print("Invalid code")

    default:
        print("Redemption failed: \(error)")
    }
}
```

### Checking for Active Discounts

```swift
// Check if product has active discount
let product = Product(id: StoreKitProductID.monthly, ...)

if let discount = await paywallService.getActiveDiscount(for: product.id) {
    // Calculate discounted price
    let originalPrice = 9.99
    let discountedPrice = discount.calculateDiscountedPrice(originalPrice)

    // Display in UI
    print("Original: $\(originalPrice)")
    print("Discounted: $\(discountedPrice)")
    print("Save: $\(originalPrice - discountedPrice)")

    // Get discount description
    switch discount.discountType {
    case .percentage:
        print("\(Int(discount.discountValue))% OFF")
    case .fixed:
        print("$\(discount.discountValue) OFF")
    }
}
```

### Creating Test Codes

```swift
// Free trial code
let freeTrial = OfferCode(
    id: "TRIAL7DAY",
    displayName: "7-Day Free Trial",
    productId: StoreKitProductID.annual,
    offerType: .freeTrial,
    expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
    isNewSubscribersOnly: true
)

// Percentage discount code
let percentageDiscount = OfferCode(
    id: "SUMMER30",
    displayName: "Summer 30% Off",
    productId: StoreKitProductID.monthly,
    offerType: .discount,
    discount: OfferDiscount(
        type: .percentage,
        value: 30,
        duration: 6  // First 6 months
    ),
    maxRedemptions: 500
)

// Fixed discount code
let fixedDiscount = OfferCode(
    id: "LIFETIME20",
    displayName: "Lifetime $20 Off",
    productId: StoreKitProductID.lifetime,
    offerType: .discount,
    discount: OfferDiscount(
        type: .fixed,
        value: 20.00,
        duration: nil  // One-time purchase
    )
)
```

---

## Testing

### Default Test Codes

The system includes several test codes in `MockOfferCodeStorageService`:

| Code | Type | Details |
|------|------|---------|
| `RITUALIST2025` | Free Trial | Annual, 90-day expiry, new subscribers only |
| `WELCOME50` | Discount | 50% off monthly for 3 cycles, 60-day expiry |
| `ANNUAL30` | Discount | 30% off annual for 1 cycle, max 100 uses |
| `LIFETIME20` | Discount | $20 off lifetime, 30-day expiry |
| `EXPIRED2024` | Free Trial | Expired (for testing error handling) |
| `LIMITREACHED` | Discount | At redemption limit (for testing limits) |
| `INACTIVE2025` | Discount | Inactive (for testing inactive state) |

### Running Tests

```bash
# Run all offer code tests
xcodebuild test -scheme Ritualist -only-testing:RitualistTests/OfferCodeTests

# Run specific test suites
xcodebuild test -scheme Ritualist -only-testing:RitualistTests/MockPaywallServiceTests
xcodebuild test -scheme Ritualist -only-testing:RitualistTests/DiscountVoucherFlowTests
```

**Test Coverage:**
- ✅ 69 total tests passing
- ✅ 22 OfferCode entity tests
- ✅ 14 MockPaywallService tests
- ✅ 9 Discount voucher flow tests
- ✅ 24 Offer code storage tests

---

## Production Setup

### Phase 4: StoreKit Integration (Blocked)

**Status:** 🔒 Awaiting Apple Developer Program

**Requirements:**
1. ✅ Active Apple Developer Program membership
2. ✅ Promotional offers configured in App Store Connect
3. ✅ Test codes created and activated

**Implementation Tasks:**

#### 1. Keychain Storage Service

Create secure production storage:

```swift
public final class KeychainActiveDiscountService: ActiveDiscountService {
    // Store ActiveDiscount securely in Keychain
    // Validate discount hasn't been tampered with
    // Encrypt discount data
}
```

#### 2. StoreKit Promotional Offers

Update `StoreKitPaywallService.purchase()`:

```swift
// Check for active discount
if let discount = await getActiveDiscount(for: product.id) {
    // Apply promotional offer to StoreKit purchase
    let options = Product.PurchaseOption.promotionalOffer(
        offerID: discount.codeId,
        keyID: "YOUR_KEY_ID",
        nonce: UUID(),
        signature: signature,
        timestamp: Date().timeIntervalSince1970
    )

    let result = try await product.purchase(options: options)

    // Clear discount after successful purchase
    await clearActiveDiscount()
}
```

#### 3. App Store Connect Configuration

**Step 1:** Create promotional offers
1. Navigate to App Store Connect → In-App Purchases
2. Select your subscription product
3. Click "Add Promotional Offer"
4. Configure:
   - Reference name (e.g., "Welcome 50% Off")
   - Offer code prefix (e.g., "WELCOME")
   - Discount type (percentage/fixed)
   - Duration (1-12 billing cycles)
   - Eligibility (new/existing/all users)

**Step 2:** Generate promotional codes
1. Click "Promotional Codes" in App Store Connect
2. Create new code batch
3. Set active dates
4. Download code list
5. Distribute to users

#### 4. Testing in Production

**StoreKit Configuration File:**
Update `Ritualist.storekit` with promotional offers for local testing.

**TestFlight:**
1. Build with production StoreKit service
2. Upload to TestFlight
3. Test real promotional codes
4. Verify transactions process correctly
5. Test edge cases (expired, invalid, wrong product)

---

## Related Documentation

- **Implementation Plan:** `plans/discount-voucher-implementation-plan.md`
- **Offer Codes Plan:** `plans/offer-codes-implementation-plan.md`
- **StoreKit Setup:** `docs/guides/features/storekit-setup.md`
- **Testing Guide:** `docs/guides/testing/OFFER-CODE-TESTING-GUIDE.md`

---

## Troubleshooting

### Common Issues

**"Code not found"**
- Check code ID case (matching is case-insensitive but code must exist)
- Verify code exists in storage
- Check if code was deleted

**"Code has expired"**
- Verify `expirationDate` hasn't passed
- Update expiration date if needed

**"Code has reached limit"**
- Check `redemptionCount` vs `maxRedemptions`
- Increase limit or create new code

**"Not eligible for this offer"**
- Check `isNewSubscribersOnly` setting
- Verify user's subscription history

**"Discount not showing in UI"**
- Verify code is `.discount` type (not `.freeTrial`)
- Check ActiveDiscount hasn't expired (24-hour window)
- Ensure PaywallViewModel loaded discounts

---

**Document Version:** 1.0
**Created:** 2025-11-19
**Author:** Claude Code
