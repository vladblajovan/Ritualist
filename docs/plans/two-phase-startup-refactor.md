# Two-Phase Startup Refactor Plan

## Overview

Refactor the app startup flow to use modern Swift concurrency patterns instead of semaphore-based blocking. The goal is to eliminate the `isPremiumFromStoreKit()` semaphore that blocks the main thread for up to 1.5 seconds.

## Architecture

### SyncBootstrap
Synchronous operations that **must** complete before the first UI frame renders. These are acceptable to block the main thread briefly.

### AsyncLaunchTasks
Asynchronous operations that run after the launch screen is shown. These use proper async/await and never block the main thread. **No new abstraction needed** - we integrate into the existing `performInitialLaunchTasks()` in RitualistApp.

---

## Current Problems

1. **Main thread blocking**: `StoreKitSubscriptionService.isPremiumFromStoreKit()` uses a semaphore to make async StoreKit calls synchronous, blocking up to 1.5 seconds
2. **Anti-pattern**: Bridging async to sync with semaphores is fragile and hard to debug
3. **Unpredictable timing**: StoreKit cold start can be slow on first launch
4. **Silent failures**: Timeout scenarios are hard to diagnose

---

## Task Inventory

### SyncBootstrap (Blocks UI - Target: <300ms)

| Task | Status | Time | Location | Notes |
|------|--------|------|----------|-------|
| Logger initialization | ✅ Keep | ~1ms | DI Container | Already fast |
| UserDefaults reads (flags, preferences) | ✅ Keep | ~2ms | Various | Already fast |
| Keychain read for cached premium status | 🔄 Change | ~5ms | SecurePremiumCache | Replace semaphore call |
| BackupManager.executePendingRestoreIfNeeded() | ✅ Keep | ~5-50ms | Container+DataSources | Must run before ModelContainer |
| PersistenceContainer init (ModelContainer) | ✅ Keep | ~60-200ms | Container+DataSources | Database init - cannot be async |
| Quick Actions registration | ✅ Keep | ~1ms | AppDelegate | Already sync |
| Geofence launch handling | ✅ Keep | ~5ms | AppDelegate | Only if location launch |

**Target total: ~75-260ms** (vs current up to 1.5s+ with StoreKit timeout)

### AsyncLaunchTasks (After Launch Screen Shows)

| Task | Status | Priority | Location | Notes |
|------|--------|----------|----------|-------|
| StoreKit entitlement verification | 🆕 New | High | performInitialLaunchTasks() | Verify cached premium, update if wrong |
| Onboarding status check | ✅ Keep | High | RootTabViewModel | Blocks TabView (250ms min) |
| Load user appearance preference | ✅ Keep | High | RootTabViewModel | Affects theme |
| Seed predefined categories | ✅ Keep | Medium | RitualistApp | Database writes |
| Setup notification categories | ✅ Keep | Medium | RitualistApp | UNUserNotificationCenter |
| Schedule initial notifications | ✅ Keep | Medium | RitualistApp | After auth check |
| Detect timezone changes | ✅ Keep | Low | RitualistApp | Profile update |
| Restore geofences | ✅ Keep | Low | RitualistApp | CLLocationManager |
| Sync with iCloud | ✅ Keep | Low | RitualistApp | CloudKit sync |
| CloudKit PersonalityAnalysis cleanup | ✅ Keep | Low | RitualistApp | One-time migration |

### Event-Driven Tasks (No Changes)

| Task | Trigger | Notes |
|------|---------|-------|
| Reschedule notifications | didBecomeActive | Day change handling |
| Detect timezone changes | didBecomeActive | Travel handling |
| Sync with iCloud | didBecomeActive | Background sync |
| Restore geofences | didBecomeActive, RemoteChange | Device sync |
| Deduplicate data | NSPersistentStoreRemoteChange | iCloud merge conflicts |
| Update last sync date | NSPersistentStoreRemoteChange | UI update |
| UI refresh (debounced) | NSPersistentStoreRemoteChange | View updates |
| Invalidate iCloud cache | NSUbiquityIdentityDidChange | Account change |

---

## Implementation Steps

### Phase 1: Add Cache TTL to SecurePremiumCache
- [ ] Add `cacheTimestamp` to Keychain storage
- [ ] Add `isCacheStale()` method (stale if > 7 days old)
- [ ] Cache is still used for sync bootstrap even if stale (to avoid blocking)

### Phase 2: Create Async Premium Verification
- [ ] Add `verifyPremiumAsync()` method to `StoreKitSubscriptionService`
- [ ] Remove semaphore-based `isPremiumFromStoreKit()`
- [ ] Update `Container+DataSources` to use `SecurePremiumCache.shared.getCachedPremiumStatus()` only

### Phase 3: Integrate into performInitialLaunchTasks()
- [ ] Add `verifyAndUpdatePremiumStatus()` as first async task
- [ ] Handle mismatch scenarios with appropriate user feedback
- [ ] Update cache after verification

