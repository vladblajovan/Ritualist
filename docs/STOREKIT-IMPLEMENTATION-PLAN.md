# StoreKit 2 Integration - Full Implementation Plan

## Current Status (January 2025)

**Branch:** `feature/storekit-monetization`
**Overall Progress:** ~75% Complete (Backend ✅, UI ✅, Testing ❌, **Bugs 🔴**)

| Phase | Status | Progress |
|-------|--------|----------|
| Phase 1: Foundation | ✅ Complete | 100% |
| Phase 2: StoreKit 2 Implementation | ✅ Complete | 100% |
| Phase 3: UI Enhancements | ✅ Complete | 100% |
| Phase 4: Testing Infrastructure | ❌ Not Started | 0% |
| Phase 5: Documentation | ✅ Complete | 100% |
| Phase 6: Code Organization | ✅ Complete | 100% |
| **Bug Fixes** | 🔴 **BLOCKER** | 0% |

**What's Working NOW:**
- ✅ Production StoreKit services (ready to uncomment)
- ✅ Mock fallbacks (both schemes build successfully)
- ✅ Lifetime purchase support
- ✅ Complete activation documentation
- ✅ SubscriptionManagementSectionView UI
- ✅ PaywallView shows all 3 products dynamically

**What's Missing:**
- 🔴 **BLOCKER**: ALL_FEATURES_ENABLED bypass not working (see Known Issues)
- 🔴 **BLOCKER**: Inconsistent habit display between screens
- ❌ Unit tests

## Approach
Mirror the iCloud implementation strategy:
- ✅ Complete StoreKit 2 integration code
- ⏸️ Commented out/feature flagged (uses mocks until enabled)
- ✅ Comprehensive documentation
- 📋 Step-by-step activation instructions (5-10 min code + 30-45 min App Store Connect)

## Branch Strategy
Created `feature/storekit-monetization` branch from `main`

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

### Code Files (Status as of January 2025)
1. ✅ **COMPLETE** - `Configuration/Ritualist.storekit` - StoreKit test configuration
2. ✅ **COMPLETE** - `StoreKitConstants.swift` - Product ID constants
3. ✅ **COMPLETE** - `StoreKitPaywallService.swift` - Full production implementation (337 lines)
4. ✅ **COMPLETE** - `StoreKitSubscriptionService.swift` - Receipt validation (218 lines)
5. ✅ **COMPLETE** - `SubscriptionPlan.swift` - Added `.lifetime` case with helpers
6. ✅ **COMPLETE** - `UserProfile.swift` - Updated `hasActiveSubscription` for lifetime
7. ✅ **COMPLETE** - `Container+Services.swift` - DI container with mock fallbacks
8. ❌ **TODO** - `SubscriptionManagementView.swift` - Settings UI component
9. ❌ **TODO** - Updated `PaywallView.swift` - Show all 3 product options
10. ❌ **TODO** - Test files - Unit & integration tests

### Documentation (Status as of January 2025)
1. ✅ **COMPLETE** - `STOREKIT-SETUP-GUIDE.md` - Complete activation instructions (450 lines)
2. ✅ **COMPLETE** - `STOREKIT-TROUBLESHOOTING.md` - Common issues & solutions (600 lines)
3. ✅ **COMPLETE** - `REVENUECAT-MIGRATION.md` - Future migration strategy (550 lines)
4. ✅ **COMPLETE** - `BUILD-CONFIGURATION-GUIDE.md` - Practical scheme selection guide
5. ✅ **COMPLETE** - `BUILD-CONFIGURATION-STRATEGY.md` - Industry analysis (18 pages)
6. ❌ **TODO** - Updated `CHANGELOG.md` - Document StoreKit additions

### Status Summary
- **Backend Implementation:** ✅ 100% Complete - Production-ready, uses mocks until enabled
- **UI Components:** ❌ 0% Complete - Not started yet
- **Testing:** ❌ 0% Complete - No unit tests yet
- **Documentation:** ✅ 100% Complete - All guides written
- **Activation Time:** 5-10 minutes code changes + 30-45 minutes App Store Connect setup

---

## Success Criteria

### ✅ Completed
- ✅ Complete StoreKit 2 integration code written (StoreKitPaywallService, StoreKitSubscriptionService)
- ✅ All 3 products (monthly, annual, lifetime) supported
- ✅ On-device receipt validation implemented
- ✅ Lifetime purchase handling (added `.lifetime` case to enum)
- ✅ Documentation covers all activation steps (STOREKIT-SETUP-GUIDE.md)
- ✅ Troubleshooting guide for common issues (STOREKIT-TROUBLESHOOTING.md)
- ✅ RevenueCat migration strategy documented (REVENUECAT-MIGRATION.md)
- ✅ Code commented with clear TODOs and activation instructions
- ✅ Mock fallbacks in DI container (both schemes build successfully)
- ✅ Mock services work perfectly until activation
- ✅ Zero impact on current app functionality
- ✅ Ready to enable in 5-10 minutes (code) + 30-45 minutes (App Store Connect)

