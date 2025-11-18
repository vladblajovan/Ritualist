# Offer Codes Implementation Plan

**Goal:** Implement comprehensive offer code redemption system for Ritualist subscriptions, supporting both debug/mock testing and production StoreKit integration.

**Timeline:** 12-16 hours (complete implementation from foundation to production)

**Status:** 🟢 In Progress - Phase 5 Complete (5/7 phases done)

**Progress:**
- ✅ Phase 1: Foundation & Domain Layer (Complete)
- ✅ Phase 2: Mock Service Implementation (Complete)
- ✅ Phase 3: Debug Menu Integration (Complete)
- ✅ Phase 4: Production Service Updates (Complete)
- ✅ Phase 5: UI Layer Integration (Complete)
- ⬜ Phase 6: Testing & Validation (Next)
- ⬜ Phase 7: Production Activation

---

## Overview

### What are Offer Codes?

Offer codes are Apple's promotional redemption system that allows developers to:
- Provide free trials, discounts, or special pricing to specific users
- Create custom marketing campaigns with unique codes
- Enable in-app redemption or App Store redemption flows
- Track redemption analytics in App Store Connect

### Key Technical Points

- **StoreKit 2:** Uses `offerCodeRedemption()` modifier for SwiftUI
- **UIKit:** Uses `presentOfferCodeRedeemSheet()` method
- **Transaction Detection:** Transactions from offer codes appear in `Transaction.updates` like regular purchases
- **Testing:** Offer codes **cannot** be tested in sandbox (must use StoreKit testing in Xcode or TestFlight)
- **iOS 17.2+:** New support for non-subscription products (one-time purchases)

### Implementation Approach

**Option A: System Redemption Sheet** (Selected)
- ✅ Uses Apple's native UI (`presentCodeRedemptionSheet()`)
- ✅ Familiar user experience across all apps
- ✅ Handles validation, errors, and entitlements automatically
- ✅ Less code to maintain
- ⚠️ iOS 14+ only

**Debug/Mock Support:**
- Complete offer code management in debug menu
- Create custom codes with discounts, expiration, eligibility
- Test all validation scenarios offline
- Full redemption history tracking

---

## Architecture Integration

### Current Architecture Analysis

**Strengths:**
- ✅ Clean protocol-based architecture (`PaywallService`, `SecureSubscriptionService`)
- ✅ StoreKit 2 native implementation with async/await
- ✅ Transaction listener already in place for background updates
- ✅ Robust error handling and state management
- ✅ Separation of concerns (purchase vs. validation)

**Integration Points:**
1. `PaywallService` Protocol (RitualistCore/Services/PaywallService.swift:10)
2. `StoreKitPaywallService` (Ritualist/Core/Services/StoreKitPaywallService.swift:35)
3. `PaywallView` (Ritualist/Features/Paywall/Presentation/PaywallView.swift:18)
4. `Transaction Listener` (StoreKitPaywallService.swift:303)
5. `PaywallError` enum (RitualistCore/Enums/Paywall/PaywallError.swift:10)

---

## Phase 1: Foundation & Domain Layer

**Duration:** 2-3 hours
**Status:** ⬜ Not Started

### Tasks

#### 1.1: Core Domain Entities

- [ ] **Create `OfferCode.swift` entity**
  - Location: `RitualistCore/Sources/RitualistCore/Entities/Paywall/OfferCode.swift`
  - Properties: id, displayName, productId, offerType, discount, expirationDate, isActive, etc.
  - Validation: isExpired, isRedemptionLimitReached, isValid
  - Nested types: OfferType enum, OfferDiscount struct

- [ ] **Create `OfferCodeRedemptionState.swift` enum**
  - Location: `RitualistCore/Sources/RitualistCore/Enums/Paywall/OfferCodeRedemptionState.swift`
  - Cases: idle, validating, redeeming, success, failed
  - Property: isProcessing computed property

#### 1.2: Storage Protocol

