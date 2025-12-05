# Settings Page Refresh Optimization Plan

## Problem Statement

The Settings page refreshes excessively (up to 3 times) when users perform actions like "Delete All Data". This causes:
- Visual flickering due to `isLoading = true` replacing the Form with a ProgressView
- Open sheets (image picker, paywall, debug menu) being dismissed unexpectedly
- Poor user experience with unnecessary UI updates

## Root Cause Analysis

### Current Refresh Triggers (7 total)

| Location | Trigger | Issue |
|----------|---------|-------|
| `SettingsRoot:15` | `.task` | Initial load - OK |
| `SettingsRoot:17-45` | `.onReceive(iCloudDidSyncRemoteChanges)` | Full reload on ANY iCloud sync |
| `SettingsFormView:178-181` | `.refreshable` | Pull-to-refresh - OK |
| `SettingsFormView:199-206` | Paywall `.onDisappear` | Redundant: calls both `refreshSubscriptionStatus()` AND `load()` |
| `SettingsFormView:216-224` | `.onAppear` | Redundant: 4 parallel refresh calls already done by `.task` |
| `SettingsFormView:231-234` | `.onChange(of: vm.profile)` | Triggers on every profile change |
| `SettingsViewModel:496` | `importData()` | Calls `load()` during import |

### Delete All Data Flow (3 refreshes)

```
1. deleteAllData() called
   ├─ deleteiCloudData.execute() → deletes from CloudKit
   ├─ profile = UserProfile()    → triggers .onChange → updateLocalState() [REFRESH 1]
   └─ returns result

2. CloudKit deletion triggers NSPersistentStoreRemoteChange
   └─ App posts .iCloudDidSyncRemoteChanges
      └─ SettingsRoot.onReceive calls vm.load() [REFRESH 2 - isLoading = true!]
         └─ load() sets profile from database
            └─ triggers .onChange → updateLocalState() [REFRESH 3]
```

### Core Issue: `isLoading = true` Destroys UI State

```swift
// SettingsFormView body
if vm.isLoading {
    ProgressView("Loading settings...")  // ← Replaces entire Form
} else {
    Form { ... }  // ← All sheets attached here get dismissed when Form is removed
}
```

## Implementation Plan

### Phase 1: Add Silent Loading Mode

**File:** `SettingsViewModel.swift`

1. Add `isSilentLoading` flag to distinguish background refreshes from user-initiated loads
2. Modify `load()` to accept a `silent` parameter
3. Only set `isLoading = true` when not in silent mode

```swift
public func load(silent: Bool = false) async {
    if !silent {
        isLoading = true
    }
    // ... existing load logic
    if !silent {
        isLoading = false
    }
}
```

### Phase 2: Add iCloud Refresh Suppression

**File:** `SettingsViewModel.swift`

1. Add `suppressiCloudRefresh` flag
2. Set flag before destructive operations (delete, import)
3. Clear flag after a short delay

```swift
public private(set) var suppressiCloudRefresh = false

public func deleteAllData() async -> DeleteAllDataResult {
    suppressiCloudRefresh = true
    defer { clearSuppressionAfterDelay() }
    // ... existing logic
}

private func clearSuppressionAfterDelay() {
    Task {
        try? await Task.sleep(for: .seconds(2))
        suppressiCloudRefresh = false
    }
}
```

**File:** `SettingsView.swift`

3. Check suppression flag in iCloud notification handler

```swift
.onReceive(NotificationCenter.default.publisher(for: .iCloudDidSyncRemoteChanges)) { _ in
    guard !vm.suppressiCloudRefresh else { return }
    // ... existing logic with silent: true
}
```

### Phase 3: Remove Redundant Refresh Calls

**File:** `SettingsView.swift`

1. Remove redundant `.onAppear` refresh calls (lines 219-223) - already done by `.task`

```swift
// REMOVE these lines:
Task { await vm.refreshNotificationStatus() }
Task { await vm.refreshLocationStatus() }
Task { await vm.refreshPremiumStatus() }
Task { await vm.refreshiCloudStatus() }
```

2. Remove redundant `load()` call in Paywall `.onDisappear` - keep only `refreshSubscriptionStatus()`

```swift
.onDisappear {
    Task {
        try? await Task.sleep(nanoseconds: 100_000_000)
        await vm.refreshSubscriptionStatus()
        // REMOVE: await vm.load()
    }
}
```

### Phase 4: Make iCloud Sync Handler Use Silent Loading

**File:** `SettingsView.swift`

```swift
.onReceive(NotificationCenter.default.publisher(for: .iCloudDidSyncRemoteChanges)) { _ in
    guard !vm.suppressiCloudRefresh else { return }
    guard !vm.isToastActive else {
        // ... existing deferred refresh logic, but with silent: true
        await vm.load(silent: true)
        return
    }
    Task {
        await vm.load(silent: true)  // ← Silent load prevents UI flicker
    }
}
```

### Phase 5: Update Import to Use Suppression

**File:** `SettingsViewModel.swift`

```swift
public func importData(jsonString: String) async {
    suppressiCloudRefresh = true
    defer { clearSuppressionAfterDelay() }

    isImportingData = true
    // ... existing import logic
    // Note: load() here can remain non-silent since user expects reload after import
}
```

## Expected Results

### Before
- Delete All Data: 3 refreshes, UI flicker, potential sheet dismissal
- Profile updates: May trigger iCloud notification → unexpected reload
- Paywall dismiss: 2 redundant refresh cycles

### After
- Delete All Data: 1 refresh (immediate profile update only)
- Profile updates: No unexpected reloads from iCloud notification
- Paywall dismiss: 1 targeted refresh (subscription status only)

## Testing Checklist

- [ ] Delete All Data: Verify single refresh, no flicker
- [ ] Update profile name: Verify no unexpected refresh
- [ ] Update gender/age: Verify toast shows without page reload
- [ ] Change avatar: Verify image picker doesn't dismiss unexpectedly
- [ ] Open paywall, make purchase, dismiss: Verify subscription updates without full reload
- [ ] Import data: Verify proper reload after import completes
- [ ] Pull-to-refresh: Verify still works with loading indicator
- [ ] iCloud sync from another device: Verify silent update without flicker

## Files to Modify

1. `Ritualist/Features/Settings/Presentation/SettingsViewModel.swift`
   - Add `suppressiCloudRefresh` property
   - Add `silent` parameter to `load()`
   - Update `deleteAllData()` and `importData()` to set suppression flag

2. `Ritualist/Features/Settings/Presentation/SettingsView.swift`
   - Update iCloud notification handler to check suppression and use silent load
   - Remove redundant `.onAppear` refresh calls
   - Remove redundant `load()` from paywall `.onDisappear`