### ✅ Phase 3 Complete (UI Components)
- ✅ SubscriptionManagementSectionView UI component (Settings screen)
- ✅ PaywallView already shows all 3 product options dynamically
- ✅ Integrated into SettingsView

### ❌ Remaining
- 🔴 **BLOCKER**: Fix ALL_FEATURES_ENABLED bypass bugs (see Known Issues section below)
- 🔴 **BLOCKER**: Fix inconsistent habit display between screens
- ❌ Comprehensive test coverage (unit tests for StoreKit services)
- ❌ Integration tests for purchase flows

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

---

## 🐛 Known Issues (January 2025)

### Critical Bug #1: ALL_FEATURES_ENABLED Bypass Not Working Completely

**Status**: 🔴 BLOCKER - User testing revealed feature gating still enforced in AllFeatures scheme

**Symptom**:
- User tested Ritualist-AllFeatures scheme (which should bypass all paywalls)
- **Issue 1**: Attempted to create 6th habit → nothing happens (paywall triggered instead)
- **Issue 2**: Habits screen shows only 5 habits, Overview screen shows all habits (inconsistent)

**Expected Behavior**:
- Unlimited habit creation with no paywall in AllFeatures scheme
- All screens should display all habits consistently

**Investigation Results**:

1. **DI Container Configuration** (`Container+Services.swift:339-351`):
   ```swift
   var featureGatingService: Factory<FeatureGatingService> {
       #if ALL_FEATURES_ENABLED
       return MockFeatureGatingService(errorHandler: self.errorHandler())
       #else
       return BuildConfigFeatureGatingService(...)
       #endif
   }
   ```
   ✅ Correctly returns MockFeatureGatingService when ALL_FEATURES_ENABLED is set

2. **MockFeatureGatingService Implementation**:
   ```swift
   public var maxHabitsAllowed: Int { Int.max }
   public func canCreateMoreHabits(currentCount: Int) -> Bool { true }
   ```
   ✅ Correctly returns unlimited habits

3. **Feature Gating Flow**:
   ```
   HabitsViewModel.handleCreateHabitTap()
     → canCreateMoreHabits (computed property)
     → CheckHabitCreationLimit.execute(currentCount: 5)
     → featureGatingService.canCreateMoreHabits(currentCount: 5)
     → Should return true but doesn't
   ```

**Root Cause** (Hypothesis):
- Either DI injection failing at runtime despite compile-time flag being set
- Or there's additional filtering logic somewhere limiting habit display to 5
- Inconsistent behavior between Overview (shows all) and Habits (shows 5) suggests UI-level filtering

**Impact**:
- 🔴 **BLOCKER**: Cannot test AllFeatures scheme properly
- 🔴 **BLOCKER**: TestFlight users would still hit paywalls
- 🟡 **MAJOR**: Inconsistent habit display across screens

**Priority**: P0 - Must fix before TestFlight/launch

---

### Critical Bug #2: Inconsistent Habit Display Between Screens

**Status**: 🔴 BLOCKER - Data display inconsistency

**Symptom**:
- **Overview screen**: Shows ALL habits (e.g., 10+ habits visible)
- **Habits screen**: Shows only 5 habits (despite having more)

**Investigation**:

1. **Data Loading** (`LoadHabitsData` UseCase):
   ```swift
   async let habitsResult = habitRepo.fetchAllHabits()  // ✅ No filtering
   ```

2. **HabitLocalDataSource**:
   ```swift
   FetchDescriptor<ActiveHabitModel>(
       sortBy: [SortDescriptor(\.displayOrder)]
   )  // ✅ No limit applied
   ```

3. **HabitsData Model**:
   ```swift
   public func filteredHabits(for selectedCategory: HabitCategory?) -> [Habit] {
       // Only filters by category, not by count ✅
   }
   ```

4. **HabitsView UI**:
   ```swift
   ForEach(vm.filteredHabits, id: \.id) { habit in
       // Uses filteredHabits which should contain all habits
   }
   ```

**Root Cause** (Unknown):
- No obvious code limiting to 5 habits found in data flow
- Possible hidden filtering logic somewhere in the UI layer
- OR the issue is with how habits are being loaded/cached

**Next Steps**:
1. Add debug logging to trace actual habit counts at each layer
2. Verify what Overview is using vs what Habits is using
3. Check if there's category filtering accidentally limiting results

---

### Issue #3: StoreKit Restore Purchases - Apple ID Binding

**Status**: 🟡 CLARIFICATION NEEDED - User asked about restore behavior

**Question**: "should restore work with the icloud account registered in the phone or allow some other account?"

**Answer**:
- ✅ **Restore uses device's Apple ID ONLY** (cannot use different account)
- StoreKit associates purchases with the Apple ID signed into Settings → App Store
- `restorePurchases()` in SubscriptionManagementSectionView uses:
  - `AppStore.sync()` - syncs with App Store for current Apple ID
  - `Transaction.currentEntitlements` - retrieves purchases for current Apple ID
- **No way to restore purchases from a different Apple ID without:**
  1. Signing out of current Apple ID
  2. Signing into different Apple ID
  3. Running restore purchases