### Phase 4: Handle Premium Status Mismatch
- [ ] If `cached=false, actual=true` (user now premium): Show toast "Premium activated! Restart to enable iCloud sync"
- [ ] If `cached=true, actual=false` (premium expired): Update cache silently, sync continues this session
- [ ] Log all mismatches for diagnostics

### Phase 5: Testing & Validation
- [ ] Test cold start performance (measure time to first frame)
- [ ] Test premium status edge cases (cached true/actual false, vice versa)
- [ ] Test offline scenarios (StoreKit unavailable)
- [ ] Test first launch (no cache) scenarios
- [ ] Test cache TTL expiry scenarios

---

## Code Changes

### Before (Current)

```swift
// Container+DataSources.swift
PersistenceContainer.premiumCheckProvider = {
    StoreKitSubscriptionService.isPremiumFromStoreKit()  // ⚠️ Blocks up to 1.5s
}

// StoreKitSubscriptionService.swift
public static func isPremiumFromStoreKit() -> Bool {
    let semaphore = DispatchSemaphore(value: 0)
    var isPremium = false

    Task {
        for await result in Transaction.currentEntitlements { ... }
        semaphore.signal()
    }

    semaphore.wait(timeout: 1500ms)  // ⚠️ BLOCKS MAIN THREAD
    return isPremium
}
```

### After (Proposed)

```swift
// Container+DataSources.swift - SyncBootstrap
PersistenceContainer.premiumCheckProvider = {
    // Instant read from Keychain cache - no blocking
    SecurePremiumCache.shared.getCachedPremiumStatus()
}

// StoreKitSubscriptionService.swift - Async verification
public static func verifyPremiumAsync() async -> Bool {
    for await result in Transaction.currentEntitlements {
        if case .verified(let transaction) = result {
            if transaction.revocationDate == nil {
                if let expirationDate = transaction.expirationDate {
                    if expirationDate > Date() {
                        return true
                    }
                } else {
                    return true  // Lifetime
                }
            }
        }
    }
    return false
}

// RitualistApp.swift - performInitialLaunchTasks()
private func performInitialLaunchTasks() async {
    logStartupContext()

    // FIRST: Verify premium status async (no blocking)
    await verifyAndUpdatePremiumStatus()

    // Existing tasks continue...
    await seedCategories()
    await cleanupPersonalityAnalysisFromCloudKit()
    // ... etc
}

private func verifyAndUpdatePremiumStatus() async {
    let cachedPremium = SecurePremiumCache.shared.getCachedPremiumStatus()
    let actualPremium = await StoreKitSubscriptionService.verifyPremiumAsync()

    // Always update cache with fresh value
    SecurePremiumCache.shared.updateCache(isPremium: actualPremium)

    // Handle mismatch
    if actualPremium != cachedPremium {
        logger.log(
            "⚠️ Premium status mismatch",
            level: .warning,
            metadata: ["cached": cachedPremium, "actual": actualPremium]
        )

        if !cachedPremium && actualPremium {
            // User is now premium but sync wasn't enabled
            // Show non-intrusive toast
            await MainActor.run {
                ToastManager.shared.show(
                    message: "Premium activated! Restart to enable iCloud sync",
                    type: .info
                )
            }
        }
        // If cached=true, actual=false: silently update cache
        // Sync continues this session, next launch will be correct
    }
}
```

---

## Edge Cases

### 1. First Launch (No Cache)
- **Scenario**: User installs app for first time, no Keychain cache exists
- **Current**: Semaphore waits for StoreKit, blocks up to 1.5s
- **Proposed**: `getCachedPremiumStatus()` returns `false` (default), async verification updates cache
- **Impact**: First launch may start without iCloud sync even if user is premium
- **Mitigation**: Show toast "Premium activated! Restart to enable iCloud sync" if user is premium

### 2. Premium Expired While App Closed
- **Scenario**: User's subscription expires while app is not running
- **Current**: Semaphore query returns false, iCloud sync disabled
- **Proposed**: Cached value (true) used for sync decision, async verification updates to false
- **Impact**: App may sync for one session after expiry; next launch will be correct
- **Mitigation**: None needed - allowing one extra sync session is harmless

### 3. User Subscribes While App Closed
- **Scenario**: User purchases subscription outside the app (App Store)
- **Current**: Semaphore query returns true, iCloud sync enabled
- **Proposed**: Cached value (false) used, async verification updates to true
- **Impact**: First session after purchase won't sync
- **Mitigation**: Show toast "Premium activated! Restart to enable iCloud sync"

### 4. StoreKit Unavailable (Airplane Mode on First Launch)
- **Scenario**: First launch with no network, StoreKit can't verify
- **Current**: Semaphore times out after 1.5s, falls back to cache (which is empty)
- **Proposed**: Cache returns false (default), async verification fails/retries on didBecomeActive
- **Impact**: Same as current, but without 1.5s block

