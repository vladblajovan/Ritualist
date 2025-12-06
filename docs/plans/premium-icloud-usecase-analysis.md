# Premium + iCloud Sync Use Case Analysis

> **Document Purpose:** Comprehensive analysis of all user scenarios involving premium status, iCloud sync, and network connectivity. Based on actual code behavior analysis.

## Two-Phase Startup Architecture

The app uses a **two-phase startup** pattern to ensure fast launch times while still verifying premium status:

### Phase 1: Sync Bootstrap (Blocking, ~5ms)

**When:** Before any UI is shown, during `PersistenceContainer.init()`

**Location:** `Container+DataSources.swift` → `PersistenceContainer.init()`

```
App Launch
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  SYNC BOOTSTRAP (blocking, must complete before UI)     │
│                                                         │
│  1. Read Keychain cache (~5ms)                         │
│     SecurePremiumCache.shared.getCachedPremiumStatus() │
│                                                         │
│  2. Read sync preference from UserDefaults             │
│     ICloudSyncPreferenceService.shared.isICloudSyncEnabled │
│                                                         │
│  3. Decide: shouldSync = isPremium && syncPreference   │
│                                                         │
│  4. Create PersistenceContainer with sync ON or OFF    │
│     (This decision is FINAL for this session)          │
└─────────────────────────────────────────────────────────┘
    │
    ▼
  UI Shows (Launch screen → Main app)
```

**Why blocking is OK here:**
- Keychain read is ~5ms (vs. 1.5 seconds for StoreKit)
- Must decide sync mode BEFORE database is created
- No network calls, no async operations

**What it reads:**
- `SecurePremiumCache` (Keychain) - Was user premium last time we checked?
- `ICloudSyncPreferenceService` (UserDefaults) - Does user want sync enabled?

---

### Phase 2: Async Launch Tasks (Non-blocking, after UI)

**When:** After UI is visible, in `RitualistApp.performInitialLaunchTasks()`

**Location:** `RitualistApp.swift` lines 289-327

```
UI is now visible
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  ASYNC LAUNCH TASKS (non-blocking, user sees app)       │
│                                                         │
│  1. verifyAndUpdatePremiumStatus() ← FIRST TASK        │
│     - Query StoreKit async (no blocking!)              │
│     - Compare with cached value                         │
│     - Update cache if different                         │
│     - Show toast if premium just activated              │
│                                                         │
│  2. seedCategories()                                    │
│  3. cleanupPersonalityAnalysisFromCloudKit()           │
│  4. detectTimezoneChanges()                            │
│  5. setupNotifications()                               │
│  6. scheduleInitialNotifications()                     │
│  7. restoreGeofences()                                 │
│  8. syncWithCloudIfAvailable()                         │
│                                                         │
│  hasCompletedInitialLaunch = true                      │
└─────────────────────────────────────────────────────────┘
```