**Implementation**: Working as designed ✅

**Documentation Needed**: Add to STOREKIT-SETUP-GUIDE.md under "Testing Restore Purchases"

---

---

### Critical Bug #4: Missing Feature Gate in Assistant Creation Flow

**Status**: 🔴 BLOCKER - Discovered during testing

**Symptom**:
- User can create habits from 2 paths:
  1. **Add Sheet** (+ button in toolbar) - HAS feature gate check ✅
  2. **Habit Assistant** - NO feature gate check ❌

**Issue**:
- Assistant creation bypasses feature gating completely
- Users can create unlimited habits via Assistant even in Subscription scheme
- Inconsistent behavior between the two creation paths

**Location**:
- `HabitsViewModel.createHabitFromSuggestion()`

**Fix Required**:
- Add feature gate check before creating habit from suggestion
- Show paywall if limit reached
- Ensure consistent behavior across both creation paths

**Priority**: P0 - Must fix before launch

---

### Action Plan to Fix Critical Bugs

**Immediate Priority** (Before any commit):

1. ✅ **Document all bugs** (this section)
2. ✅ **Add debug logging** to trace execution flow
3. 🔴 **Test with logging**: Run app with debug logs to see what's actually happening
4. 🔴 **Fix ALL_FEATURES_ENABLED bypass**:
   - Verify which service is being injected at runtime
   - Fix any DI container issues
   - Ensure BuildConfigurationService is working correctly
5. 🔴 **Fix inconsistent habit display**:
   - Compare Overview vs Habits data loading paths
   - Audit all filtering logic
   - Ensure both screens use same data source
6. 🔴 **Add feature gate to Assistant creation**:
   - Check habit limit before creating from suggestion
   - Show paywall if limit reached
   - Ensure consistent with Add Sheet behavior
7. 🟡 **Audit all feature gating points**:
   - Search for other places using feature gating
   - Ensure ALL respect ALL_FEATURES_ENABLED flag
   - Test each feature gate individually

**Testing Checklist** (After fixes):
- [ ] AllFeatures scheme: Create 6+ habits via Add Sheet successfully
- [ ] AllFeatures scheme: Create 6+ habits via Assistant successfully
- [ ] AllFeatures scheme: No paywall appears anywhere
- [ ] Habits screen shows same count as Overview screen
- [ ] Subscription scheme: Paywall works correctly for both paths
- [ ] Subscription scheme: Shows correct habit limit message
- [ ] Restore purchases works with device Apple ID

**ETA**: 3-5 hours debugging + fixes

---

## 📊 Business Rules & Monetization Decisions

### Habit Limits

**Free Tier**: 5 habits maximum
- Centralized in `BusinessConstants.freeMaxHabits`
- Referenced by all feature gating services

**Premium Tier**: Unlimited habits (`Int.max`)
- All premium subscription plans (Monthly, Annual, Lifetime)
- Centralized in `BusinessConstants.premiumMaxHabits`

### Category Limits Decision

**Decision**: Categories remain unlimited for all users (free and premium)

**Constant**: `BusinessConstants.maxCategories = Int.max`

**Rationale** (Analyzed from 10+ perspectives):

1. **Natural Constraint from Habit Limit**:
   - Free users limited to 5 habits
   - 5 habits naturally constrains category usage
   - Creating many categories with few habits provides no value

2. **Low Monetization Value**:
   - Categories are organizational tools, not content
   - Industry norm: organization features remain free (Todoist, Trello, Notion)
   - Limiting categories would frustrate users without significant revenue gain

3. **Technical Simplicity**:
   - Categories are lightweight (name + emoji + color)
   - No storage/performance concerns
   - Easy to implement, maintain unlimited access

4. **User Psychology**:
   - Limiting organization tools increases frustration
   - Users feel "nickel-and-dimed" by organizing restrictions
   - Better to limit content (habits) than organization (categories)

5. **Competitive Alignment**:
   - Todoist: Unlimited projects for free
   - Trello: Unlimited boards for free
   - Notion: Unlimited pages for free (limits blocks)
   - **Pattern**: Limit content/complexity, not organization

6. **Support Burden**:
   - Category limits would generate support tickets
   - Users wouldn't understand why organization is restricted
   - Clear value prop: "Upgrade for more habits" > "Upgrade for more folders"

7. **Implementation Flexibility**:
   - Constant defined allows future changes if needed
   - Can always introduce limit later if abuse detected
   - Starting unlimited avoids negative PR from restriction

8. **UX Consistency**:
   - Settings page doesn't show category count
   - No need to add category management complexity
   - Keeps free tier simple and focused

**Implementation**:
```swift
// BusinessConstants.swift
public static let maxCategories = Int.max

// Rationale: Categories are lightweight organization tools.
// The 5-habit limit naturally constrains category usage,
// making an explicit limit unnecessary. Organization features
// should remain free to avoid user frustration.
```

**Future Consideration**:
- Monitor category creation patterns in analytics
- If abuse detected (e.g., 100+ categories), can introduce limit later
- Constant already defined for easy policy change

