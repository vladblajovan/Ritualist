# Migration Plan: Free Always-On iCloud Sync

## Overview

This document outlines the complete migration from premium-gated iCloud sync to free, always-on iCloud sync. The goal is to simplify the codebase, improve startup times, and align with industry standards.

### Goals
- Remove ~400 lines of sync-gating code
- Eliminate 2-2.5s worst-case startup delay
- Remove "restart app for sync" requirement after purchase
- Simplify returning user detection
- Simplify Settings UI

### Non-Goals
- Changing other premium features (habit limits, analytics, etc.)
- Removing CloudKit infrastructure
- Changing data model or schema

---

## Phase 1: Core Infrastructure Changes ✅

### 1.1 PersistenceContainer.swift ✅

**Location:** `RitualistCore/Sources/RitualistCore/Storage/PersistenceContainer.swift`

**Changes:**
- [x] Remove `premiumCheckProvider` static property (line ~302)
- [x] Remove `checkPremiumStatusFromCache()` method (lines ~319-342)
- [x] Simplify `init()` to always enable sync:
  ```swift
  // BEFORE
  let isPremium = Self.checkPremiumStatusFromCache()
  let syncPreference = ICloudSyncPreferenceService.shared.isICloudSyncEnabled
  let shouldSync = isPremium && syncPreference

  // AFTER
  let shouldSync = true  // Always sync
  ```
- [x] Update logging to remove premium-related metadata
- [x] Remove sync preference check

**Lines to remove:** ~50

---

### 1.2 PersistenceConfiguration.swift ✅

**Location:** `RitualistCore/Sources/RitualistCore/Storage/PersistenceConfiguration.swift`

**Changes:**
- [x] Remove `syncableEntitiesConfiguration(syncEnabled:)` method (lines ~63-71)
- [x] Remove `allConfigurations(syncEnabled:)` method (lines ~108-113)
- [x] Update `allConfigurations` to always use CloudKit:
  ```swift
  // BEFORE
  public static func allConfigurations(syncEnabled: Bool) -> [ModelConfiguration] {
      [
          syncableEntitiesConfiguration(syncEnabled: syncEnabled),
          localConfiguration
      ]
  }

  // AFTER
  public static var allConfigurations: [ModelConfiguration] {
      [cloudKitConfiguration, localConfiguration]
  }
  ```

**Lines to remove:** ~30

---

### 1.3 Container+DataSources.swift ✅

**Location:** `Ritualist/DI/Container+DataSources.swift`

**Changes:**
- [x] Keep `ALL_FEATURES_ENABLED` cache bridging (lines ~18-22) - needed for other features
- [x] Remove entire premium check provider setup (lines ~30-73)
- [x] Remove blocking StoreKit check
- [x] Simplify to:
  ```swift
  var persistenceContainer: Factory<RitualistCore.PersistenceContainer> {
      self {
          do {
              // Execute pending restore BEFORE creating ModelContainer
              let backupManager = RitualistCore.BackupManager()
              try backupManager.executePendingRestoreIfNeeded()

              return try RitualistCore.PersistenceContainer()
          } catch {
              // ... error handling unchanged
          }
      }
      .singleton
  }
  ```

**Lines to remove:** ~40

---

## Phase 2: App Startup Changes ✅

### 2.1 RitualistApp.swift ✅

**Location:** `Ritualist/Application/RitualistApp.swift`

**Changes:**
- [x] Remove sync-related logic from `verifyAndUpdatePremiumStatus()`:
  - Keep premium verification for feature gating (habit limits)
  - Remove sync-specific handling and toasts
- [x] Remove "restart app for sync" toast logic
- [x] Remove `syncWithCloudIfAvailable()` premium checks (simplify to just check iCloud availability)
- [x] Update `performInitialLaunchTasks()` to remove sync-premium coupling

**Specific removals:**
```swift
// REMOVE this toast logic (approximate location ~550-570)
if !cachedPremium && actualPremium {
    // User just became premium - need restart for sync
    await MainActor.run {
        toastManager.show(
            "Premium activated! Restart app to enable iCloud sync",
            // ...
        )
    }
}
```

**Lines to remove:** ~60

---

### 2.2 RootTabViewModel.swift ✅

**Location:** `Ritualist/Application/RootTabViewModel.swift`

