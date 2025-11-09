# StoreKit 2 Integration - Full Implementation Plan

## Approach
Mirror the iCloud implementation strategy:
- ✅ Complete StoreKit 2 integration code
- ✅ Full testing infrastructure
- ✅ Comprehensive documentation
- ⏸️ Commented out/feature flagged (no Apple Developer Program yet)
- 📋 Step-by-step activation instructions

## Branch Strategy
Create `feature/storekit-monetization` branch from `main`

---

## Phase 1: Foundation & Configuration (Week 1)

### 1.1 StoreKit Configuration File
**Create:** `Configuration/Ritualist.storekit`
- Define all 3 products: monthly ($9.99), annual ($49.99 + 7-day trial), lifetime ($100)
- Configure subscription groups
- Set up test scenarios
- Enable Xcode StoreKit testing

### 1.2 Product ID Constants
**Create:** `RitualistCore/Sources/RitualistCore/Constants/StoreKitConstants.swift`
```swift
public enum StoreKitProductID {
    public static let monthly = "com.vladblajovan.ritualist.monthly"
    public static let annual = "com.vladblajovan.ritualist.annual"
    public static let lifetime = "com.vladblajovan.ritualist.lifetime"
}
```

### 1.3 Update Mock to Include Lifetime
**Update:** `MockPaywallService.swift`
- Add lifetime product ($100) to mock products
- Map to `.monthly` subscription plan (one-time purchase)
- Update UI to display all 3 options

---

## Phase 2: StoreKit 2 Implementation (Weeks 1-2)

### 2.1 Production PaywallService
**Implement:** `Ritualist/Core/Services/StoreKitPaywallService.swift`
- Replace stub with full StoreKit 2 implementation
- Product loading from App Store
- Purchase flow with verification
- Restore purchases functionality
- Transaction.updates listener
- Error handling for all scenarios
- **Status:** Fully implemented, ready to uncomment

### 2.2 Production SubscriptionService
**Implement:** `RitualistCore/Sources/RitualistCore/Services/StoreKitSubscriptionService.swift`
- Replace `MockSecureSubscriptionService` in production
- On-device receipt validation using StoreKit 2
- Current entitlements checking
- Subscription status caching
- Expiry detection
- **Status:** Fully implemented, ready to uncomment

### 2.3 Lifetime Purchase Handling
**New:** Handle lifetime purchases in subscription logic
- Map lifetime to permanent premium access
- Store in UserProfile with special flag
- Feature gating recognizes lifetime users

---

## Phase 3: UI Enhancements (Week 2)

### 3.1 Subscription Management View
**Create:** `Ritualist/Features/Settings/Presentation/Components/SubscriptionManagementView.swift`
- Show active subscription details (plan, renewal date)
- Trial countdown indicator
- "Manage Subscription" → deep link to App Store
- Fix "Cancel Subscription" to redirect properly
- Lifetime purchase indicator
- **Status:** Implemented but commented out in SettingsView

### 3.2 Paywall Updates
**Update:** `PaywallView.swift`
- Add lifetime product card
- Highlight 7-day trial on annual plan
- Update benefit cards for 3 options
- Polish animations and states

---

## Phase 4: Testing Infrastructure (Week 3)

### 4.1 StoreKit Testing
**Files:**
- `.storekit` configuration (already created in Phase 1)
- Enable in Xcode scheme settings
- Document local testing procedures

### 4.2 Unit Tests
**Create:** `RitualistTests/Features/Paywall/`
- `StoreKitPaywallServiceTests.swift` - Test purchase flows
- `SubscriptionValidationTests.swift` - Test expiry logic
- `FeatureGatingTests.swift` - Test premium access
- Mock StoreKit responses for testing

### 4.3 Integration Tests
**Create:** `RitualistTests/Integration/`
- End-to-end purchase flow tests
- Restore purchases flow
- Subscription lifecycle tests

---

## Phase 5: Documentation (Week 3-4)

