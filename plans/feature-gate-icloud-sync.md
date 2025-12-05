# Feature Gate iCloud Sync with Settings Toggle

## Summary
Add iCloud sync as a premium feature with a user-controlled toggle in Settings. Free users get local-only storage. Premium users can enable/disable sync via toggle (requires app restart).

## Requirements
- **Premium + Toggle**: Only premium users see the toggle
- **Keep local copy**: Data stays on device when sync disabled
- **Restart acceptable**: Toggle change takes effect on next app launch

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         App Startup                             │
├─────────────────────────────────────────────────────────────────┤
│  1. Read UserDefaults: iCloudSyncEnabled (default: true)        │
│  2. Read UserDefaults: premium status cache (bypass DI)         │
│  3. Determine sync mode:                                        │
│     - Premium + Toggle ON  → CloudKit config                    │
│     - Premium + Toggle OFF → Local-only config                  │
│     - Free user           → Local-only config (forced)          │
│  4. Initialize PersistenceContainer with appropriate config     │
└─────────────────────────────────────────────────────────────────┘
```

## Critical Issues Identified

### Issue 1: Premium Check Timing (Chicken-and-Egg Problem)

**Problem:** `PersistenceContainer.init()` needs to know premium status, but `SecureSubscriptionService` is registered via DI Container, which may depend on `PersistenceContainer` being initialized first.

**Solution:** Read premium status directly from UserDefaults at startup, bypassing DI:

```swift
// In PersistenceContainer.init()
private static func checkPremiumStatusSync() -> Bool {
    // Read from the same UserDefaults key that MockSecureSubscriptionService uses
    // Key: "secure_mock_purchases" → Array of product IDs
    let purchases = UserDefaults.standard.stringArray(forKey: "secure_mock_purchases") ?? []
    return !purchases.isEmpty
}
```

**Note:** This duplicates the logic from `MockSecureSubscriptionService.isPremiumUser()`, but is necessary to break the DI circular dependency. In production with StoreKit, we'd read from Keychain or a cached entitlement flag.

### Issue 2: Data Migration Between Store Files

**Problem:** SwiftData creates **separate database files** per ModelConfiguration:
- `CloudKit.store` → CloudKit-synced entities (when sync ON)
- `LocalAll.store` → Same entities stored locally (when sync OFF)

**When toggling sync OFF:** Data in `CloudKit.store` becomes inaccessible
**When toggling sync ON:** Data in `LocalAll.store` becomes inaccessible

**Solution:** Single-store approach - always use ONE store file, just change CloudKit sync behavior:

```swift
// Instead of two separate configs for the same entities:
// ❌ CloudKit.store (sync enabled)
// ❌ LocalAll.store (sync disabled)

// Use ONE store with dynamic CloudKit setting:
// ✅ Habits.store (CloudKit enabled OR disabled based on toggle)

public static func habitConfiguration(syncEnabled: Bool) -> ModelConfiguration {
    ModelConfiguration(
        "Habits",  // Same name = same store file
        schema: Schema(cloudKitSyncedTypes),
        cloudKitDatabase: syncEnabled
            ? .private(iCloudConstants.containerIdentifier)
            : .none
    )
}
```

**Key Insight:** By using the same configuration NAME, SwiftData uses the same store file. The `cloudKitDatabase` parameter only affects whether sync is active, not where data is stored.

**Important Limitation:** This needs verification. SwiftData may still create different files based on CloudKit setting. If so, we need explicit migration:

```swift
// Migration service to copy data between stores
public func migrateData(from sourceConfig: ModelConfiguration,
                         to targetConfig: ModelConfiguration) async throws {
    // 1. Open source container (read-only)
    // 2. Fetch all entities
    // 3. Insert into target container
    // 4. Delete from source (optional)
}
```

## Implementation Steps

### Step 1: Add Feature Type
**File:** `RitualistCore/Sources/RitualistCore/Enums/Paywall/FeatureType.swift`

```swift
public enum FeatureType: String, CaseIterable {
    case unlimitedHabits = "unlimited_habits"
    case advancedAnalytics = "advanced_analytics"
    case customReminders = "custom_reminders"
    case dataExport = "data_export"
    case iCloudSync = "icloud_sync"  // NEW