**Changes:**
- [x] Remove `isCloudKitSyncActive` computed property (lines ~465-469)
- [x] Remove `premiumVerifier` parameter from init
- [x] Simplify `checkOnboardingStatus()`:
  ```swift
  // BEFORE
  let willSyncBeActive = isPremiumVerified && syncPreference
  if iCloudOnboardingCompleted && willSyncBeActive {
      // returning user with sync
  }

  // AFTER
  if iCloudOnboardingCompleted {
      // returning user - sync always active
  }
  ```
- [x] Remove `isPremiumVerified` usage in onboarding flow
- [x] Remove sync preference checks

**Lines to remove:** ~40

---

## Phase 3: Services Changes ✅

### 3.1 ICloudSyncPreferenceService.swift ✅

**Location:** `RitualistCore/Sources/RitualistCore/Services/ICloudSyncPreferenceService.swift`

**Implemented: Option A - Delete entirely**
- [x] Deleted file completely
- [x] Removed all references throughout codebase
- [x] Removed `UserDefaultsKeys.iCloudSyncEnabled` constant

**Lines removed:** ~70

---

### 3.2 StoreKitSubscriptionService.swift

**Location:** `Ritualist/Core/Services/StoreKitSubscriptionService.swift`

**Status:** No changes needed - `verifyPremiumSync` was already removed in Phase 1

---

### 3.3 SecurePremiumCache.swift

**Location:** `RitualistCore/Sources/RitualistCore/Services/SecurePremiumCache.swift`

**Status:** Kept as-is (still needed for feature gating)

---

## Phase 4: Settings UI Changes ✅

### 4.1 iCloudSyncSectionView.swift ✅

**Location:** `Ritualist/Features/Settings/Presentation/Components/iCloudSyncSectionView.swift`

**Changes:**
- [x] Remove sync toggle entirely
- [x] Remove "Upgrade to Pro" banner/prompts
- [x] Simplify to show:
  - iCloud connection status
  - Last sync timestamp
  - (Delete iCloud data button in DataManagementSectionView)
- [x] Remove premium status checks

**New simplified structure:**
```swift
Section("iCloud") {
    // Status row
    HStack {
        Label("iCloud Sync", systemImage: "icloud")
        Spacer()
        Text(iCloudStatus) // "Connected" / "Not Available"
    }

    // Last sync (if available)
    if let lastSync = lastSyncDate {
        HStack {
            Label("Last Synced", systemImage: "clock")
            Spacer()
            Text(lastSync, style: .relative)
        }
    }

    // Delete button
    Button(role: .destructive) {
        // Delete iCloud data
    } label: {
        Label("Delete iCloud Data", systemImage: "trash")
    }
}
```

**Lines to remove:** ~80

---

### 4.2 SettingsViewModel.swift ✅

**Location:** `Ritualist/Features/Settings/Presentation/SettingsViewModel.swift`

**Changes:**
- [x] Remove `iCloudSyncEnabled` computed property
- [x] Remove `setICloudSyncEnabled()` method
- [x] Remove sync preference use case dependencies from init
- [x] Simplify iCloud-related state

**Lines removed:** ~30

---

### 4.3 SubscriptionManagementSectionView.swift

**Location:** `Ritualist/Features/Settings/Presentation/Components/SubscriptionManagementSectionView.swift`

**Status:** To be updated separately - premium feature descriptions still need review

**Changes needed:**
- [ ] Update premium feature descriptions (remove "iCloud sync" from list)
- [ ] Update copy to reflect new premium benefits

---

## Phase 5: Use Cases Changes ✅

### 5.1 Remove Sync Preference Use Cases ✅

**Files modified/removed:**

- [x] `GetICloudSyncPreferenceUseCase` - Removed from `iCloudSyncUseCases.swift`
- [x] `SetICloudSyncPreferenceUseCase` - Removed from `iCloudSyncUseCases.swift`
- [x] Removed re-exports from `UseCases.swift`
- [x] Updated `Container+SettingsUseCases.swift` - Removed registrations

**Location:** `RitualistCore/Sources/RitualistCore/UseCases/`

---

### 5.2 Update CheckPremiumStatus Use Case

**Location:** `RitualistCore/Sources/RitualistCore/UseCases/Implementations/Core/UserUseCases.swift`

