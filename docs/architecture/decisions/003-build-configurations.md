# Build Configuration Strategy - Industry Best Practices

## Executive Summary

**Current Approach:** Scheme-based with compiler flags
- ✅ **Ritualist-AllFeatures** (ALL_FEATURES_ENABLED) - Bypass paywall for TestFlight
- ✅ **Ritualist-Subscription** (SUBSCRIPTION_ENABLED) - Enable paywall for App Store

**Recommendation:** **Keep current approach** - it aligns with industry best practices and provides the best developer experience.

---

## Table of Contents
1. [Current Implementation Analysis](#current-implementation-analysis)
2. [Industry Best Practices](#industry-best-practices)
3. [Approach Comparison](#approach-comparison)
4. [Recommended Strategy](#recommended-strategy)
5. [Implementation Guidelines](#implementation-guidelines)
6. [Testing Strategy](#testing-strategy)
7. [RevenueCat Integration](#revenuecat-integration)

---

## Current Implementation Analysis

### How It Works Today

**1. Xcode Schemes:**
```
Ritualist-AllFeatures
├── Debug-AllFeatures configuration
│   └── SWIFT_ACTIVE_COMPILATION_CONDITIONS = "ALL_FEATURES_ENABLED"
└── Release-AllFeatures configuration
    └── SWIFT_ACTIVE_COMPILATION_CONDITIONS = "ALL_FEATURES_ENABLED"

Ritualist-Subscription
├── Debug-Subscription configuration
│   └── SWIFT_ACTIVE_COMPILATION_CONDITIONS = "SUBSCRIPTION_ENABLED"
└── Release-Subscription configuration
    └── SWIFT_ACTIVE_COMPILATION_CONDITIONS = "SUBSCRIPTION_ENABLED"
```

**2. Build Configuration Service:**
```swift
// RitualistCore/Sources/RitualistCore/Services/BuildConfigurationService.swift
public protocol BuildConfigurationService {
    var allFeaturesEnabled: Bool { get }
    var subscriptionEnabled: Bool { get }
}

public final class DefaultBuildConfigurationService: BuildConfigurationService {
    public var allFeaturesEnabled: Bool {
        #if ALL_FEATURES_ENABLED
        return true
        #else
        return false
        #endif
    }

    public var subscriptionEnabled: Bool {
        #if SUBSCRIPTION_ENABLED
        return true
        #else
        return false
        #endif
    }
}
```

**3. Feature Gating Integration:**
```swift
// BuildConfigFeatureGatingBusinessService.swift
public final class BuildConfigFeatureGatingBusinessService: FeatureGatingBusinessService {
    public func canCreateMoreHabits(_ currentCount: Int) -> Bool {
        // If ALL_FEATURES_ENABLED, bypass all limits
        if buildConfigService.allFeaturesEnabled {
            return true
        }

        // Otherwise, check actual subscription status
        return standardFeatureGating.canCreateMoreHabits(currentCount)
    }
}
```

**4. Dependency Injection:**
```swift
// Container+Services.swift
var featureGatingBusinessService: Factory<FeatureGatingBusinessService> {
    #if ALL_FEATURES_ENABLED
    // TestFlight: Mock service always returns true
    return MockFeatureGatingBusinessService()
    #else
    // App Store: Check actual subscription
    return BuildConfigFeatureGatingBusinessService(
        buildConfigService: buildConfigurationService(),
        standardFeatureGating: defaultFeatureGatingBusinessService()
    )
    #endif
}
```

### Current Architecture Strengths

✅ **Compile-time Safety**
- Invalid configurations caught at build time
- No runtime overhead checking flags
- Clear separation between dev/prod code paths

✅ **Developer Experience**
- Switch schemes to test different modes
- No code changes needed between builds
- Easy to understand and debug

✅ **Clean Separation**
- TestFlight users test full app (AllFeatures)
- Production enforces paywall (Subscription)
- No accidental paywall in beta builds

✅ **Testability**
- Mock services for AllFeatures mode
- Real services for Subscription mode
- Easy to test both paths

---

## Industry Best Practices

### Research: How Major Apps Handle This

#### 1. **Spotify** (Gold Standard)
**Approach:** Build configurations + feature flags

```
Development Build:
- All premium features unlocked
- Internal testing environment
- Bypass premium checks

Internal Beta (TestFlight):
- Premium features unlocked for testers
- Production environment
- Real user data

App Store Release:
- Freemium model active
- Premium paywall shown
- Subscription enforcement
```

**Strategy:**
- Separate build configurations (Debug, Beta, Release)
- Compile-time flags for dev builds
- Runtime feature flags for A/B testing
- Clear separation of dev vs prod experiences

#### 2. **Netflix**
**Approach:** Scheme-based builds

```
Schemes:
- Development (no auth, mock data)
- QA (real auth, test accounts with premium)
- Production (real auth, subscription required)
```

**Benefits:**
- QA can test premium features without paying
- Developers work with mock services
- Production enforces real subscriptions

#### 3. **Calm / Headspace** (Meditation Apps)
**Approach:** Similar to Spotify

```
TestFlight:
- All content unlocked
- Beta testers experience full app
- Encourages feedback on premium features

App Store:
- Free tier limited content
- Paywall after X sessions
- Subscription required for full access
```

### Common Patterns Across Industry

**✅ DO:**
1. **Separate build configurations** for dev/beta/prod
2. **Compile-time flags** for feature availability
3. **Mock services** for development and testing
4. **TestFlight gets premium access** to test all features
5. **Clear documentation** on which build to use when

**❌ DON'T:**
1. **Runtime feature flags for core business logic** (use compile-time)
2. **Same build for dev and prod** (creates confusion)
3. **Paywall in TestFlight** (beta testers won't test premium features)
4. **Manual code changes** between builds (use schemes)

---

## Approach Comparison

### Option 1: Current Approach (Schemes + Compiler Flags) ⭐ RECOMMENDED

**How It Works:**
- Two schemes: AllFeatures and Subscription
- Compiler flags set per build configuration
- Service layer checks flags and switches behavior

**Pros:**
- ✅ Compile-time safety (no runtime overhead)
- ✅ Clear separation (scheme = purpose)
- ✅ Easy to switch (select scheme in Xcode)
- ✅ Industry standard (Spotify, Netflix, etc.)
- ✅ Works with StoreKit testing
- ✅ No manual code changes
- ✅ Testable with both configurations

**Cons:**
- ⚠️ Multiple build configurations to maintain
- ⚠️ Must remember to use correct scheme for distribution

**Best For:** Production apps with clear dev/beta/prod separation

---

### Option 2: Single Scheme + Runtime Feature Flags

**How It Works:**
- One scheme for everything
- Check environment variables or UserDefaults at runtime
- Toggle features dynamically

**Pros:**
- ✅ Simpler build setup
- ✅ Can toggle features without rebuild
- ✅ Good for A/B testing

**Cons:**
- ❌ Runtime overhead (checking flags every time)
- ❌ Possible to ship wrong configuration
- ❌ Harder to test both paths
- ❌ UserDefaults can be manipulated (security risk)
- ❌ Not recommended for core business logic

**Best For:** A/B testing non-critical features, analytics toggles

---

### Option 3: Build Configurations Only (No Schemes)

**How It Works:**
- Debug vs Release configurations
- Different flags per configuration
- No explicit schemes

**Pros:**
- ✅ Simpler than schemes
- ✅ Xcode default approach

**Cons:**
- ❌ Less explicit (Debug ≠ AllFeatures)
- ❌ Hard to test production paywall in debug mode
- ❌ Limited flexibility

**Best For:** Simple apps with basic debug/release needs

---

### Option 4: Xcode Build Schemes + Target Membership

**How It Works:**
- Separate targets for Free and Premium builds
- Different code included in each target
- Completely separate apps

**Pros:**
- ✅ Total separation
- ✅ Can ship both to App Store

**Cons:**
- ❌ Code duplication
- ❌ Maintenance nightmare
- ❌ Not suitable for single app with IAP

**Best For:** Separate free and paid versions (rare in modern apps)

---

## Recommended Strategy

### Keep Current Approach with Minor Refinements

**✅ Current System Works Well**

Your scheme-based approach with compiler flags is **exactly what industry leaders do**. It provides:

1. **Clear Separation**
   - AllFeatures = TestFlight/Internal testing
   - Subscription = App Store production

2. **Compile-Time Safety**
   - Invalid configurations fail at build time
   - No runtime overhead
   - Code is optimized away by compiler

3. **Developer Experience**
   - Change scheme dropdown → done
   - No manual flag toggling
   - Easy to understand

4. **Testing Benefits**
   - Can test both modes locally
   - StoreKit testing works in both schemes
   - Mock vs real services clearly separated

### Minor Refinements to Consider

#### 1. Add Staging Configuration (Optional)

For pre-production testing with real StoreKit but sandbox environment:

```
Ritualist-Staging (New)
├── Debug-Staging configuration
│   └── SUBSCRIPTION_ENABLED + STAGING_ENVIRONMENT
└── Release-Staging configuration
    └── SUBSCRIPTION_ENABLED + STAGING_ENVIRONMENT
```

**Use case:** Test subscription flow with sandbox accounts before production.

#### 2. Improve Build Configuration Naming

**Current (Good):**
- `Debug-AllFeatures`
- `Release-AllFeatures`
- `Debug-Subscription`
- `Release-Subscription`

**Alternative (More explicit):**
- `Debug-TestFlight` (ALL_FEATURES_ENABLED)
- `Release-TestFlight` (ALL_FEATURES_ENABLED)
- `Debug-AppStore` (SUBSCRIPTION_ENABLED)
- `Release-AppStore` (SUBSCRIPTION_ENABLED)

**Recommendation:** Keep current naming. "AllFeatures" is clear and aligns with the flag name.

#### 3. Add Configuration Documentation

Create a build configuration cheat sheet:

```markdown
# Build Configuration Guide

## When to Use Each Scheme

### Ritualist-AllFeatures
- **Purpose:** Development, TestFlight, internal testing
- **Behavior:** All premium features unlocked, no paywall
- **Use for:**
  - Local development
  - TestFlight beta releases
  - QA testing premium features
  - Screenshots for App Store

### Ritualist-Subscription
- **Purpose:** Production App Store releases
- **Behavior:** Freemium model, paywall active, 5 habit limit
- **Use for:**
  - App Store submissions
  - Production releases
  - Testing paywall flow

## Quick Reference

| Task | Scheme | Configuration |
|------|--------|---------------|
| Local dev | AllFeatures | Debug-AllFeatures |
| TestFlight | AllFeatures | Release-AllFeatures |
| App Store | Subscription | Release-Subscription |
| Test paywall | Subscription | Debug-Subscription |
```

---

## Implementation Guidelines

### 1. Consistent Flag Usage Pattern

**✅ CORRECT - Service Layer:**
```swift
// In FeatureGatingService
public var hasAdvancedAnalytics: Bool {
    #if ALL_FEATURES_ENABLED
    return true  // Bypass in TestFlight
    #else
    return userProfile.isPremiumUser  // Check subscription
    #endif
}
```

**❌ WRONG - View Layer:**
```swift
// DON'T check flags directly in Views
var body: some View {
    #if ALL_FEATURES_ENABLED
    AdvancedAnalyticsView()
    #else
    UpgradePromptView()
    #endif
}
```

**Why?** Keep business logic in services, views should be flag-agnostic.

### 2. DI Container Pattern

**✅ CORRECT - Conditional Service Injection:**
```swift
var paywallService: Factory<PaywallService> {
    #if ALL_FEATURES_ENABLED
    return MockPaywallService()  // Always "purchased"
    #else
    return StoreKitPaywallService()  // Real StoreKit
    #endif
}
```

**Benefits:**
- Views call same interface
- Implementation swapped at compile time
- Zero runtime overhead

### 3. Feature Gating Hierarchy

```
Layer 1: BuildConfigurationService
    ↓ (provides compile-time flags)
Layer 2: FeatureGatingService
    ↓ (combines flags + user subscription)
Layer 3: ViewModels
    ↓ (calls feature gating service)
Layer 4: Views
    ↓ (renders based on ViewModel state)
```

**Never skip layers!** Always go through the hierarchy.

---

## Testing Strategy

### Unit Testing with Both Configurations

**Test AllFeatures Mode:**
```swift
func testFeatureGating_AllFeatures_Always Returns True() {
    let buildConfig = MockBuildConfigurationService(allFeaturesEnabled: true)
    let featureGating = BuildConfigFeatureGatingBusinessService(
        buildConfigService: buildConfig,
        standardFeatureGating: mockStandard
    )

    XCTAssertTrue(featureGating.canCreateMoreHabits(100))
    // Even with 100 habits, should allow more in AllFeatures mode
}
```

**Test Subscription Mode:**
```swift
func testFeatureGating_Subscription_RespectsPremiumStatus() {
    let buildConfig = MockBuildConfigurationService(subscriptionEnabled: true)
    let userProfile = UserProfile(isPremiumUser: false)
    let featureGating = DefaultFeatureGatingBusinessService(
        userProfile: userProfile
    )

    XCTAssertFalse(featureGating.canCreateMoreHabits(5))
    // Free tier should be limited at 5 habits
}
```

### StoreKit Testing Integration

**Local Testing with .storekit File:**

```
Ritualist-AllFeatures + .storekit file:
- Can test purchase UI
- Mock service returns success
- No real transactions
- Fast iteration

Ritualist-Subscription + .storekit file:
- Real StoreKit flow
- Local product testing
- Transaction verification
- Proper testing environment
```

**Recommended:**
- Use AllFeatures for UI development
- Use Subscription with .storekit for StoreKit testing
- Use Subscription with sandbox for integration testing

### CI/CD Configuration

**GitHub Actions / CI:**
```yaml
jobs:
  test-all-features:
    name: Test AllFeatures Mode
    steps:
      - run: xcodebuild test -scheme Ritualist-AllFeatures

  test-subscription:
    name: Test Subscription Mode
    steps:
      - run: xcodebuild test -scheme Ritualist-Subscription
```

**Both configurations should build and pass tests.**

---

## RevenueCat Integration

### How Current Approach Stays Compatible

RevenueCat is a **wrapper around StoreKit**, not a replacement for build configurations.

**Future Architecture:**
```
AllFeatures Mode:
    BuildConfigService (ALL_FEATURES_ENABLED) → Bypass paywall

Subscription Mode:
    BuildConfigService (SUBSCRIPTION_ENABLED)
        ↓
    RevenueCatService (wraps StoreKit)
        ↓
    Feature Gating (checks subscription status from RevenueCat)
```

**Implementation Pattern:**
```swift
// Future: RitualistCore/Sources/RitualistCore/Services/RevenueCatPaywallService.swift
import RevenueCat

public final class RevenueCatPaywallService: PaywallService {
    public init() {
        // RevenueCat initialization
    }

    public func loadProducts() async throws -> [Product] {
        let offerings = try await Purchases.shared.offerings()
        // Map RevenueCat offerings to domain Products
    }

    public func purchase(_ product: Product) async throws -> Bool {
        let result = try await Purchases.shared.purchase(package: package)
        // Handle result
    }
}

// DI remains the same:
var paywallService: Factory<PaywallService> {
    #if ALL_FEATURES_ENABLED
    return MockPaywallService()
    #else
    return RevenueCatPaywallService()  // Swapped implementation
    #endif
}
```

**Key Point:** Build configuration strategy doesn't change with RevenueCat.

### Migration Path

**Phase 1: StoreKit 2 (Current Plan)**
```
AllFeatures: MockPaywallService
Subscription: StoreKitPaywallService
```

**Phase 2: RevenueCat (Future)**
```
AllFeatures: MockPaywallService (unchanged)
Subscription: RevenueCatPaywallService (swap implementation)
```

**Benefits of Current Approach:**
- ✅ Easy to swap StoreKit for RevenueCat
- ✅ Protocol-based architecture supports it
- ✅ No changes to Views or ViewModels
- ✅ AllFeatures mode still bypasses everything

---

## Decision Matrix

### Should You Change Your Current Approach?

**NO** - Keep the current scheme-based approach if:
- ✅ You want compile-time safety (YES - you do)
- ✅ You need clear dev/prod separation (YES - TestFlight vs App Store)
- ✅ You value industry alignment (YES - mirrors Spotify/Netflix)
- ✅ You want easy testing of both modes (YES - helpful)
- ✅ You plan to use RevenueCat later (YES - compatible)

**YES** - Consider changing if:
- ❌ You need runtime feature toggling (NO - not required)
- ❌ You ship multiple variations to App Store (NO - single app)
- ❌ You want A/B testing of paywall (NO - not needed yet)
- ❌ Build configs are confusing your team (NO - solo dev)

**Verdict:** **KEEP CURRENT APPROACH** ✅

---

## Final Recommendation

### Proposed Final Architecture

```
┌─────────────────────────────────────────────────────┐
│           Build Configurations                      │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Ritualist-AllFeatures (TestFlight)                │
│  ├── ALL_FEATURES_ENABLED flag                     │
│  ├── MockPaywallService                            │
│  └── Bypasses all premium checks                   │
│                                                     │
│  Ritualist-Subscription (App Store)                │
│  ├── SUBSCRIPTION_ENABLED flag                     │
│  ├── StoreKitPaywallService → RevenueCat (later)  │
│  └── Enforces subscription checks                  │
│                                                     │
│  [Optional] Ritualist-Staging (Future)             │
│  ├── SUBSCRIPTION_ENABLED + STAGING_ENVIRONMENT    │
│  ├── StoreKitPaywallService with sandbox           │
│  └── Pre-production testing                        │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Implementation Checklist

- [x] ✅ Keep existing schemes (AllFeatures, Subscription)
- [x] ✅ Keep compiler flags (ALL_FEATURES_ENABLED, SUBSCRIPTION_ENABLED)
- [x] ✅ Keep BuildConfigurationService
- [x] ✅ Keep scheme-based service injection
- [ ] 📝 Add build configuration documentation
- [ ] 📝 Add scheme selection guide
- [ ] 🔮 Consider staging configuration (future)
- [ ] 🔮 Plan RevenueCat migration (future)

### Distribution Guide

**TestFlight:**
```
1. Select: Ritualist-AllFeatures scheme
2. Configuration: Release-AllFeatures
3. Archive and upload
4. Result: Beta testers get all features unlocked
```

**App Store:**
```
1. Select: Ritualist-Subscription scheme
2. Configuration: Release-Subscription
3. Archive and upload
4. Result: Production users see paywall at 5 habits
```

**Local Development:**
```
1. Use: Ritualist-AllFeatures (faster iteration)
2. Switch to: Ritualist-Subscription (to test paywall)
3. Use .storekit file: For StoreKit testing
```

---

## Conclusion

**Your current build configuration strategy is industry-standard and well-architected.** The scheme-based approach with compiler flags provides:

1. **Compile-time safety** - Catch errors early
2. **Clear separation** - TestFlight vs App Store behavior
3. **Industry alignment** - How Spotify, Netflix, major apps do it
4. **Developer experience** - Easy scheme switching
5. **Future-proof** - Works with RevenueCat migration
6. **Testability** - Can test both modes

**Recommendation:** **Keep it as-is** with minor documentation improvements.

**No changes needed to code architecture** - just add documentation to guide future you (and any team members) on when to use which scheme.