    public var displayName: String {
        switch self {
        // ... existing cases
        case .iCloudSync: return "iCloud Sync"
        }
    }
}
```

### Step 2: Add UserDefaults Key
**File:** `RitualistCore/Sources/RitualistCore/Constants/UserDefaultsKeys.swift`

```swift
public static let iCloudSyncEnabled = "com.ritualist.iCloudSyncEnabled"
```

### Step 3: Update Feature Gating Services
**Files to modify (only sync services are actually used):**
- `RitualistCore/Sources/RitualistCore/Services/FeatureGatingService.swift` (protocol)
- `RitualistCore/Sources/RitualistCore/Services/DefaultFeatureGatingService.swift`
- `RitualistCore/Sources/RitualistCore/Services/MockFeatureGatingService.swift`
- `RitualistCore/Sources/RitualistCore/Services/BuildConfigFeatureGatingService.swift`

**NOTE:** The async `FeatureGatingBusinessService` implementations exist but are **NOT USED** anywhere in the codebase (registered in DI but never injected). Skip these files.

Add to protocols and implementations:
```swift
var hasICloudSync: Bool { get }
```

In `isFeatureAvailable(_:)`:
```swift
case .iCloudSync:
    return hasICloudSync
```

### Step 4: Add Feature Blocked Message
**File:** `RitualistCore/Sources/RitualistCore/Utilities/FeatureGatingConstants.swift`

```swift
case .iCloudSync:
    return Messages.iCloudSync

static let iCloudSync = "iCloud sync keeps your habits in sync across all your devices. Upgrade to Pro to enable cloud sync."
```

### Step 5: Create iCloud Sync Preference Service
**File (NEW):** `RitualistCore/Sources/RitualistCore/Services/ICloudSyncPreferenceService.swift`

```swift
public protocol ICloudSyncPreferenceServiceProtocol: Sendable {
    /// Whether user has enabled iCloud sync (user preference)
    var isICloudSyncEnabled: Bool { get }

    /// Set iCloud sync preference (requires restart)
    func setICloudSyncEnabled(_ enabled: Bool)

    /// Whether sync should actually be active (premium + user preference)
    func shouldSyncBeActive(isPremium: Bool) -> Bool
}

public final class ICloudSyncPreferenceService: ICloudSyncPreferenceServiceProtocol, Sendable {
    public static let shared = ICloudSyncPreferenceService()

    private init() {}

    public var isICloudSyncEnabled: Bool {
        // Default to true for new users (opt-out model)
        UserDefaults.standard.object(forKey: UserDefaultsKeys.iCloudSyncEnabled) as? Bool ?? true
    }

    public func setICloudSyncEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: UserDefaultsKeys.iCloudSyncEnabled)
    }

    public func shouldSyncBeActive(isPremium: Bool) -> Bool {
        isPremium && isICloudSyncEnabled
    }
}
```

### Step 6: Update PersistenceConfiguration
**File:** `RitualistCore/Sources/RitualistCore/Storage/PersistenceConfiguration.swift`

**NOTE:** This file now exists from the local-only PersonalityAnalysis PR. Update it to support dynamic sync toggling.

Use single-store approach to prevent data orphaning:

```swift
// Add new method to existing file:

/// Get configuration for syncable entities based on whether sync is enabled
/// Uses SAME store name regardless of sync setting to prevent data orphaning
/// - Parameter syncEnabled: Whether CloudKit sync should be active
public static func syncableEntitiesConfiguration(syncEnabled: Bool) -> ModelConfiguration {
    ModelConfiguration(
        "CloudKit",  // SAME name always = same store file
        schema: Schema(cloudKitSyncedTypes),
        cloudKitDatabase: syncEnabled
            ? .private(iCloudConstants.containerIdentifier)
            : .none  // Same store, just no sync
    )
}