**Status:** To be updated separately - documentation clarification only

**Changes needed:**
- [ ] Update documentation to clarify it's for feature gating (habits, analytics)
- [ ] Not for sync decisions

---

## Phase 6: DI Container Updates ✅

### 6.1 Container+Services.swift ✅

**Location:** `Ritualist/DI/Container+Services.swift`

**Changes:**
- [x] Remove `iCloudSyncPreferenceService` factory

---

### 6.2 Container+SettingsUseCases.swift ✅

**Location:** `Ritualist/DI/Container+SettingsUseCases.swift`

**Changes:**
- [x] Remove `getICloudSyncPreference` factory
- [x] Remove `setICloudSyncPreference` factory

---

## Phase 7: Testing Infrastructure ✅

### 7.1 Existing Tests to Update

**RootTabViewModelTests.swift** ✅
- [x] Remove `setupPremiumProvider()` helper method
- [x] Remove tests that verify sync-premium coupling
- [x] Update returning user tests to not require premium status
- [x] Simplify test setup

**PersistenceContainerTests.swift** - N/A (file doesn't exist)
**SettingsViewModelTests.swift** - N/A (file doesn't exist)

---

### 7.2 Tests Removed ✅

- [x] Premium-sync coupling tests removed from RootTabViewModelTests
- [x] Sync preference use case tests - N/A (no dedicated test file existed)

---

### 7.3 New Tests (Optional - Future Enhancement)

Tests that could be added in the future:
- `test_returning_user_detected_without_premium_check`
- `test_returning_user_data_syncs_for_free_user`
- `test_section_shows_status_without_upgrade_prompt`

---

### 7.4 Mock Updates ✅

**MockICloudKeyValueService.swift** - Kept as-is (still needed)
**MockSecureSubscriptionService.swift** - Kept for feature gating tests
**SubscriptionManagementSectionView.swift preview mocks** - Updated ✅

---

## Phase 8: Documentation Updates ✅

### 8.1 Files Updated

- [x] `docs/STOREKIT-ICLOUD-ISSUES.md` - Updated to reflect new architecture
- [x] `docs/plans/free-icloud-sync-migration.md` - This file, tracking progress
- [ ] `docs/plans/premium-icloud-usecase-analysis.md` - Can be archived (low priority)

### 8.2 Documentation Added

- [x] Added "Architecture Change: Free iCloud Sync" section to STOREKIT-ICLOUD-ISSUES.md
- [x] Documented that premium is for features, not sync

---

## Phase 11: Debug Menu Cleanup ✅

### 11.1 Review Summary

Reviewed `DebugMenuView.swift` for options related to sync preferences.

**Result:** No changes needed

**Subscription Testing Section** - Still needed:
- "Clear Mock Purchases" - For testing premium feature gating (habit limits)
- "Clear Premium Cache (Keychain)" - For testing feature states

**iCloud Sync Diagnostics Section** - Still needed:
- CloudKit configuration info
- Push notification status
- Sync event tracking
- Force status check

**Rationale:**
- Subscription testing is still relevant for premium features (not sync)
- iCloud sync diagnostics help debug sync issues regardless of payment status
- No sync preference toggles existed in debug menu (were in Settings UI)

---

## Phase 9: Migration Strategy

### 9.1 Existing User Handling

**Free users with local data:**
- Data automatically starts syncing on next launch
- No user action required
- Data merges with any existing iCloud data (handled by SwiftData)

**Premium users:**
- No change in experience
- Sync continues working

**Users who had sync disabled:**
- Sync preference is removed
- Their data starts syncing
- Consider: Show one-time notification explaining change?

### 9.2 Rollout Strategy

1. **Development:** Implement all changes on feature branch
2. **Internal Testing:** Test all scenarios (fresh install, reinstall, upgrade, etc.)
3. **TestFlight:** Beta test with subset of users
4. **App Store:** Release with release notes mentioning free sync

---

## Phase 10: Verification Checklist

### 10.1 Manual Testing Scenarios

- [ ] **Fresh install (new user):** App launches quickly, no blocking delay
- [ ] **Fresh install → purchase:** Premium features unlock, no restart needed
- [ ] **Reinstall (was free):** Local data syncs to iCloud
- [ ] **Reinstall (was premium):** Data syncs, premium features work
- [ ] **New device (free user):** Data syncs from iCloud
- [ ] **New device (premium user):** Data syncs, premium features work
- [x] **Settings:** iCloud section shows status, no upgrade prompts
- [ ] **Delete iCloud data:** Works for all users
- [ ] **Offline mode:** App works offline, syncs when online

### 10.2 Performance Verification

- [ ] Measure startup time before migration
- [ ] Measure startup time after migration
- [x] Verify no blocking calls in startup path (removed blocking StoreKit check)
- [ ] Profile memory usage (should be unchanged)

### 10.3 Regression Testing

- [x] All existing tests pass (verified)
- [ ] Habit CRUD operations work
- [ ] Premium feature gating still works (habit limits, etc.)
- [ ] Onboarding flows work correctly
- [ ] Widget still functions

---

## Summary

### Implementation Status: ✅ COMPLETE

### Files Modified (14)
1. ✅ `PersistenceContainer.swift` - Removed premium check, always enables sync
2. ✅ `PersistenceConfiguration.swift` - Simplified to static `allConfigurations`
3. ✅ `Container+DataSources.swift` - Removed blocking StoreKit check
4. ✅ `RitualistApp.swift` - Simplified premium verification
5. ✅ `RootTabViewModel.swift` - Removed premium dependency
6. ✅ `iCloudSyncSectionView.swift` - Simplified to status-only display
7. ✅ `SettingsViewModel.swift` - Removed sync preference dependencies
8. ✅ `SubscriptionManagementSectionView.swift` - Updated preview mocks
9. ✅ `Container+Services.swift` - Removed sync preference service
10. ✅ `Container+SettingsUseCases.swift` - Removed preference factories
11. ✅ `Container+ViewModels.swift` - Updated SettingsViewModel init
12. ✅ `UseCases.swift` - Removed re-exports
13. ✅ `iCloudSyncUseCases.swift` - Removed preference use cases
14. ✅ `AppConstants.swift` - Removed `iCloudSyncEnabled` key

### Files Deleted (1)
1. ✅ `ICloudSyncPreferenceService.swift`

### Tests Updated (1)
1. ✅ `RootTabViewModelTests.swift`

### Documentation Updated (2)
1. ✅ `docs/STOREKIT-ICLOUD-ISSUES.md`
2. ✅ `docs/plans/free-icloud-sync-migration.md`

### Lines Changed (Actual)
- **Removed:** ~350+ lines
- **Added:** ~50 lines (simplified replacements)
- **Net reduction:** ~300 lines

### Completion Date: 2025-12-16

---

## Appendix: Code Snippets

### A.1 Simplified PersistenceContainer.init()

```swift
public init() throws {
    // Always enable sync - it's free for all users
    let shouldSync = true

    Self.logger.log(
        "Initializing PersistenceContainer with CloudKit sync enabled",
        level: .info,
        category: .system
    )

    // ... rest of init unchanged, just uses shouldSync = true
}
```

### A.2 Simplified Returning User Check

```swift
func checkOnboardingStatus() async {
    // Check iCloud flag - if set, user completed onboarding somewhere
    let iCloudOnboardingCompleted = iCloudKeyValueService.hasCompletedOnboarding()

    if iCloudOnboardingCompleted {
        // Returning user - data will sync automatically
        showOnboarding = false
        pendingReturningUserWelcome = true
        return
    }

    // New user flow...
}
```

### A.3 Simplified iCloud Settings Section

```swift
Section("iCloud") {
    // Connection status
    LabeledContent("Status") {
        HStack(spacing: 4) {
            Circle()
                .fill(isConnected ? .green : .secondary)
                .frame(width: 8, height: 8)
            Text(isConnected ? "Connected" : "Not Available")
        }
    }

    // Last sync
    if let lastSync = vm.lastSyncDate {
        LabeledContent("Last Synced") {
            Text(lastSync, style: .relative)
        }
    }

    // Delete data
    Button(role: .destructive) {
        showDeleteConfirmation = true
    } label: {
        Label("Delete iCloud Data", systemImage: "trash")
    }
} footer: {
    Text("Your habits sync automatically across all your devices signed into the same iCloud account.")
}
```