- [ ] **Create `OfferCodeStorageService.swift` protocol**
  - Location: `RitualistCore/Sources/RitualistCore/Services/OfferCodeStorageService.swift`
  - Methods: getAllOfferCodes, getOfferCode, saveOfferCode, deleteOfferCode
  - Redemption tracking: incrementRedemptionCount, getRedemptionHistory, recordRedemption
  - Entity: OfferCodeRedemption struct

#### 1.3: Update Existing Domain

- [ ] **Extend `PaywallError.swift`**
  - Location: `RitualistCore/Sources/RitualistCore/Enums/Paywall/PaywallError.swift`
  - Add 6 new cases:
    - `offerCodeRedemptionFailed(String)`
    - `offerCodeInvalid`
    - `offerCodeExpired`
    - `offerCodeAlreadyRedeemed`
    - `offerCodeNotEligible`
    - `offerCodeRedemptionLimitReached`
  - Update `errorDescription` computed property

- [ ] **Extend `PaywallService` protocol**
  - Location: `RitualistCore/Sources/RitualistCore/Services/PaywallService.swift`
  - Add methods:
    - `func presentOfferCodeRedemptionSheet()`
    - `func isOfferCodeRedemptionAvailable() -> Bool`

### Files Created (3)
```
RitualistCore/Sources/RitualistCore/
├── Entities/Paywall/
│   └── OfferCode.swift [NEW]
├── Enums/Paywall/
│   └── OfferCodeRedemptionState.swift [NEW]
└── Services/
    └── OfferCodeStorageService.swift [NEW]
```

### Files Modified (2)
```
RitualistCore/Sources/RitualistCore/
├── Enums/Paywall/
│   └── PaywallError.swift [+6 cases]
└── Services/
    └── PaywallService.swift [+2 methods]
```

---

## Phase 2: Mock Service Implementation

**Duration:** 2-3 hours
**Status:** ⬜ Not Started

### Tasks

#### 2.1: Mock Offer Code Storage

- [ ] **Create `MockOfferCodeStorageService.swift`**
  - Location: `RitualistCore/Sources/RitualistCore/Services/MockOfferCodeStorageService.swift`
  - Uses UserDefaults for persistence
  - Pre-configured test codes:
    - `RITUALIST2025` (Annual free trial, 90 days)
    - `WELCOME50` (Monthly 50% off, 3 cycles)
    - `ANNUAL30` (Annual 30% off, 1 cycle, max 100)
    - `EXPIRED2024` (Expired test code)
    - `LIMITREACHED` (Redemption limit test)
  - Debug helpers: loadDefaultTestCodes, clearAllCodes, clearRedemptionHistory

#### 2.2: Enhanced MockPaywallService

- [ ] **Update `MockPaywallService` class**
  - Location: `RitualistCore/Sources/RitualistCore/Services/PaywallService.swift`
  - Add property: `offerCodeStorage: OfferCodeStorageService`
  - Add property: `offerCodeRedemptionState: OfferCodeRedemptionState`
  - Update initializer to accept `offerCodeStorage`
  - Implement `redeemOfferCode(_ code: String)` method:
    - Validate code exists
    - Check expiration
    - Check redemption limit
    - Check eligibility (new subscribers only)
    - Check if already redeemed by user
    - Grant purchase via `subscriptionService.mockPurchase()`
    - Record redemption
    - Increment redemption count
  - Implement `isOfferCodeRedemptionAvailable()` (always true for mock)

### Files Created (1)
```
RitualistCore/Sources/RitualistCore/Services/
└── MockOfferCodeStorageService.swift [NEW]
```

### Files Modified (1)
```
RitualistCore/Sources/RitualistCore/Services/
└── PaywallService.swift [MockPaywallService class]
```

---

## Phase 3: Debug Menu Integration

**Duration:** 3-4 hours
**Status:** ⬜ Not Started

### Tasks

#### 3.1: Create Offer Code Management View

- [ ] **Create `DebugOfferCodesView.swift`**
  - Location: `Ritualist/Features/Settings/Presentation/DebugOfferCodesView.swift`
  - Main sections:
    - Quick Redeem (text field + button)
    - Available Codes (list with status badges)
    - Actions (create, history, reset, clear)
  - Features:
    - Load all codes on appear
    - Quick redemption from code row
    - Real-time redemption feedback
    - Alert for success/failure

