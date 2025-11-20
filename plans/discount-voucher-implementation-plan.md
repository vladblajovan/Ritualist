# Discount Voucher Implementation Plan

**Goal:** Extend offer code system to support discount vouchers that reduce purchase price (separate from free trial codes that grant immediate subscriptions).

**Timeline:** 8-12 hours

**Status:** 🟢 Phase 3 Complete (3/4 phases done)

**Progress:**
- ✅ Phase 1: Backend Infrastructure (Complete)
- ✅ Phase 2: Service Layer & Testing (Complete)
- ✅ Phase 3: UI/UX Integration (Complete)
- 🔒 Phase 4: Production StoreKit Integration (Blocked - Awaiting Apple Developer Program)

---

## Overview

### What are Discount Vouchers?

Discount vouchers are a specific type of offer code that:
- **Store discount information** when redeemed (don't grant immediate access)
- **Apply discount at purchase time** (reduce the displayed price)
- **Support multiple discount types:** percentage off, fixed amount off
- **Have duration limits:** apply for N billing cycles or one-time

**Key Difference from Free Trial Codes:**
- ❌ Free Trial: Redeem → Immediate subscription access
- ✅ Discount: Redeem → Store discount → Purchase with discount → Grant subscription

### Technical Architecture

**New Components:**
1. **ActiveDiscount** entity - Stores discount details between redemption and purchase
2. **ActiveDiscountService** - Manages discount state lifecycle
3. **Purchase flow updates** - Check for active discount, apply pricing, clear after purchase
4. **UI updates** - Show discounted pricing, savings badges, promotional messaging

---

## Phase 1: Backend Infrastructure ✅

**Duration:** 2-3 hours
**Status:** ✅ Complete
**PR:** #61 (Offer Codes - Basic Infrastructure)

### Tasks Completed

- [x] **Extend OfferCode entity**
  - Location: `RitualistCore/Sources/RitualistCore/Entities/Paywall/OfferCode.swift`
  - Added `OfferType` enum: `.freeTrial`, `.discount`, `.upgrade`
  - Added `OfferDiscount` nested struct with:
    - `type`: `.percentage` or `.fixed`
    - `value`: discount amount (50 for 50%, or 20.00 for $20)
    - `duration`: billing cycles (nil for one-time purchases)
  - Added `discount` property (optional)

- [x] **Update default test codes**
  - Location: `MockOfferCodeStorageService.swift`
  - Added `WELCOME50`: 50% off monthly for 3 cycles
  - Added `ANNUAL30`: 30% off annual for 1 cycle
  - Added `LIFETIME20`: $20 off lifetime (one-time)

### Files Modified (2)
```
RitualistCore/Sources/RitualistCore/
├── Entities/Paywall/
│   └── OfferCode.swift [+OfferType enum, +OfferDiscount struct]
└── Services/
    └── MockOfferCodeStorageService.swift [+3 discount test codes]
```

---

## Phase 2: Service Layer & Testing ✅

**Duration:** 4-5 hours
**Status:** ✅ Complete
**Completed:** 2025-11-19

### Tasks Completed

#### 2.1: ActiveDiscount Service

- [x] **Create ActiveDiscountService.swift**
  - Location: `RitualistCore/Sources/RitualistCore/Services/ActiveDiscountService.swift`
  - **ActiveDiscount entity:**
    - Properties: codeId, productId, discountType, discountValue, duration
    - Timestamps: redeemedAt, expiresAt (24hr default)
    - Methods: `calculateDiscountedPrice()`, `isValid`, `displayString`
  - **ActiveDiscountService protocol:**
    - `setActiveDiscount(_:)` - Store discount after redemption
    - `getActiveDiscount(for:)` - Retrieve discount for product
    - `clearActiveDiscount()` - Clear after purchase
    - `hasActiveDiscount(for:)` - Check if discount exists
  - **MockActiveDiscountService implementation:**
    - Uses UserDefaults for storage
    - Auto-expires after 24 hours
    - Cleanup on initialization

#### 2.2: PaywallService Updates

- [x] **Update MockPaywallService.redeemOfferCode()**
  - Location: `RitualistCore/Sources/RitualistCore/Services/PaywallService.swift:406`
  - Added offer type differentiation:
    ```swift
    switch offerCode.offerType {
    case .freeTrial, .upgrade:
        // Grant immediate subscription
        try await subscriptionService.mockPurchase(productId)
    case .discount:
        // Store discount for later
        let activeDiscount = ActiveDiscount(...)
        try await activeDiscountService.setActiveDiscount(activeDiscount)
    }
    ```

- [x] **Update MockPaywallService.purchase()**
  - Location: `RitualistCore/Sources/RitualistCore/Services/PaywallService.swift:201`
  - Check for active discount before purchase
  - Clear discount after successful purchase
  - Calculate discounted price (for future UI display)

- [x] **Add discount methods to PaywallService protocol**
  - `getActiveDiscount(for:) async -> ActiveDiscount?`
  - `hasActiveDiscount(for:) async -> Bool`
  - `clearActiveDiscount() async`

- [x] **Update NoOpPaywallService**
  - Return `nil` for discount methods
  - Maintain protocol conformance

#### 2.3: StoreKit Service Stubs

- [x] **Add stub methods to StoreKitPaywallService**
  - Location: `Ritualist/Core/Services/StoreKitPaywallService.swift:250`
  - `getActiveDiscount(for:)` - Returns nil (TODO for Phase 4)
  - `hasActiveDiscount(for:)` - Returns false (TODO for Phase 4)
  - `clearActiveDiscount()` - No-op (TODO for Phase 4)
  - Added documentation for future implementation

#### 2.4: Test Infrastructure & Race Condition Fixes

- [x] **Refactor mock services to accept UserDefaults**
  - `MockOfferCodeStorageService(userDefaults:)` - Isolated storage
  - `MockActiveDiscountService(userDefaults:)` - Isolated storage
  - `MockSecureSubscriptionService(userDefaults:)` - Isolated storage
  - Default parameter: `.standard` (backward compatible)

- [x] **Update test helpers with isolated UserDefaults**
  - `DiscountVoucherFlowTests` - Uses `UserDefaults(suiteName: "DiscountVoucherFlowTests")`
  - `MockPaywallServiceTests` - Uses `UserDefaults(suiteName: "MockPaywallServiceTests")`
  - `MockOfferCodeStorageServiceTests` - Uses `UserDefaults(suiteName: "MockOfferCodeStorageServiceTests")`
  - Each suite clears domain on initialization: `removePersistentDomain(forName:)`

- [x] **Add .serialized to test suites**
  - Prevents intra-suite race conditions
  - Allows inter-suite parallel execution
  - Best of both worlds: speed + reliability

#### 2.5: Comprehensive Test Suite

- [x] **Create DiscountVoucherFlowTests.swift** (9 tests)
  - Location: `RitualistTests/Core/Services/DiscountVoucherFlowTests.swift`
  - **Discount Code Redemption Tests (2):**
    - `redeemDiscountCode_storesActiveDiscount_doesNotGrantSubscription`
    - `redeemDiscountCode_storesCorrectDiscountDetails`
  - **Purchase with Discount Tests (2):**
    - `purchaseWithActiveDiscount_clearsDiscount`
    - `purchaseWithoutDiscount_succeeds`
  - **Complete Flow Tests (2):**
    - `completeDiscountFlow_worksEndToEnd`
    - `discountForWrongProduct_doesNotAffectPurchase`
  - **Price Calculation Tests (3):**
    - `activeDiscount_calculatesPercentageCorrectly`
    - `activeDiscount_calculatesFixedCorrectly`
    - `activeDiscount_neverProducesNegativePrice`

- [x] **Fix existing tests for discount differentiation**
  - Updated `MockPaywallServiceTests` (2 tests fixed)
  - Changed to explicitly look for `.freeTrial` codes (not just any valid code)
  - Added fallback to `.upgrade` codes for flexibility

### Test Results ✅

**Total Test Count: 69 tests**
- ✅ DiscountVoucherFlowTests: 9/9 passing
- ✅ MockOfferCodeStorageServiceTests: 24/24 passing
- ✅ MockPaywallServiceTests: 14/14 passing
- ✅ OfferCodeTests: 22/22 passing

**Test Isolation:** ✅ All tests pass when run individually, per-suite, or all together (no race conditions!)

### Files Created (2)
```
RitualistCore/Sources/RitualistCore/Services/
└── ActiveDiscountService.swift [NEW - 240 lines]

RitualistTests/Core/Services/
└── DiscountVoucherFlowTests.swift [NEW - 312 lines, 9 tests]
```

### Files Modified (6)
```
RitualistCore/Sources/RitualistCore/Services/
├── PaywallService.swift [+discount differentiation, +3 protocol methods]
├── MockOfferCodeStorageService.swift [+userDefaults parameter]
├── MockActiveDiscountService.swift [+userDefaults parameter]
└── MockSecureSubscriptionService.swift [+userDefaults parameter]

Ritualist/Core/Services/
└── StoreKitPaywallService.swift [+stub discount methods]

RitualistTests/Core/Services/
├── DiscountVoucherFlowTests.swift [+isolated UserDefaults, +.serialized]
├── MockPaywallServiceTests.swift [+isolated UserDefaults, +.serialized, 2 tests fixed]
└── MockOfferCodeStorageServiceTests.swift [+isolated UserDefaults, +.serialized]
```

---

## Phase 3: UI/UX Integration ✅

**Duration:** 3-4 hours
**Status:** ✅ Complete
**Completed:** 2025-11-19

### Tasks Completed

#### 3.1: PaywallView Updates

- [x] **Add discount banner section**
  - Location: `Ritualist/Features/Paywall/Presentation/PaywallView.swift:228-236`
  - Shows when active discount exists for selected product
  - Displays: "Discount Applied! 🎉 Code: WELCOME50"
  - Prominent card with green gradient background
  - Party popper icon for visual appeal

- [x] **Update product pricing display**
  - Shows original price with strike-through + discounted price
  - Adds "Save $X" badge in green
  - Example: ~~$9.99~~ **$4.99** (Save $5.00!)
  - Location: `PricingCard` component (lines 594-628)

- [x] **Update purchase button text**
  - Without discount: "Start Free Trial" or "Purchase"
  - With discount: "Get Monthly - $4.99" (shows discounted price)
  - Location: `purchaseButtonText` computed property (lines 409-428)

- [x] **Discount redemption flow**
  - Uses existing offer code sheet (already implemented in Phase 1)
  - Validation feedback handled by `offerCodeRedemptionState`
  - Success state automatically shows discount in UI

#### 3.2: PaywallViewModel Updates

- [x] **Add discount state properties**
  - `activeDiscounts: [String: ActiveDiscount]` - Stores discounts per product
  - Computed property: `hasActiveDiscountForSelectedProduct: Bool`
  - Computed property: `activeDiscountForSelectedProduct: ActiveDiscount?`
  - Location: `PaywallViewModel.swift:55-70`

- [x] **Add discount management methods**
  - `loadActiveDiscounts()` - Loads discounts for all products
  - `getActiveDiscount(for:)` - Gets discount for specific product
  - `getDiscountedPrice(for:)` - Calculates discounted price
  - `clearActiveDiscount()` - Clears discount after purchase
  - Location: `PaywallViewModel.swift:277-321`

#### 3.3: Discount UI Components

- [x] **Create DiscountBadge component**
  - Shows "50% OFF" or "$20 OFF" in green capsule
  - Green-to-mint gradient background
  - Tag icon for visual recognition
  - Location: `PaywallView.swift:414-451`

- [x] **Create DiscountBannerCard component**
  - Full-width banner with party popper icon
  - Shows discount badge and code ID
  - Green gradient border and background
  - Shadow effect for prominence
  - Location: `PaywallView.swift:453-512`

- [x] **Update PricingCard display**
  - Added discount badge in header (next to product name)
  - Shows original price with red strike-through
  - Displays discounted price in green
  - Calculates and shows "Save $X" text
  - Location: `PricingCard` component (lines 527-684)

### Files Modified (2)
```
Ritualist/Features/Paywall/Presentation/
├── PaywallView.swift [+DiscountBadge, +DiscountBannerCard, updated PricingCard]
└── PaywallViewModel.swift [+discount properties & methods]
```

### Build Status ✅
- **BUILD SUCCEEDED**
- All discount UI code compiles successfully
- SwiftLint warnings (type body length) - acceptable

---

## Phase 4: Production StoreKit Integration 🔒

**Duration:** 2-3 hours
**Status:** 🔒 Blocked - Awaiting Apple Developer Program
**Note:** This phase will be implemented once the Apple Developer Program is purchased and active. All infrastructure is in place for a smooth transition.

### Prerequisites (Blocked)

- [ ] ⏸️ Apple Developer Program active (**REQUIRED**)
- [ ] ⏸️ Promotional offers configured in App Store Connect
- [ ] ⏸️ Test codes created and active

### Tasks

#### 4.1: StoreKit Service Implementation

- [ ] **Implement ActiveDiscountService for production**
  - Create `KeychainActiveDiscountService` (more secure than UserDefaults)
  - Store encrypted discount data
  - Validate discount hasn't been tampered with

- [ ] **Update StoreKitPaywallService.purchase()**
  - Check for active discount
  - Apply promotional offer code to StoreKit purchase
  - Use `product.purchase(options: .promotionalOffer(...))`
  - Clear discount after successful purchase

- [ ] **Implement discount methods**
  - `getActiveDiscount(for:)` - Retrieve from Keychain
  - `hasActiveDiscount(for:)` - Check existence
  - `clearActiveDiscount()` - Remove from Keychain

#### 4.2: App Store Connect Configuration

- [ ] **Create promotional offers**
  - Navigate to App Store Connect → In-App Purchases
  - Create promotional offers with:
    - Reference name
    - Offer code prefix
    - Discount type (percentage/fixed)
    - Duration (1-12 billing cycles)
    - Eligibility (new/existing/all users)

- [ ] **Generate promotional codes**
  - Create codes: WELCOME50, ANNUAL30, etc.
  - Set active dates
  - Download code list
  - Distribute to users

#### 4.3: Testing & Validation

- [ ] **Test with StoreKit configuration**
  - Update `Ritualist.storekit` with promotional offers
  - Test redemption → purchase flow locally
  - Verify discount application

- [ ] **TestFlight testing**
  - Build with production StoreKit service
  - Test real promotional codes
  - Verify transactions process correctly
  - Test edge cases (expired, invalid, wrong product)

### Files to Create (1)
```
RitualistCore/Sources/RitualistCore/Services/
└── KeychainActiveDiscountService.swift [NEW]
```

### Files to Modify (1)
```
Ritualist/Core/Services/
└── StoreKitPaywallService.swift [+production discount implementation]
```

---

## Implementation Notes

### Key Design Decisions

**1. Two-Phase Redemption:**
- Phase 1: Redeem code → Store ActiveDiscount
- Phase 2: Purchase → Apply discount → Clear ActiveDiscount
- **Why:** Allows users to browse products with discount applied, decide later

**2. Discount Expiration:**
- Default: 24 hours after redemption
- **Why:** Creates urgency, prevents indefinite storage

**3. Product-Specific Discounts:**
- Discount tied to specific product ID
- Prevents applying monthly discount to annual product
- **Why:** Matches App Store Connect promotional offer constraints

**4. Test Isolation Pattern:**
- Each test suite uses isolated UserDefaults
- `.serialized` within each suite
- Parallel execution across suites
- **Why:** Eliminates race conditions while maintaining performance

### Common Patterns

**Checking for Discount:**
```swift
if let discount = await paywallService.getActiveDiscount(for: product.id) {
    let originalPrice = 9.99
    let discountedPrice = discount.calculateDiscountedPrice(originalPrice)
    // Show UI: $9.99 → $4.99 (Save $5!)
}
```

**Redeeming Discount Code:**
```swift
// Redeem code (stores discount, doesn't grant subscription)
try await paywallService.redeemOfferCode("WELCOME50")

// Later, during purchase...
let result = try await paywallService.purchase(product)
// Discount automatically applied and cleared
```

**Clearing Discount:**
```swift
await paywallService.clearActiveDiscount()
```

### Testing Strategy

**Unit Tests:**
- ✅ 9 discount voucher flow tests
- ✅ Price calculation validation
- ✅ Redemption flow validation
- ✅ Cross-product discount isolation

**Integration Tests:**
- Phase 3: UI tests with mocked discount state
- Phase 4: End-to-end tests with StoreKit

**Manual Testing:**
- Debug menu for offline testing
- StoreKit configuration for local testing
- TestFlight for production validation

---

## Progress Tracking

### Phase 1: Backend Infrastructure ✅
- [x] Extend OfferCode entity (1 file)
- [x] Add discount test codes (1 file)

**Total: 2/2 tasks complete** ✅
**PR:** #61

### Phase 2: Service Layer & Testing ✅
- [x] Create ActiveDiscountService (1 file)
- [x] Update PaywallService redemption logic (1 file)
- [x] Update PaywallService purchase logic (1 file)
- [x] Add StoreKit service stubs (1 file)
- [x] Refactor services for test isolation (3 files)
- [x] Create comprehensive test suite (1 file, 9 tests)
- [x] Fix existing tests (1 file, 2 tests)

**Total: 7/7 tasks complete** ✅
**Completed:** 2025-11-19
**Tests:** 69/69 passing

### Phase 3: UI/UX Integration ✅
- [x] Add discount banner (1 section)
- [x] Update pricing display (3 components)
- [x] Add discount management (4 methods)
- [x] Create discount badge (2 components)

**Total: 4/4 sections complete** ✅
**Completed:** 2025-11-19

### Phase 4: Production Integration 🔒
- [ ] ⏸️ Implement Keychain storage (1 file)
- [ ] ⏸️ Update StoreKit service (1 file, 3 methods)
- [ ] ⏸️ Configure App Store Connect (2 tasks)
- [ ] ⏸️ Testing & validation (2 tasks)

**Total: 0/8 tasks complete**
**Status:** Blocked - Awaiting Apple Developer Program

---

## Success Criteria

### Phase 2 Complete ✅
- [x] ActiveDiscount entity with price calculation
- [x] ActiveDiscountService protocol and mock implementation
- [x] Discount codes stored but don't grant subscriptions
- [x] Discounts applied during purchase
- [x] Discounts cleared after purchase
- [x] Comprehensive test coverage (9 tests)
- [x] No race conditions in tests
- [x] All 69 tests passing

### Phase 3 Complete ✅
- [x] Users see discount banner after redemption
- [x] Pricing shows original + discounted prices
- [x] Savings clearly displayed
- [x] Discount badge on product cards
- [x] Smooth redemption flow (reuses existing offer code sheet)

### Phase 4 Complete (Blocked - Apple Developer Program)
- [ ] ⏸️ Production StoreKit integration working
- [ ] ⏸️ Real promotional codes redeemable
- [ ] ⏸️ TestFlight validation passed
- [ ] ⏸️ Zero production errors

---

## Next Steps

**🔒 Blocked - Awaiting Apple Developer Program (Phase 4):**

Once Apple Developer Program is purchased and active:

1. Purchase Apple Developer Program membership
2. Create Keychain storage service for production
3. Implement StoreKit promotional offers
4. Configure promotional offers in App Store Connect
5. TestFlight validation with real codes
6. Production deployment

**Current State:**
- ✅ All mock/development infrastructure complete
- ✅ Full UI/UX implementation ready
- ✅ Comprehensive test coverage (69/69 tests passing)
- 🔒 Production integration awaiting Apple Developer Program

---

## Related Documentation

- **Offer Codes Plan:** `plans/offer-codes-implementation-plan.md`
- **Testing Guide:** `docs/guides/testing/OFFER-CODE-TESTING-GUIDE.md`
- **StoreKit Setup:** `docs/STOREKIT-SETUP-GUIDE.md`

---

**Document Version:** 2.0
**Created:** 2025-11-19
**Last Updated:** 2025-11-19
**Status:** Phase 3 Complete - Phase 4 Blocked (Awaiting Apple Developer Program)