/// Get all configurations for the container based on sync preference
public static func allConfigurations(syncEnabled: Bool) -> [ModelConfiguration] {
    [
        syncableEntitiesConfiguration(syncEnabled: syncEnabled),
        localConfiguration  // PersonalityAnalysis - always local
    ]
}
```

**Existing code to keep:**
- `cloudKitSyncedTypes` - list of syncable entity types
- `localOnlyTypes` - PersonalityAnalysis only
- `localConfiguration` - unchanged, always local
- `cloudKitConfiguration` - keep for reference, but use `syncableEntitiesConfiguration(syncEnabled:)` at runtime

**Key Point:** By keeping the configuration NAME as "CloudKit" even when sync is disabled, we ensure the same store file is used. Only the `cloudKitDatabase` parameter changes, which controls whether sync happens - not where data is stored.

### Step 7: Update PersistenceContainer
**File:** `RitualistCore/Sources/RitualistCore/Storage/PersistenceContainer.swift`

Modify initialization to check sync state:

```swift
public init() throws {
    // Determine if sync should be active
    // Read directly from UserDefaults to avoid DI circular dependency
    let isPremium = Self.checkPremiumStatusFromCache()
    let syncPreference = ICloudSyncPreferenceService.shared.isICloudSyncEnabled
    let shouldSync = isPremium && syncPreference

    Self.logger.log(
        "Initializing PersistenceContainer",
        level: .info,
        category: .system,
        metadata: [
            "is_premium": isPremium,
            "user_sync_preference": syncPreference,
            "sync_active": shouldSync
        ]
    )

    // Use single-store approach with dynamic CloudKit setting
    let configurations = PersistenceConfiguration.allConfigurations(syncEnabled: shouldSync)

    container = try ModelContainer(
        for: schema,
        migrationPlan: RitualistMigrationPlan.self,
        configurations: configurations
    )
    // ... rest of init
}

/// Synchronous premium check at startup - reads directly from UserDefaults
/// This bypasses DI to avoid circular dependency (PersistenceContainer ↔ SubscriptionService)
/// Must mirror the logic in MockSecureSubscriptionService.isPremiumUser()
private static func checkPremiumStatusFromCache() -> Bool {
    // Same key used by MockSecureSubscriptionService
    let purchases = UserDefaults.standard.stringArray(forKey: "secure_mock_purchases") ?? []
    return !purchases.isEmpty

    // TODO: For production StoreKit implementation, read from:
    // - Keychain cached entitlement, OR
    // - UserDefaults premium status flag set by StoreKit transaction observer
}
```

### Step 8: Add Toggle to Settings UI
**File:** `Ritualist/Features/Settings/Presentation/Components/iCloudSyncSectionView.swift`

Add toggle (only visible to premium users):

```swift
struct ICloudSyncSectionView: View {
    @Bindable var vm: SettingsViewModel
    @State private var showRestartAlert = false