- [ ] **Create `OfferCodeRow` component**
  - Display: code ID, display name, status badge
  - Details: product, expiration, redemption count, eligibility
  - Quick redeem button (if valid)
  - Status badges: ACTIVE, INACTIVE, EXPIRED, LIMIT REACHED

- [ ] **Create `CreateOfferCodeView` sheet**
  - Form sections:
    - Code Details (ID, display name)
    - Product (picker: Monthly, Annual, Lifetime)
    - Offer Type (picker: Free Trial, Discount)
    - Discount config (type, value)
    - Expiration (toggle, days input)
    - Redemption Limits (new subscribers only, max redemptions)
  - Validation before save

- [ ] **Create `RedemptionHistoryView` sheet**
  - List all redemptions with timestamps
  - Show code ID, display name, product ID
  - Empty state for no redemptions

#### 3.2: Update Debug Menu

- [ ] **Update `DebugMenuView.swift`**
  - Location: `Ritualist/Features/Settings/Presentation/DebugMenuView.swift`
  - Add new section: "Offer Codes Testing" (after "Subscription Testing")
  - NavigationLink to `DebugOfferCodesView`
  - Icon: "giftcard", color: purple
  - Subtitle: "Create and test promotional codes"
  - Only show in non-AllFeatures mode

### Files Created (1)
```
Ritualist/Features/Settings/Presentation/
└── DebugOfferCodesView.swift [NEW]
   ├── DebugOfferCodesView
   ├── OfferCodeRow
   ├── CreateOfferCodeView
   └── RedemptionHistoryView
```

### Files Modified (1)
```
Ritualist/Features/Settings/Presentation/
└── DebugMenuView.swift [+Offer Codes section]
```

---

## Phase 4: Production Service Updates

**Duration:** 2-3 hours
**Status:** ✅ Complete

### Tasks

#### 4.1: StoreKitPaywallService Updates

- [x] **Update `StoreKitPaywallService.swift`**
  - Location: `Ritualist/Core/Services/StoreKitPaywallService.swift`
  - Add property: `offerCodeRedemptionState: OfferCodeRedemptionState`
  - ~~Add import: `UIKit`~~ - **NOT NEEDED** (using pure StoreKit 2)

- [x] **Implement `presentOfferCodeRedemptionSheet()`**
  - Kept as stub for Phase 4 (service layer)
  - UI presentation will be done in Phase 5 via SwiftUI `.offerCodeRedemption()` modifier
  - Pure StoreKit 2 approach (no UIKit/SKPaymentQueue)

- [x] **Implement `isOfferCodeRedemptionAvailable()`**
  - Return true for iOS 14+, false otherwise
  - Uses `#available(iOS 14.0, *)` check

- [x] **Enhance `listenForTransactions()` method**
  - Check if transaction has `offer` property (iOS 15+)
  - Create `handleOfferCodeTransaction()` helper
  - Create `handleRegularTransaction()` helper
  - Update `offerCodeRedemptionState` on success
  - Log offer details (offer ID, product ID)

- [x] **Add transaction handlers**
  - `handleOfferCodeTransaction()`: Process offer redemptions
  - `handleRegularTransaction()`: Process regular purchases
  - Update UI state on main actor via `await MainActor.run`

### Files Modified (1)
```
Ritualist/Core/Services/
└── StoreKitPaywallService.swift [+offer code support]
```

---

## Phase 5: UI Layer Integration

**Duration:** 2-3 hours
**Status:** ✅ Complete

### Tasks

#### 5.1: PaywallView Updates

- [x] **Update `PaywallView.swift`**
  - Location: `Ritualist/Features/Paywall/Presentation/PaywallView.swift`
  - Add `offerCodeSection` after `pricingSection`
  - Add `onChange` handler for `offerCodeRedemptionState`
  - Add `handleOfferCodeStateChange()` method for state handling
  - Add separate alerts for success and error states

