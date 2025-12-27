# iCloud Sync Feature Gating - Implementation Notes

## Overview

iCloud sync is a premium feature. Free users have local-only storage. Premium users can enable/disable sync via a toggle in Settings (requires app restart).

## Architecture

### Premium Check Flow

```
App Startup
    │
    ├─► Container+DataSources.swift
    │       Sets UserDefaults.allFeaturesEnabledCache (bridges ALL_FEATURES_ENABLED flag)
    │
    └─► PersistenceContainer.init()
            │
            ├─► MockSecureSubscriptionService.isPremiumFromCache()
            │       1. Check allFeaturesEnabledCache (AllFeatures scheme)
            │       2. Check mockPurchases (Subscription scheme)
            │       3. (Future) Check StoreKit2 cached entitlements
            │
            ├─► ICloudSyncPreferenceService.isICloudSyncEnabled
            │       User's toggle preference (default: false)
            │
            └─► shouldSync = isPremium && syncPreference
                    │
                    ├─► true:  CloudKit configuration (sync enabled)
                    └─► false: Local-only configuration (no sync)
```

### Key Files

| File | Purpose |
|------|---------|
| `MockSecureSubscriptionService.swift` | `isPremiumFromCache()` - single source of truth for startup-time premium check |
| `ICloudSyncPreferenceService.swift` | User's sync preference (opt-in, default OFF) |
| `PersistenceContainer.swift` | Decides CloudKit vs local-only based on premium + preference |
| `Container+DataSources.swift` | Bridges `ALL_FEATURES_ENABLED` compiler flag to Swift Package |
| `PersistenceConfiguration.swift` | Defines CloudKit and local-only ModelConfigurations |

## Known Limitations & Design Decisions

### 1. UserDefaults for Build Flag Bridging

**Issue:** RitualistCore is a Swift Package and cannot see `ALL_FEATURES_ENABLED` compiler flag from main app target.

**Solution:** Bridge via UserDefaults (`allFeaturesEnabledCache` key) set in `Container+DataSources.swift` before `PersistenceContainer` is created.

**Security Note:** This is for development/TestFlight only. Production will use StoreKit2 receipt validation which is secure.

**StoreKit2 Migration:** When implementing real StoreKit2:
1. On app launch, check `Transaction.currentEntitlements`
2. Cache result in UserDefaults (`premiumStatusCache` key)
3. Update `MockSecureSubscriptionService.isPremiumFromCache()` to check this cache
4. Listen for transaction updates and refresh cache

### 2. iCloud Key-Value Store Syncs Independently

**Issue:** `NSUbiquitousKeyValueStore` (used for `hasCompletedOnboarding` flag) syncs automatically for ALL users, not just premium.

**Impact:** A free user on Device B can see the onboarding flag from Device A (premium), even though their habit data won't sync.

**Solution:** Gate the "returning user" flow by premium status. Free users with iCloud KV flag are treated as new users on that device.

### 3. Sync Toggle Requires App Restart

**Issue:** SwiftData's CloudKit configuration is set at `ModelContainer` initialization. Cannot change at runtime.

**Solution:** Toggle sets UserDefaults preference, shows "Restart Required" alert. Change takes effect on next app launch.

**Alternative Considered:** Making `PersistenceContainer.init()` async to allow hot-swapping configurations - rejected due to complexity and DI initialization order issues.

### 4. Opt-In Model (Default: OFF)

**Decision:** Sync is disabled by default. Users must explicitly enable it.

**Rationale:**
- Prevents unexpected data merge when user becomes premium
- Gives user control over when sync starts
- Avoids overwriting iCloud data with potentially empty local data

### 5. Data Merge Behavior

**Behavior:** When sync is enabled, local and iCloud data merge:
- **Profile:** Single record - latest/most complete version wins
- **Habits:** Multiple records - both datasets merge together
- **Categories:** Multiple records - merge
- **Logs:** Multiple records - merge

**Potential Issue:** If user has non-empty local profile and different non-empty iCloud profile, one will be overwritten based on CloudKit conflict resolution (last-writer-wins by default).

**Mitigation:** Not implemented. Users should be aware that enabling sync merges data.

### 6. Same Store File for Both Configurations

**Implementation:** `PersistenceConfiguration.syncableEntitiesConfiguration(syncEnabled:)` uses same store name ("CloudKit") regardless of sync setting.

**Benefit:** When user toggles sync off, their data stays in the same SQLite file - only the CloudKit mirroring stops. Data is never orphaned.

## Testing Checklist

### Ritualist Scheme (Production - Free User)
- [x] `is_premium: false` at startup
- [x] No sync toast shown
- [x] No auto-sync on launch
- [x] "Upgrade to Pro" message in iCloud section
- [x] iCloud KV flag detection skipped (treated as new user)

### Ritualist Scheme (After Purchase via StoreKit)
- [x] Purchase subscription → toggle appears (OFF by default)
- [x] Toggle ON → restart alert shown
- [x] Restart → sync active, data merges with iCloud
- [x] Profile/habits merge correctly

### Ritualist-AllFeatures Scheme (Development)
- [x] `is_premium: true` at startup (ALL_FEATURES_ENABLED flag)
- [x] iCloud sync toggle visible in Settings
- [x] Toggle OFF → restart → local-only (no sync)
- [x] Toggle ON → restart → sync active
- [x] Data persists when toggling (same store file)

### Subscription Expiry
- [x] Subscription expires → restart → `is_premium: false`
- [x] Local data remains intact (same store file)
- [x] User loses sync capability but keeps their data
- [x] Toggle hidden (free user UI shown)

## Future Improvements

1. **Warn before enabling sync** - Alert explaining that local data will merge with iCloud
2. **Sync conflict UI** - Show user when conflicts occur and let them choose
3. **Force sync direction** - "Replace with iCloud" vs "Replace iCloud with local" options
4. **Real-time sync toggle** - If SwiftData ever supports runtime configuration changes