### 5.1 Setup Guide
**Create:** `docs/STOREKIT-SETUP-GUIDE.md`
```markdown
# StoreKit Monetization Setup Guide

## Prerequisites
- Apple Developer Program membership ($99/year)
- App created in App Store Connect

## Step-by-step Activation
1. App Store Connect configuration
2. Create IAP products (IDs in StoreKitConstants.swift)
3. Submit products for review
4. Uncomment production services in DI
5. Test with sandbox accounts
6. Deploy to TestFlight
7. Launch to App Store

## Testing Instructions
- Local testing with .storekit file
- Sandbox testing procedures
- TestFlight beta testing
```

### 5.2 Troubleshooting Guide
**Create:** `docs/STOREKIT-TROUBLESHOOTING.md`
- Common issues and solutions
- Sandbox account setup
- Transaction verification failures
- Subscription edge cases

### 5.3 RevenueCat Integration Prep
**Create:** `docs/REVENUECAT-MIGRATION.md`
- Why RevenueCat (analytics, webhooks, cross-platform)
- When to migrate (after launch, when needed)
- Migration strategy
- Backward compatibility plan

---

## Phase 6: Code Organization & Feature Flags (Week 4)

### 6.1 Conditional Compilation
**Pattern:**
```swift
// In Container+Services.swift
var paywallService: Factory<PaywallService> {
    #if STOREKIT_ENABLED  // New flag
    return StoreKitPaywallService()
    #else
    return MockPaywallService(...)  // Default for now
    #endif
}
```

### 6.2 Build Configuration
**Update:** `Ritualist.xcodeproj`
- Add `STOREKIT_ENABLED` flag (commented out)
- Instructions in docs for enabling

### 6.3 Code Comments
**Pattern:**
```swift
// MARK: - StoreKit Production Implementation
// TODO: Uncomment when Apple Developer Program is active
// See docs/STOREKIT-SETUP-GUIDE.md for activation steps
// return StoreKitPaywallService()

// MARK: - Mock Implementation (Development)
return MockPaywallService(...)
```

---

## Deliverables

### Code Files
1. ✅ `Configuration/Ritualist.storekit` - StoreKit test configuration
2. ✅ `StoreKitConstants.swift` - Product ID constants
3. ✅ `StoreKitPaywallService.swift` - Full production implementation
4. ✅ `StoreKitSubscriptionService.swift` - Receipt validation
5. ✅ `SubscriptionManagementView.swift` - Settings UI
6. ✅ Updated `PaywallView.swift` - 3 product options
7. ✅ Test files - Unit & integration tests

### Documentation
1. ✅ `STOREKIT-SETUP-GUIDE.md` - Activation instructions
2. ✅ `STOREKIT-TROUBLESHOOTING.md` - Common issues
3. ✅ `REVENUECAT-MIGRATION.md` - Future migration plan
4. ✅ `STOREKIT-TESTING.md` - Testing procedures
5. ✅ Updated `CHANGELOG.md` - Document additions
6. ✅ `BUILD-CONFIGURATION-STRATEGY.md` - Scheme vs flags analysis

### Status
- **All code:** Production-ready, commented out
- **All tests:** Passing with mocks
- **All docs:** Complete with step-by-step guides
- **Activation:** 1-2 hours when Apple Developer Program active

---

## Success Criteria

✅ Complete StoreKit 2 integration code written
✅ All 3 products (monthly, annual, lifetime) supported
✅ On-device receipt validation implemented
✅ Comprehensive test coverage
✅ Documentation covers all activation steps
✅ Code commented with clear TODOs
✅ Feature flag ready to enable
✅ Mock services work perfectly until activation
✅ Zero impact on current app functionality
✅ Ready to enable in 1-2 hours when needed

---

## Timeline
- **Week 1:** Foundation + StoreKit implementation
- **Week 2:** UI enhancements + start testing
- **Week 3:** Complete testing + documentation
- **Week 4:** Polish, code review, PR ready

**Total:** 3-4 weeks relaxed pace, fully production-ready but dormant

---

## Build Configuration Strategy

See `BUILD-CONFIGURATION-STRATEGY.md` for detailed analysis of:
- Current scheme-based approach (Ritualist-AllFeatures vs Ritualist-Subscription)
- Industry best practices
- Recommended strategy going forward
- Integration with StoreKit testing
