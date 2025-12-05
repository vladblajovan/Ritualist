# StoreKit2 Activation Plan

## Goal
Enable real StoreKit2 implementation for the default **Ritualist** scheme (production), while keeping mock services for testing schemes.

## Build Flag Logic (After Changes)

| Scheme | Flags | SubscriptionService | PaywallService | Feature Gating |
|--------|-------|---------------------|----------------|----------------|
| **Ritualist** (default) | None | `StoreKitSubscriptionService` | `StoreKitPaywallService` | Real subscription-based |
| **Ritualist-AllFeatures** | `ALL_FEATURES_ENABLED` | `MockSecureSubscriptionService` | `MockPaywallService` | All features unlocked |
| **Ritualist-Subscription** | `SUBSCRIPTION_ENABLED` | `MockSecureSubscriptionService` | `MockPaywallService` | Mock subscription-based |

## Files to Modify

### 1. `Ritualist/DI/Container+Services.swift`

**Change 1: `secureSubscriptionService` (lines 263-275)**
- **Current**: Always returns `MockSecureSubscriptionService`
- **New**: Return `StoreKitSubscriptionService` when no flags, mock when `ALL_FEATURES_ENABLED || SUBSCRIPTION_ENABLED`

```swift
// BEFORE
return RitualistCore.MockSecureSubscriptionService(errorHandler: self.errorHandler())

// AFTER
#if ALL_FEATURES_ENABLED || SUBSCRIPTION_ENABLED
return RitualistCore.MockSecureSubscriptionService(errorHandler: self.errorHandler())
#else
return StoreKitSubscriptionService(errorHandler: self.errorHandler())
#endif
```

**Change 2: `paywallBusinessService` (lines 284-297)**
- **Current**: Uses `#if DEBUG` to decide mock vs NoOp
- **New**: Use build flags instead of DEBUG

```swift
// BEFORE
#if DEBUG
let mockBusiness = MockPaywallBusinessService(...)
return mockBusiness
#else
return NoOpPaywallBusinessService()
#endif

// AFTER
#if ALL_FEATURES_ENABLED || SUBSCRIPTION_ENABLED
let mockBusiness = MockPaywallBusinessService(...)
return mockBusiness
#else
return NoOpPaywallBusinessService()
#endif
```

**Change 3: `paywallService` (lines 301-331)**
- **Current**: Always returns `MockPaywallService`
- **New**: Return `StoreKitPaywallService` when no flags, mock when `ALL_FEATURES_ENABLED || SUBSCRIPTION_ENABLED`

```swift
// BEFORE
let mockPaywall = MockPaywallService(...)
return mockPaywall

// AFTER
#if ALL_FEATURES_ENABLED || SUBSCRIPTION_ENABLED
let mockPaywall = MockPaywallService(...)
return mockPaywall
#else
return MainActor.assumeIsolated {
    StoreKitPaywallService(
        subscriptionService: self.secureSubscriptionService(),
        logger: self.debugLogger()
    )
}
#endif
```

### 2. `RitualistCore/Sources/RitualistCore/Services/BuildConfigurationService.swift`

**Change: Update `BuildConfiguration.current` default case (lines 27-31)**
- **Current**: Defaults to `.subscriptionBased` when no flags
- **New**: Add a third case `.production` for real StoreKit2, or keep as-is if the existing logic is acceptable

**Analysis**: The current implementation returns `.subscriptionBased` when no flags are set. This is fine because:
- The `BuildConfigFeatureGatingService` will use the real `DefaultFeatureGatingBusinessService`
- The `DefaultFeatureGatingBusinessService` checks the actual `subscriptionService.isPremiumUser()`

**Decision**: No changes needed to BuildConfigurationService - the existing logic works correctly.

### 3. UI Files Using `#if ALL_FEATURES_ENABLED`

These files use `#if ALL_FEATURES_ENABLED` to hide/show subscription-related UI. They should continue working as-is because:
- **Ritualist scheme** (no flags): Shows subscription UI, real StoreKit2
- **Ritualist-AllFeatures**: Hides subscription UI (all features unlocked)
- **Ritualist-Subscription**: Shows subscription UI with mocks

**Files (no changes needed)**:
- `Ritualist/Features/Habits/Presentation/HabitsViewModel.swift` - Premium banner logic
- `Ritualist/Features/HabitsAssistant/Presentation/HabitsAssistantView.swift` - Habit limit banner
- `Ritualist/Features/Settings/Presentation/Components/SubscriptionManagementSectionView.swift` - Subscription UI
- `Ritualist/Features/Settings/Presentation/DebugMenuView.swift` - Debug menu sections
- `Ritualist/Features/Shared/Presentation/HabitsAssistant/HabitsAssistantSheet.swift` - Limit banner

## Implementation Steps

### Step 1: Update DI Container
- [ ] Modify `secureSubscriptionService` to use StoreKit2 by default
- [ ] Modify `paywallBusinessService` to use build flags instead of DEBUG
- [ ] Modify `paywallService` to use StoreKit2 by default

### Step 2: Verify Compilation
- [ ] Build with **Ritualist** scheme (no flags) - should use real StoreKit2
- [ ] Build with **Ritualist-AllFeatures** scheme - should use mocks
- [ ] Build with **Ritualist-Subscription** scheme - should use mocks

### Step 3: Update Scheme for Local Testing (Optional)
- [ ] Configure Ritualist scheme to use `Ritualist.storekit` configuration for simulator testing
- [ ] This allows testing real StoreKit2 code path without App Store Connect products

### Step 4: Verify Feature Gating Works
- [ ] Run app with Ritualist scheme
- [ ] Verify paywall shows for free users
- [ ] Verify StoreKit products attempt to load (will fail without App Store Connect setup, but code path is correct)

## Verification Checklist

After implementation:
- [ ] `Container+Services.swift` compiles without errors
- [ ] Ritualist scheme builds successfully
- [ ] Ritualist-AllFeatures scheme builds successfully
- [ ] Ritualist-Subscription scheme builds successfully
- [ ] App launches with Ritualist scheme (products may not load yet - that's expected)
- [ ] Debug menu shows correct build configuration info

## Risk Assessment

**Low Risk** because:
1. All StoreKit2 code is already written and tested
2. Single file change (`Container+Services.swift`)
3. Easy rollback (revert the #if conditions)
4. No database or schema changes
5. Mock services remain available for testing

## Notes

- The real StoreKit2 services will attempt to load products from App Store Connect
- Until IAP products are created in App Store Connect, the paywall will show loading/error state
- Local testing with `Ritualist.storekit` configuration can validate the code path
- The checklist in `/Users/vladblajovan/Desktop/Ritualist app/STOREKIT2-ACTIVATION-CHECKLIST.md` covers App Store Connect setup