- [x] **Create `offerCodeSection` view**
  - Divider
  - Button with:
    - Icon: "giftcard.fill" with purple-pink gradient
    - Title: "Have a promo code?"
    - Subtitle: "Redeem your offer code here"
    - Chevron right
  - Card-style background with .ultraThinMaterial
  - Conditional rendering if iOS 14+ available
  - Added `.offerCodeRedemption(isPresented:)` modifier

#### 5.2: PaywallViewModel Updates

- [x] **Update `PaywallViewModel.swift`**
  - Location: `Ritualist/Features/Paywall/Presentation/PaywallViewModel.swift`
  - Add computed property: `offerCodeRedemptionState`
  - Add computed property: `isOfferCodeRedemptionAvailable`
  - Add method: `presentOfferCodeSheet()`
  - Log user action when tapped
  - Inject `paywallService` dependency

#### 5.3: PaywallService Protocol Extension

- [x] **Add `offerCodeRedemptionState` to protocol**
  - Location: `RitualistCore/Sources/RitualistCore/Services/PaywallService.swift`
  - Added property to protocol: `var offerCodeRedemptionState: OfferCodeRedemptionState { get }`
  - Updated `NoOpPaywallService` to conform

### Files Modified (3)
```
Ritualist/Features/Paywall/Presentation/
├── PaywallView.swift [+offer code section, +modifiers, +alerts]
└── PaywallViewModel.swift [+offer code properties & methods]

RitualistCore/Sources/RitualistCore/Services/
└── PaywallService.swift [+offerCodeRedemptionState to protocol & NoOp]
```

---

## Phase 6: Testing & Validation

**Duration:** 2-4 hours
**Status:** ⬜ Not Started

### Tasks

#### 6.1: Local Testing (StoreKit Configuration)

- [ ] **Update `Ritualist.storekit` file**
  - Location: `Configuration/Ritualist.storekit`
  - Add `offerCodes` array with test codes
  - Configure: code, productIds, type, duration

- [ ] **Test debug menu**
  - Create custom offer code
  - Redeem valid code
  - Test expired code
  - Test limit-reached code
  - Test eligibility rules
  - Verify redemption history

- [ ] **Test validation scenarios**
  - Invalid code ID
  - Expired code
  - Already redeemed
  - Not eligible (existing subscriber)
  - Redemption limit reached

#### 6.2: Unit Tests

- [ ] **Create `OfferCodeRedemptionTests.swift`**
  - Location: `RitualistTests/Services/OfferCodeRedemptionTests.swift`
  - Test valid code redemption
  - Test invalid code handling
  - Test expiration logic
  - Test redemption limits
  - Test eligibility checks
  - Test transaction listener

#### 6.3: TestFlight Testing

- [ ] **Create real codes in App Store Connect**
  - Navigate to App → Features → Offer Codes
  - Create test offer code (e.g., `TESTFLIGHT2025`)
  - Set active with future expiration

- [ ] **Build for TestFlight**
  - Use `Ritualist-Subscription` scheme
  - Archive and upload
  - Wait for processing

- [ ] **Test on device**
  - Install TestFlight build
  - Navigate to paywall
  - Tap "Have a promo code?"
  - Enter code and redeem
  - Verify transaction processing
  - Check subscription status

- [ ] **Test edge cases**
  - Expired code → Error shown
  - Duplicate redemption → Error shown
  - Wrong eligibility → Error shown
  - Offline redemption → Queue for retry

### Files Created (2)
```
Configuration/
└── Ritualist.storekit [+offer codes]

RitualistTests/Services/
└── OfferCodeRedemptionTests.swift [NEW]
```

---

## Phase 7: Production Activation

**Duration:** 1-2 hours
**Status:** ⬜ Not Started

### Prerequisites

Before activating in production:

- [ ] Purchase Apple Developer Program ($99/year)
- [ ] Create app in App Store Connect (if not exists)
- [ ] Create IAP products (monthly, annual, lifetime)
- [ ] Submit products for review
- [ ] Create production offer codes in App Store Connect
- [ ] Test codes on TestFlight