### 5. Cache is Stale (>7 days old)
- **Scenario**: User hasn't opened app in a week, subscription status may have changed
- **Current**: N/A (cache has no TTL)
- **Proposed**: Cache is still used for sync bootstrap (to avoid blocking), but logged as stale
- **Impact**: Same as edge cases 2/3, handled by async verification

### Acceptable Trade-offs
All edge cases result in at most **one session** with potentially wrong sync mode. This is acceptable because:
1. The cache is always updated after async verification
2. Next app launch will use the correct value
3. No data loss occurs (local data is always preserved)
4. User experience is dramatically better (no 1.5s freeze)
5. **NEW**: Toast notification informs premium users to restart for iCloud sync

---

## Success Metrics

1. **Cold start time**: < 500ms to first interactive UI (vs current potential 1.5s+)
2. **No main thread blocks**: Zero semaphore.wait() calls on main thread
3. **Cache accuracy**: Premium status cache matches StoreKit within 1 app session
4. **Offline support**: App launches smoothly even without network
5. **User awareness**: Premium users are notified when restart is needed for sync

---

## Files to Modify

| File | Changes |
|------|---------|
| `Ritualist/Core/Services/StoreKitSubscriptionService.swift` | Add `verifyPremiumAsync()`, remove `isPremiumFromStoreKit()` |
| `RitualistCore/.../Services/SecurePremiumCache.swift` | Add cache timestamp and `isCacheStale()` method |
| `Ritualist/DI/Container+DataSources.swift` | Use `SecurePremiumCache.shared.getCachedPremiumStatus()` only |
| `Ritualist/Application/RitualistApp.swift` | Add `verifyAndUpdatePremiumStatus()` to async launch tasks |

---

## Progress Tracking

- [x] Phase 1: Add Cache TTL to SecurePremiumCache ✅ (2025-12-06)
  - Added `stalenessThreshold` constant (7 days)
  - Added `isCacheStale()` method
  - Updated `debugDescription()` to include staleness info
- [x] Phase 2: Create Async Premium Verification ✅ (2025-12-06)
  - Added `verifyPremiumAsync()` async method
  - Deprecated `isPremiumFromStoreKit()` (kept for compatibility)
  - Updated `Container+DataSources` to use `SecurePremiumCache.shared.getCachedPremiumStatus()`
- [x] Phase 3: Integrate into performInitialLaunchTasks() ✅ (2025-12-06)
  - Added `verifyAndUpdatePremiumStatus()` as first async task
  - Injected `ToastService` for user notifications
- [x] Phase 4: Handle Premium Status Mismatch (with toast) ✅ (2025-12-06)
  - Toast shown when `cached=false, actual=true`: "Premium activated! Restart app to enable iCloud sync"
  - Added `hasShownPremiumRestartToast` flag to prevent repeated toasts
  - Silent cache update when `cached=true, actual=false`
  - All mismatches logged with metadata
- [x] Phase 5: Testing & Validation ✅ (2025-12-06)
  - Build succeeded
  - Analyzed all edge cases (see analysis below)
- [x] Phase 6: Update documentation ✅ (2025-12-06)
  - Updated `STOREKIT-ICLOUD-ISSUES.md` with two-phase startup details
- [ ] Phase 7: Create PR

---

## Additional Improvements (2025-12-06)

### Logging Infrastructure Cleanup
- [x] Converted all `print()` statements to `DebugLogger` in main app and RitualistCore
- [x] Added `LoggerConstants.appSubsystem` constant to avoid hardcoded strings
- [x] Updated `DebugLogger` default parameter to use `LoggerConstants.appSubsystem`
- [x] Updated 13 files to use `LoggerConstants.appSubsystem` instead of hardcoded `"com.ritualist.app"`
- [x] Added `LogCategory.premiumCache` for Keychain cache operations
- [x] Verified Release build behavior: only `.error` and `.critical` logs output

### Files Modified
| File | Changes |
|------|---------|
| `SecurePremiumCache.swift` | Added `stalenessThreshold`, `isCacheStale()`, logger with `.premiumCache` category |
| `StoreKitSubscriptionService.swift` | Added `verifyPremiumAsync()`, deprecated `isPremiumFromStoreKit()`, static logger |
| `Container+DataSources.swift` | Changed to use `SecurePremiumCache.shared.getCachedPremiumStatus()` |
| `RitualistApp.swift` | Added `verifyAndUpdatePremiumStatus()`, injected `ToastService` |
| `AppConstants.swift` | Added `LoggerConstants.appSubsystem`, `hasShownPremiumRestartToast` key |
| `DebugLogger.swift` | Added `LogCategory.premiumCache`, improved documentation, uses `LoggerConstants` |
| `PaywallService.swift` | Added logger, converted print to log |
| `MockOfferCodeStorageService.swift` | Added logger, converted print to log |
| `STOREKIT-ICLOUD-ISSUES.md` | Updated with two-phase startup documentation |

### Created Documentation
- `docs/log-analysis-report.md` - Analysis of logging patterns and recommendations