**Why async is safe here:**
- UI is already showing - user isn't waiting
- StoreKit queries can take 0.5-1.5 seconds
- If cache was wrong, we correct it and notify user
- Database mode is already set (can't change mid-session)

---

## Visual Flow: Premium Check Timeline

```
TIME ──────────────────────────────────────────────────────────────►

     │ App Launch │        UI Visible        │    User Interacting
     │            │                          │
     ├────────────┼──────────────────────────┼────────────────────►
     │            │                          │
     │  PHASE 1   │        PHASE 2           │
     │  (5ms)     │        (async)           │
     │            │                          │
     │ Keychain   │  StoreKit Query          │
     │ Read       │  ┌─────────────┐         │
     │ ┌───┐      │  │ Verify      │         │
     │ │ ⚡ │      │  │ Premium     │         │
     │ └───┘      │  │ Async       │         │
     │            │  └──────┬──────┘         │
     │ Decision:  │         │                │
     │ Sync ON/OFF│         ▼                │
     │            │  Cache matches? ─── Yes ─► Done
     │            │         │                │
     │            │         No               │
     │            │         │                │
     │            │         ▼                │
     │            │  Update cache            │
     │            │  Show toast if needed    │
     │            │  (restart for sync)      │
```

---

## Key Decision Points

### At Startup (PersistenceContainer.init)

```swift
// From Container+DataSources.swift
PersistenceContainer.premiumCheckProvider = {
    SecurePremiumCache.shared.getCachedPremiumStatus()  // ← Keychain, instant
}

// From PersistenceContainer.swift
let isPremium = Self.checkPremiumStatusFromCache()  // Uses provider above
let syncPreference = ICloudSyncPreferenceService.shared.isICloudSyncEnabled
let shouldSync = isPremium && syncPreference        // Final decision
```

### After UI Shows (verifyAndUpdatePremiumStatus)

```swift
// From RitualistApp.swift
let cachedPremium = SecurePremiumCache.shared.getCachedPremiumStatus()
let actualPremium = await StoreKitSubscriptionService.verifyPremiumAsync()  // ← Async!

SecurePremiumCache.shared.updateCache(isPremium: actualPremium)

if actualPremium != cachedPremium {
    if !cachedPremium && actualPremium {
        // User is now premium but sync wasn't enabled at startup
        toastService.info("Premium activated! Restart app to enable iCloud sync")
    }
}
```

---

## Scenario Matrix

### 1. NEW USER - FIRST LAUNCH

| State | Behavior |
|-------|----------|
| **Keychain cache:** Empty | `getCachedPremiumStatus()` → `false` |
| **StoreKit:** No entitlements | `verifyPremiumAsync()` → `false` |
| **iCloud sync:** Disabled | Local-only storage |
| **Result:** ✅ Correct - Free user gets local storage |

### 2. RETURNING FREE USER - APP LAUNCH

| State | Behavior |
|-------|----------|
| **Keychain cache:** `isPremium=false` | `getCachedPremiumStatus()` → `false` |
| **StoreKit:** No entitlements | `verifyPremiumAsync()` → `false` |
| **Result:** ✅ Cache matches StoreKit, no action needed |

---

### 3. USER JUST PURCHASED SUBSCRIPTION (same session)

| State | Behavior |
|-------|----------|
| **Purchase flow:** | `StoreKitPaywallService.purchase()` calls `subscriptionService.registerPurchase()` |
| **StoreKitSubscriptionService:** | `registerPurchase()` calls `SecurePremiumCache.shared.updateCache(isPremium: true)` |
| **iCloud sync this session:** | ❌ Still disabled (PersistenceContainer already initialized) |
| **Toast shown:** | ✅ "Premium activated! Restart app to enable iCloud sync" |
| **Next launch:** | Cache=true → sync enabled |
| **Result:** ✅ Correct - User notified, restart enables sync |

### 4. RETURNING PREMIUM USER - NORMAL LAUNCH

| State | Behavior |
|-------|----------|
| **Keychain cache:** `isPremium=true`, age < 3 days | `getCachedPremiumStatus()` → `true` |
| **Sync preference:** `true` | |
| **PersistenceContainer:** | `shouldSync = true && true = true` |
| **iCloud sync:** ✅ Enabled | |
| **StoreKit verification:** | `verifyPremiumAsync()` → `true` |
| **Result:** ✅ Cache matches, sync active, no toast |

---

### 5. PREMIUM USER - OFFLINE (< 3 days)

| State | Behavior |
|-------|----------|
| **Keychain cache:** `isPremium=true`, age < 3 days | `getCachedPremiumStatus()` → `true` |
| **StoreKit query:** | Will attempt but may timeout/fail |
| **Grace period:** | Within 3-day offline grace |
| **iCloud sync:** | Enabled (based on cache) |
| **Behavior:** | CloudKit operations may fail but app works |
| **Result:** ✅ Correct - Grace period provides seamless offline UX |

### 6. PREMIUM USER - OFFLINE (> 3 days)

| State | Behavior |
|-------|----------|
| **Keychain cache:** `isPremium=true`, age > 3 days | `getCachedPremiumStatus()` → `false` (beyond grace) |
| **StoreKit query:** | May fail |
| **iCloud sync:** | Disabled |
| **Result:** ⚠️ User loses sync, but data preserved locally |

**Analysis:** This is the expected security trade-off. After 3 days offline, we can't trust the cache. User gets local-only storage. When they come online, next launch will:
1. StoreKit verifies subscription
2. Cache updates to `isPremium=true`
3. **RESTART NEEDED** to re-enable sync (toast shown)

---

### 7. SUBSCRIPTION EXPIRED - USER LAUNCHES APP

| State | Behavior |
|-------|----------|
| **Keychain cache:** `isPremium=true` (stale) | `getCachedPremiumStatus()` → `true` |
| **PersistenceContainer:** | Sync enabled (based on cache) |
| **StoreKit verification:** | `verifyPremiumAsync()` → `false` |
| **Cache updated:** | `updateCache(isPremium: false)` |
| **This session:** | Sync CONTINUES (container already initialized) |
| **Next launch:** | Cache=false → sync disabled |
| **Result:** ✅ Correct - Graceful degradation, no data loss |

**Analysis:** User gets one more session with sync (graceful degradation). Their data syncs one final time. Next launch will use local-only storage.

### 8. SUBSCRIPTION EXPIRED - CACHE STALE (> 7 days)

| State | Behavior |
|-------|----------|
| **Keychain cache:** `isPremium=true`, age > 7 days | `isCacheStale()` → `true` |
| **Behavior:** | Same as above, but logged as "stale" |
| **Result:** ✅ Still uses cache for bootstrap (no blocking) |

The staleness threshold (7 days) is informational - it's logged but doesn't change behavior. The 3-day grace period is what actually controls whether cached premium is trusted.

---

### 9. USER RE-SUBSCRIBES AFTER EXPIRATION

| State | Behavior |
|-------|----------|
| **Cache before:** `isPremium=false` | |
| **User purchases:** | `registerPurchase()` → `updateCache(isPremium: true)` |
| **This session:** | Sync still disabled (container initialized as local-only) |
| **Toast shown:** | ✅ "Premium activated! Restart app to enable iCloud sync" |
| **After restart:** | Sync re-enabled, CloudKit merges data |
| **Result:** ✅ Correct - Data preserved, sync resumes after restart |

---

### 10. PREMIUM USER - SYNC PREFERENCE OFF

| State | Behavior |
|-------|----------|
| **Keychain cache:** `isPremium=true` | |
| **Sync preference:** `false` | `ICloudSyncPreferenceService.isICloudSyncEnabled` |
| **PersistenceContainer:** | `shouldSync = true && false = false` |
| **Result:** ✅ Premium but local-only (user choice) |

---

### 11. USER TOGGLES SYNC ON (was off)

| State | Behavior |
|-------|----------|
| **Before:** | `syncPreference=false`, local storage |
| **User enables:** | `setICloudSyncEnabled(true)` |
| **This session:** | Still local (container initialized) |
| **After restart:** | Sync enabled, CloudKit merges |
| **Result:** ✅ Requires restart (documented behavior) |

### 12. USER TOGGLES SYNC OFF (was on)

| State | Behavior |
|-------|----------|
| **Before:** | `syncPreference=true`, CloudKit active |
| **User disables:** | `setICloudSyncEnabled(false)` |
| **This session:** | Sync continues (container initialized) |
| **After restart:** | Local-only, existing data preserved |
| **Result:** ✅ Graceful, no data loss |

---

### 13. NEW DEVICE SETUP - EXISTING PREMIUM USER

| State | Behavior |
|-------|----------|
| **Keychain cache:** Empty (new device) | `getCachedPremiumStatus()` → `false` |
| **PersistenceContainer:** | Local-only storage |
| **StoreKit verification:** | `verifyPremiumAsync()` → `true` |
| **Cache updated:** | `isPremium=true` |
| **Toast shown:** | ✅ "Premium activated! Restart app to enable iCloud sync" |
| **After restart:** | Sync enabled, iCloud data downloads |
| **Result:** ✅ Data syncs after one restart |

---

### 14. ICLOUD ACCOUNT SIGNED OUT

| State | Behavior |
|-------|----------|
| **Detection:** | `NSUbiquityIdentityDidChange` notification |
| **iCloud status cache:** | Invalidated |
| **CloudKit operations:** | Will fail with auth errors |
| **Data:** | Local copy preserved |
| **Result:** ✅ App continues working, just without sync |

### 15. ICLOUD ACCOUNT SIGNED IN (was out)

| State | Behavior |
|-------|----------|
| **Detection:** | `NSUbiquityIdentityDidChange` notification |
| **If premium + sync pref on:** | Sync was already configured at startup |
| **If container local-only:** | Restart needed for sync |
| **Result:** ⚠️ May need restart depending on timing |

---

### 16. NETWORK COMES ONLINE (was offline)

| State | Behavior |
|-------|----------|
| **CloudKit:** | Auto-resumes pending operations |
| **NSPersistentStoreRemoteChange:** | Fires when changes arrive |
| **Deduplication:** | Runs to clean up any merge conflicts |
| **Result:** ✅ Automatic recovery |

---

### 17. REFUND/REVOCATION BY APPLE

| State | Behavior |
|-------|----------|
| **Transaction listener:** | Detects revocation |
| **StoreKit check:** | `transaction.revocationDate != nil` |
| **registerPurchase:** | Not called (revoked) |
| **Cache:** | Updated to `isPremium=false` on next refresh |
| **This session:** | May continue with cached status |
| **Next launch:** | Properly detected as non-premium |
| **Result:** ✅ Handled correctly |

---

### 18. SUBSCRIPTION RENEWAL (automatic)

| State | Behavior |
|-------|----------|
| **Transaction listener:** | Detects renewal |
| **StoreKitSubscriptionService:** | Cache refreshed |
| **SecurePremiumCache:** | Updated during `refreshCache()` |
| **Result:** ✅ Seamless, no user action needed |

---

### 19. FAMILY SHARING - ASK TO BUY PENDING

| State | Behavior |
|-------|----------|
| **Purchase result:** | `.pending` |
| **purchaseState:** | Set to `.idle` |
| **Premium granted:** | Not until approved |
| **Transaction listener:** | Will catch approval later |
| **Result:** ✅ Correct handling of pending state |

---

## Edge Cases Analysis

### 20. TOAST ALREADY SHOWN - USER DOESN'T RESTART

| State | Behavior |
|-------|----------|
| **Flag:** `hasShownPremiumRestartToast = true` | |
| **Subsequent launches:** | Toast not shown again |
| **User eventually restarts:** | Sync enables normally |
| **Flag reset:** | When cache matches StoreKit |
| **Result:** ✅ No toast spam |

### 21. RACE: PURCHASE COMPLETES DURING STARTUP

| State | Behavior |
|-------|----------|
| **PersistenceContainer:** | Already initialized |
| **Transaction listener:** | Catches purchase |
| **registerPurchase:** | Updates cache |
| **Sync this session:** | No (container fixed) |
| **Toast:** | Shown if needed |
| **Result:** ✅ Safe - container immutable after init |

---

## Summary Table

| Scenario | Cache | StoreKit | Sync | Outcome |
|----------|-------|----------|------|---------|
| New user | Empty | false | OFF | ✅ Local |
| Premium, online | true | true | ON | ✅ Sync |
| Premium, offline <3d | true | - | ON | ✅ Grace |
| Premium, offline >3d | expired | - | OFF | ⚠️ Local |
| Just purchased | - | true | OFF→ON restart | ✅ Toast |
| Expired | true→false | false | ON→OFF next | ✅ Graceful |
| Re-subscribed | false→true | true | OFF→ON restart | ✅ Toast |
| New device | Empty | true | OFF→ON restart | ✅ Toast |
| Sync pref off | true | true | OFF | ✅ User choice |
| Refund | true | revoked | OFF next | ✅ Handled |

---

## Potential Issues Identified

1. **Minor UX friction:** New device setup requires one restart to get iCloud data. This is acceptable trade-off for non-blocking startup.

2. **>3 day offline:** User loses sync until online. This is by design (security trade-off) and matches industry standard (RevenueCat uses same grace period).

3. **iCloud account changes:** May require restart if timing is unfortunate. This is rare and acceptable.

**No breaking changes or data loss scenarios identified.** The implementation correctly handles all edge cases with graceful degradation.

---

## Code References

| Component | File | Line |
|-----------|------|------|
| Sync Bootstrap | `Container+DataSources.swift` | 30-47 |
| Premium Cache | `SecurePremiumCache.swift` | 101-133 |
| Async Verification | `RitualistApp.swift` | 368-446 |
| StoreKit Query | `StoreKitSubscriptionService.swift` | 71-90 |
| PersistenceContainer | `PersistenceContainer.swift` | 26-44 |
| Sync Preference | `ICloudSyncPreferenceService.swift` | 40-42 |