### Tasks

- [ ] **Create production offer codes**
  - Navigate to App Store Connect → Features → Offer Codes
  - Create codes with:
    - Reference name (internal)
    - Customer-facing name
    - Code (user enters this)
    - Type (introductory or promotional)
    - Product selection
    - Duration
    - Start/end dates
    - Number of codes
    - Eligibility rules

- [ ] **Enable StoreKit service**
  - Update `Container+Services.swift`
  - Uncomment `StoreKitPaywallService`
  - Comment out `MockPaywallService`

- [ ] **Deploy to App Store**
  - Use `Ritualist-Subscription` scheme
  - Submit for review
  - Wait for approval

- [ ] **Monitor analytics**
  - Check App Store Connect → Analytics → Offer Codes
  - Track: redemption count, conversion rate, revenue impact
  - Monitor geographic distribution

### Production Checklist

- [ ] Offer codes active in App Store Connect
- [ ] Redemption sheet tested on TestFlight
- [ ] Transaction processing verified
- [ ] Analytics tracking confirmed
- [ ] Error handling tested
- [ ] User feedback collected

---

## File Structure Summary

### New Files (7)

```
RitualistCore/Sources/RitualistCore/
├── Entities/Paywall/
│   └── OfferCode.swift
├── Enums/Paywall/
│   └── OfferCodeRedemptionState.swift
├── Services/
│   ├── OfferCodeStorageService.swift
│   └── MockOfferCodeStorageService.swift

Ritualist/Features/Settings/Presentation/
└── DebugOfferCodesView.swift

RitualistTests/Services/
└── OfferCodeRedemptionTests.swift

Configuration/
└── (Ritualist.storekit updated)
```

### Modified Files (6)

```
RitualistCore/Sources/RitualistCore/
├── Enums/Paywall/
│   └── PaywallError.swift [+6 cases]
├── Services/
│   └── PaywallService.swift [+2 methods to protocol, +mock impl]

Ritualist/
├── Core/Services/
│   └── StoreKitPaywallService.swift [+redemption sheet, +transaction handling]
└── Features/
    ├── Paywall/Presentation/
    │   ├── PaywallView.swift [+offer code section]
    │   └── PaywallViewModel.swift [+offer code methods]
    └── Settings/Presentation/
        └── DebugMenuView.swift [+Offer Codes section]
```

---

## Progress Tracking

### Phase 1: Foundation & Domain Layer ✅
- [x] 1.1: Core Domain Entities (3 files)
- [x] 1.2: Storage Protocol (1 file)
- [x] 1.3: Update Existing Domain (2 files)

**Total: 6/6 tasks complete** ✅
**Commit:** `ec923e1` - Phase 1: Foundation & Domain Layer for Offer Codes

### Phase 2: Mock Service Implementation ✅
- [x] 2.1: Mock Offer Code Storage (1 file)
- [x] 2.2: Enhanced MockPaywallService (1 file)

**Total: 2/2 tasks complete** ✅
**Commit:** `ef9e020` - Phase 2: Mock Service Implementation for Offer Codes

### Phase 3: Debug Menu Integration ✅
- [x] 3.1: Create Offer Code Management View (1 file, 4 components)
- [x] 3.2: Update Debug Menu (1 file)

**Total: 2/2 tasks complete** ✅
**Commit:** `61c891f` - Phase 3: Debug Menu Integration for Offer Codes

### Phase 4: Production Service Updates ⬜
- [ ] 4.1: StoreKitPaywallService Updates (1 file, 4 methods)

**Total: 0/4 tasks complete**

### Phase 5: UI Layer Integration ⬜
- [ ] 5.1: PaywallView Updates (1 file, 3 sections)
- [ ] 5.2: PaywallViewModel Updates (1 file, 3 properties)

**Total: 0/6 tasks complete**

### Phase 6: Testing & Validation ⬜
- [ ] 6.1: Local Testing (1 file, 7 scenarios)
- [ ] 6.2: Unit Tests (1 file, 6 tests)
- [ ] 6.3: TestFlight Testing (4 scenarios)