    var body: some View {
        Section {
            // Existing status UI...

            // Toggle (premium only)
            if vm.isPremiumUser {
                Toggle("Enable iCloud Sync", isOn: $vm.iCloudSyncEnabled)
                    .onChange(of: vm.iCloudSyncEnabled) { _, newValue in
                        vm.setICloudSyncEnabled(newValue)
                        showRestartAlert = true
                    }
            }
        } header: {
            Text("iCloud Sync")
        } footer: {
            if !vm.isPremiumUser {
                Text("Upgrade to Pro to sync your habits across all your devices.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .alert("Restart Required", isPresented: $showRestartAlert) {
            Button("OK") { }
        } message: {
            Text("Please restart the app for this change to take effect.")
        }
    }
}
```

### Step 9: Update SettingsViewModel
**File:** `Ritualist/Features/Settings/Presentation/SettingsViewModel.swift`

Add state and methods:

```swift
// Add injected service
@ObservationIgnored @Injected(\.iCloudSyncPreferenceService) var iCloudSyncPreferenceService

// Add computed property
public var iCloudSyncEnabled: Bool {
    get { iCloudSyncPreferenceService.isICloudSyncEnabled }
    set { } // Handled by setICloudSyncEnabled
}

public func setICloudSyncEnabled(_ enabled: Bool) {
    iCloudSyncPreferenceService.setICloudSyncEnabled(enabled)
    userActionTracker.track(.custom(event: "icloud_sync_toggled", parameters: ["enabled": enabled]))
}
```

### Step 10: Register in DI Container
**File:** `Ritualist/DI/Container+Services.swift`

```swift
var iCloudSyncPreferenceService: Factory<ICloudSyncPreferenceServiceProtocol> {
    self { ICloudSyncPreferenceService.shared }
        .singleton
}
```

## Files to Modify

| File | Change |
|------|--------|
| `FeatureType.swift` | Add `.iCloudSync` case |
| `UserDefaultsKeys.swift` | Add `iCloudSyncEnabled` key |
| `FeatureGatingService.swift` | Add `hasICloudSync` property |
| `DefaultFeatureGatingService.swift` | Implement `hasICloudSync` |
| `MockFeatureGatingService.swift` | Implement `hasICloudSync` |
| `BuildConfigFeatureGatingService.swift` | Implement `hasICloudSync` |
| `FeatureGatingConstants.swift` | Add blocked message |
| `PersistenceConfiguration.swift` | Add `syncableEntitiesConfiguration(syncEnabled:)` and `allConfigurations(syncEnabled:)` methods (file already exists) |
| `PersistenceContainer.swift` | Check sync state at init, add `checkPremiumStatusFromCache()` |
| `iCloudSyncSectionView.swift` | Add toggle UI |
| `SettingsViewModel.swift` | Add toggle state/methods |
| `Container+Services.swift` | Register preference service |

**Skipped (unused async services):**
- `FeatureGatingBusinessService.swift`
- `DefaultFeatureGatingBusinessService.swift`
- `MockFeatureGatingBusinessService.swift`
- `BuildConfigFeatureGatingBusinessService.swift`

## New Files

| File | Purpose |
|------|---------|
| `ICloudSyncPreferenceService.swift` | Manage user's sync preference |

## Edge Cases to Handle

1. **Subscription expires**: Next app launch detects non-premium, sync disabled but data preserved in same store
2. **First launch**: Default sync enabled (true), but only active if premium
3. **Toggle while offline**: Works fine, just sets UserDefaults; sync resumes when back online
4. **Data continuity**: Single-store approach ensures data persists regardless of sync toggle
5. **Re-enabling sync after offline period**:
   - Local changes made while sync OFF will sync up when toggle ON
   - CloudKit handles merge automatically (uses existing deduplication logic)
6. **Premium status cache stale**:
   - If user buys subscription but cache not updated, restart fixes it
   - Consider adding observer for StoreKit transaction updates
7. **CloudKit quota exceeded**:
   - Sync fails but data stays local
   - User can disable sync to prevent retry loops

## Verification Required

### Single-Store Approach Verification
Before implementation, verify that SwiftData uses the same store file when only `cloudKitDatabase` changes:

```swift
// Test: Do these two configs use the same store file?
let configA = ModelConfiguration("CloudKit", schema: schema, cloudKitDatabase: .private(...))
let configB = ModelConfiguration("CloudKit", schema: schema, cloudKitDatabase: .none)

// Expected: Both use "CloudKit.store"
// If not: Need explicit data migration between stores
```

**Test procedure:**
1. Create app with sync ON, add some habits
2. Check file system for `CloudKit.store`
3. Restart with sync OFF
4. Check if habits still visible (same store) or gone (different store)

### Fallback Plan
If SwiftData creates different stores based on `cloudKitDatabase` setting:
1. Implement `SyncMigrationService` to copy data between stores
2. Run migration on each app launch when toggle state differs from last launch
3. Store last toggle state in UserDefaults to detect changes

## Testing Checklist

### Feature Gating
- [ ] Free user: No toggle visible, local-only storage, no CloudKit activity
- [ ] Premium user: Toggle visible, default ON
- [ ] Premium user toggle OFF: Restart alert shown
- [ ] Premium user toggle ON: Restart alert shown

### Data Persistence (Critical)
- [ ] **Single-store verification**: Habits persist when toggling sync OFF then ON
- [ ] Data created while sync OFF persists after restart
- [ ] Data created while sync ON persists when toggling OFF

### Subscription Transitions
- [ ] Premium → Free: Next launch disables sync, data preserved
- [ ] Free → Premium: Toggle appears, can enable sync
- [ ] Premium status cache updates correctly after purchase

### CloudKit Behavior
- [ ] Sync ON: Changes sync to other devices
- [ ] Sync OFF: No CloudKit network activity
- [ ] Sync OFF → ON: Pending local changes sync up