**Total: 0/17 tasks complete**

### Phase 7: Production Activation ⬜
- [ ] Prerequisites (6 items)
- [ ] Create production codes (1 task)
- [ ] Enable StoreKit service (1 task)
- [ ] Deploy to App Store (1 task)
- [ ] Monitor analytics (1 task)

**Total: 0/10 tasks complete**

---

## Implementation Notes

### Key Insights

1. **Separation of Concerns:**
   - Mock storage uses UserDefaults for debug
   - Production uses Apple's StoreKit validation
   - Same validation logic in mock and production

2. **Testing Strategy:**
   - Debug menu for rapid iteration
   - StoreKit Configuration for local testing
   - TestFlight for real code testing
   - Production for live monitoring

3. **User Experience:**
   - System sheet = familiar, trusted UI
   - Automatic validation by Apple
   - Seamless transaction processing
   - Clear error messaging

4. **Production Readiness:**
   - All validation handled by StoreKit
   - Minimal maintenance required
   - Analytics built-in to App Store Connect
   - Easy to create new codes

### Common Pitfalls

⚠️ **Avoid These Mistakes:**

1. **Testing in Sandbox:**
   - Offer codes don't work in sandbox
   - Must use StoreKit Configuration or TestFlight

2. **Forgetting iOS Version Checks:**
   - Always check iOS 14+ before showing UI
   - Gracefully handle older devices

3. **Not Finishing Transactions:**
   - Always call `transaction.finish()` after processing
   - Prevents duplicate processing

4. **Hardcoding Product IDs:**
   - Use `StoreKitProductID` constants
   - Supports both legacy and new IDs

5. **Ignoring Transaction.updates:**
   - Offer redemptions arrive via background stream
   - Must have listener running always

---

## Estimated Timeline

### Development Time

| Phase | Duration | Complexity |
|-------|----------|------------|
| Phase 1: Foundation | 2-3 hours | Medium |
| Phase 2: Mock Services | 2-3 hours | Medium |
| Phase 3: Debug Menu | 3-4 hours | High |
| Phase 4: Production Service | 2-3 hours | Medium |
| Phase 5: UI Integration | 2-3 hours | Low |
| Phase 6: Testing | 2-4 hours | Medium |
| Phase 7: Production | 1-2 hours | Low |

**Total: 14-22 hours** (can be done over 2-3 days)

### Milestone Targets

- **Day 1:** Phases 1-3 complete (debug/mock fully functional)
- **Day 2:** Phases 4-5 complete (production ready, UI integrated)
- **Day 3:** Phases 6-7 complete (tested, deployed)

---

## Success Criteria

### Definition of Done

✅ **Foundation:**
- All domain entities created and tested
- Protocol-based design allows mock/production swap
- Error handling covers all scenarios

✅ **Debug/Mock:**
- Can create custom codes in debug menu
- All validation scenarios testable offline
- Redemption history tracked

✅ **Production:**
- System sheet presents correctly
- Transactions processed automatically
- Entitlements granted properly

✅ **Testing:**
- All unit tests passing
- TestFlight validation successful
- Edge cases handled gracefully

✅ **Deployment:**
- Production codes active
- Analytics tracking working
- Zero crashes or errors

---

## Dependencies

### External

- Apple Developer Program membership ($99/year)
- App Store Connect access
- TestFlight build processing time
- App review (for new products)

### Internal

- StoreKit 2 implementation complete
- PaywallService protocol in place
- DebugMenu infrastructure available
- Transaction listener active

### Version Requirements

- iOS 14.0+ (offer code redemption sheet)
- iOS 15.0+ (offer property on transactions)
- iOS 17.2+ (one-time purchase offers)

---

## Next Steps

1. **Review this plan** with team
2. **Create feature branch:** `feature/offer-codes-integration`
3. **Start with Phase 1** (Foundation)
4. **Incremental testing** after each phase
5. **Code review** before production activation

---

**Document Version:** 1.0
**Created:** 2025-11-18
**Last Updated:** 2025-11-18
**Status:** Ready for Implementation
