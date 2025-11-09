# Migration Plan: Remove Subscription Fields from Database (Schema V8)

## Overview
Remove subscription data from UserProfile database, establish SubscriptionService as single source of truth. Delete unused SchemaV8 (habit priority) and create new V8 for this change.

## Current State
- **Active Schema**: V7 (location-aware habits)
- **Prepared but Unused**: V8 (habit priority feature - to be deleted)
- **Target**: New V8 (subscription field removal)

## Problem Being Solved
**Two Sources of Truth Bug:**
- Purchases update `MockSecureSubscriptionService` (UserDefaults)
- Settings UI reads from `UserProfile.subscriptionPlan` (SwiftData database)
- Database NOT updated after purchase → Settings doesn't refresh

## Solution: Single Source of Truth
Remove subscription fields from database entirely. Query `SubscriptionService` for all subscription state.

## Files That Need Changes

### Files to DELETE:
1. `RitualistCore/Sources/RitualistCore/Storage/SchemaV8.swift` (unused habit priority schema)

### Files to CREATE:
1. `RitualistCore/Sources/RitualistCore/Storage/SchemaV8.swift` (new - subscription removal)

### Files to MODIFY:
1. `RitualistCore/Sources/RitualistCore/Services/Subscription/SecureSubscriptionService.swift` - Add protocol methods
2. `RitualistCore/Sources/RitualistCore/Services/MockSecureSubscriptionService.swift` - Implement new methods
3. `RitualistCore/Sources/RitualistCore/Services/StoreKitSubscriptionService.swift` - Implement new methods
4. `RitualistCore/Sources/RitualistCore/Storage/MigrationPlan.swift` - Add V8 to schemas and stages
5. `RitualistCore/Sources/RitualistCore/Storage/ActiveSchema.swift` - Update to V8 type aliases
6. `RitualistCore/Sources/RitualistCore/Storage/PersistenceContainer.swift` - Update version comments and logs
7. `Ritualist/Features/Settings/Presentation/SettingsViewModel.swift` - Add service-based subscription properties
8. `Ritualist/Features/Settings/Presentation/Components/SubscriptionManagementSectionView.swift` - Use vm properties
9. `Ritualist/Features/Settings/Presentation/SettingsView.swift` - Call refreshSubscriptionStatus()
10. `SCHEMA-MIGRATION-GUIDE.md` - Update current version metadata

## Steps

### 1. Delete Unused Schema V8
**File to Remove:**
- `RitualistCore/Sources/RitualistCore/Storage/SchemaV8.swift`

**Reason:**
This schema was prepared but never activated (habit priority feature). We'll reuse V8 numbering for our subscription migration.

### 2. Create New Schema V8 (Subscription Field Removal)

**File to Create:**
- `RitualistCore/Sources/RitualistCore/Storage/SchemaV8.swift`

**Changes from V7:**
```swift
// V7 UserProfile (REMOVE these fields in V8)
public var subscriptionPlan: String = "free"
public var subscriptionExpiryDate: Date?

// V8 UserProfile (these fields removed)
// All other V7 fields remain unchanged:
// - id, name, createdAt, updatedAt
// - appearance, weekStartDay, displayTimezoneMode
// - avatarImageData
// - location properties (latitude, longitude, locationName, etc.)
```

**Models to Migrate:**
- `UserProfileModelV8` - Remove subscription fields
- `HabitModelV8` - Copy from V7 (no changes)
- `HabitCategoryModelV8` - Copy from V7 (no changes)
- `HabitLogModelV8` - Copy from V7 (no changes)

### 3. Enhance SubscriptionService Protocol

**File to Update:**
- `RitualistCore/Sources/RitualistCore/Services/Subscription/SecureSubscriptionService.swift`

**New Methods:**
```swift
/// Get current subscription plan
func getCurrentSubscriptionPlan() async -> SubscriptionPlan

/// Get subscription expiry date (nil for lifetime/free)
func getSubscriptionExpiryDate() async -> Date?
```

### 4. Implement in Both Services

#### MockSecureSubscriptionService
**File:** `RitualistCore/Sources/RitualistCore/Services/MockSecureSubscriptionService.swift`

**Implementation:**
```swift
func getCurrentSubscriptionPlan() async -> SubscriptionPlan {
    // Map validatedPurchases to SubscriptionPlan enum
    if validatedPurchases.contains("com.ritualist.lifetime") {
        return .lifetime
    } else if validatedPurchases.contains("com.ritualist.annual") {
        return .annual
    } else if validatedPurchases.contains("com.ritualist.monthly") {
        return .monthly
    }
    return .free
}

func getSubscriptionExpiryDate() async -> Date? {
    // For mocking: calculate expiry based on product type
    let plan = await getCurrentSubscriptionPlan()
    switch plan {
    case .monthly:
        return Date().addingTimeInterval(30 * 24 * 60 * 60)
    case .annual:
        return Date().addingTimeInterval(365 * 24 * 60 * 60)
    case .lifetime, .free:
        return nil
    }
}
```

#### StoreKitSubscriptionService
**File:** `RitualistCore/Sources/RitualistCore/Services/StoreKitSubscriptionService.swift`

**Implementation:**
```swift
func getCurrentSubscriptionPlan() async -> SubscriptionPlan {
    // Query Transaction.currentEntitlements
    for await result in Transaction.currentEntitlements {
        if case .verified(let transaction) = result {
            switch transaction.productID {
            case "com.ritualist.lifetime":
                return .lifetime
            case "com.ritualist.annual":
                return .annual
            case "com.ritualist.monthly":
                return .monthly
            default:
                continue
            }
        }
    }
    return .free
}

func getSubscriptionExpiryDate() async -> Date? {
    for await result in Transaction.currentEntitlements {
        if case .verified(let transaction) = result,
           let expirationDate = transaction.expirationDate {
            return expirationDate
        }
    }
    return nil
}
```

### 5. Update SettingsViewModel

**File:** `Ritualist/Features/Settings/Presentation/SettingsViewModel.swift`

**Changes:**
```swift
// Add injected dependency
@ObservationIgnored @Injected(\.subscriptionService) var subscriptionService

// Remove direct profile access, add computed properties
public var subscriptionPlan: SubscriptionPlan {
    cachedSubscriptionPlan
}

public var subscriptionExpiryDate: Date? {
    cachedSubscriptionExpiryDate
}

// Add caching to avoid async issues
private var cachedSubscriptionPlan: SubscriptionPlan = .free
private var cachedSubscriptionExpiryDate: Date?

// Update load() method
public func load() async {
    isLoading = true
    error = nil
    do {
        profile = try await loadProfile.execute()
        hasNotificationPermission = await checkNotificationStatus.execute()
        locationAuthStatus = await getLocationAuthStatus.execute()
        cachedPremiumStatus = await checkPremiumStatus.execute()
        lastSyncDate = await getLastSyncDate.execute()
        await refreshiCloudStatus()

        // NEW: Cache subscription data from service
        cachedSubscriptionPlan = await subscriptionService.getCurrentSubscriptionPlan()
        cachedSubscriptionExpiryDate = await subscriptionService.getSubscriptionExpiryDate()
    } catch {
        // ... error handling
    }
    isLoading = false
}

// Add refresh method for after purchases
public func refreshSubscriptionStatus() async {
    cachedSubscriptionPlan = await subscriptionService.getCurrentSubscriptionPlan()
    cachedSubscriptionExpiryDate = await subscriptionService.getSubscriptionExpiryDate()
}
```

### 6. Update UI Components

**File:** `Ritualist/Features/Settings/Presentation/Components/SubscriptionManagementSectionView.swift`

**Changes:**
```swift
// BEFORE (reading from profile)
vm.profile.subscriptionPlan
vm.profile.subscriptionExpiryDate

// AFTER (reading from ViewModel computed properties)
vm.subscriptionPlan
vm.subscriptionExpiryDate
```

**File:** `Ritualist/Features/Settings/Presentation/SettingsView.swift`

**Update paywall dismissal:**
```swift
.sheet(item: $vm.paywallItem) { item in
    PaywallView(vm: item.viewModel)
        .onDisappear {
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000)
                await vm.load()
                await vm.refreshSubscriptionStatus() // NEW: Refresh from service
            }
        }
}
```

### 7. Activate Schema V8

**File:** `RitualistCore/Sources/RitualistCore/Storage/ActiveSchema.swift`

**Change:**
```swift
// BEFORE
public typealias ActiveHabitModel = HabitModelV7
public typealias ActiveHabitCategoryModel = HabitCategoryModelV7
public typealias ActiveUserProfileModel = UserProfileModelV7
public typealias ActiveHabitLogModel = HabitLogModelV7

// AFTER
public typealias ActiveHabitModel = HabitModelV8
public typealias ActiveHabitCategoryModel = HabitCategoryModelV8
public typealias ActiveUserProfileModel = UserProfileModelV8
public typealias ActiveHabitLogModel = HabitLogModelV8
```

### 8. Update PersistenceContainer Documentation

**File:** `RitualistCore/Sources/RitualistCore/Storage/PersistenceContainer.swift`

**Changes:**
Update schema version references and migration descriptions:

```swift
// Line 23: Update comment
/// Uses versioned schema (SchemaV8) with migration plan to safely handle schema changes.

// Line 26: Update log message
Self.logger.info("🔍 Initializing PersistenceContainer with versioned schema (V8)")

// Line 77-78: Update schema version comments
Self.logger.info("📋 Creating Schema from SchemaV8")
Self.logger.debug("   SchemaV8 models: \(SchemaV8.models.map { String(describing: $0) })")

// Line 80-81: Update schema initialization
let schema = Schema(versionedSchema: SchemaV8.self)
Self.logger.debug("   Schema version: \(SchemaV8.versionIdentifier)")

// Line 84: Update migration plan comment
Self.logger.info("   Migration plan will handle V2 → V3 → V4 → V5 → V6 → V7 → V8 upgrades automatically")

// Line 88: Update migration chain comment
// Migrations: V2 → V3 (adds isPinned) → V4 (replaces with notes) → V5 (adds lastCompletedDate) → V6 (adds archivedDate) → V7 (adds location support) → V8 (removes subscription fields)

// Line 95: Update success log
Self.logger.info("✅ Successfully initialized ModelContainer with versioned schema (V8)")

// Line 196-197: Add V7→V8 migration description
case "7.0.0 → 8.0.0":
    return "Removed subscription fields from database - subscription status now queried from StoreKit service for improved security and accuracy."
```

### 9. Update SCHEMA-MIGRATION-GUIDE.md

**File:** `SCHEMA-MIGRATION-GUIDE.md`

**Changes:**
```markdown
# Line 9: Update current version
**Current Schema Version**: V8

# Line 412-414: Update metadata
**Last Updated**: November 9, 2025
**Current Schema Version**: V8
**Total Migrations**: 7 (V2→V3, V3→V4, V4→V5, V5→V6, V6→V7, V7→V8)
```

### 8. Testing

**Migration Testing:**
1. Start with V7 database containing subscription data
2. Activate V8 schema
3. Verify migration completes without errors
4. Verify no data loss (other profile fields intact)
5. Check Debug Menu → Migration History shows V7→V8

**Subscription Display Testing:**
1. Mock purchase monthly subscription
2. Verify Settings shows "Monthly" status
3. Verify expiry date displays correctly
4. Restart app - verify subscription persists

**Purchase Flow Testing:**
1. Open Settings → Subscribe to Pro
2. Purchase mock product
3. Verify paywall dismisses
4. **CRITICAL**: Verify Settings subscription section updates immediately
5. Navigate to Habits → Verify banner disappears

**Cross-Screen Consistency:**
1. Purchase from Habits screen
2. Navigate to Settings → Verify shows subscribed
3. Purchase from Settings screen
4. Navigate to Habits → Verify banner gone

## Benefits

1. **Single Source of Truth** - No more sync bugs between database and service
2. **Industry Standard** - Service-based subscription management (StoreKit 2)
3. **Migration Practice** - Experience for upcoming iCloud sync migrations
4. **Security** - Production uses StoreKit receipts, not local database
5. **Cleaner Schema** - No gaps in version numbering (V7→V8)
6. **Testability** - Mock service for development, StoreKit for production

## Risks and Mitigations

**Risk 1: Migration Data Loss**
- **Mitigation**: V8 migration only removes subscription fields, all other profile data preserved
- **Testing**: Verify migration in Debug-AllFeatures before Release build

**Risk 2: Subscription State Lost During Migration**
- **Impact**: Minimal - mock purchases in UserDefaults persist independently
- **Production**: StoreKit always queryable, never stored locally

**Risk 3: UI Not Updating After Purchase**
- **Mitigation**: Call `refreshSubscriptionStatus()` after paywall dismissal
- **Testing**: Verify Settings updates in both purchase flows (Settings and Habits)

## Future Enhancements

1. **Server-Side Receipt Validation** - For production security
2. **Subscription Analytics** - Track conversion rates, churn
3. **Grace Period Handling** - Apple billing retry logic
4. **Family Sharing Support** - StoreKit 2 feature
5. **Promotional Offers** - Discounts, free trials

## Implementation Checklist

Based on `SCHEMA-MIGRATION-GUIDE.md`, verify all steps before committing:

### Schema Creation
- [ ] Delete unused `SchemaV8.swift` (habit priority feature)
- [ ] Create new `SchemaV8.swift` with subscription fields removed
- [ ] Schema version set to `Schema.Version(8, 0, 0)`
- [ ] All models copied from V7 (Habit, HabitLog, Category, UserProfile, etc.)
- [ ] Remove `subscriptionPlan` from `UserProfileModelV8`
- [ ] Remove `subscriptionExpiryDate` from `UserProfileModelV8`
- [ ] All initializers updated (remove subscription parameters)
- [ ] Type aliases added for all V8 models

### Domain Entity Updates
- [ ] `UserProfile` entity unchanged (already has subscription fields - not used)
- [ ] `toEntity()` method updated (don't set subscription fields from database)
- [ ] `fromEntity()` method updated (don't save subscription fields to database)

### Service Layer Enhancements
- [ ] `SecureSubscriptionService` protocol updated with new methods
- [ ] `getCurrentSubscriptionPlan()` implemented in `MockSecureSubscriptionService`
- [ ] `getSubscriptionExpiryDate()` implemented in `MockSecureSubscriptionService`
- [ ] `getCurrentSubscriptionPlan()` implemented in `StoreKitSubscriptionService`
- [ ] `getSubscriptionExpiryDate()` implemented in `StoreKitSubscriptionService`

### Migration Plan Updates
- [ ] `SchemaV8.self` added to `MigrationPlan.schemas` array
- [ ] `migrateV7toV8` added to `MigrationPlan.stages` array
- [ ] Migration stage implemented as lightweight
- [ ] Documentation comments updated with V7→V8 description

### ViewModel Updates
- [ ] `SettingsViewModel` injected with `subscriptionService`
- [ ] Computed properties added: `subscriptionPlan`, `subscriptionExpiryDate`
- [ ] Caching properties added for subscription data
- [ ] `load()` method updated to cache subscription data
- [ ] `refreshSubscriptionStatus()` method added

### UI Updates
- [ ] `SubscriptionManagementSectionView` uses `vm.subscriptionPlan`
- [ ] `SubscriptionManagementSectionView` uses `vm.subscriptionExpiryDate`
- [ ] `SettingsView` paywall dismissal calls `refreshSubscriptionStatus()`
- [ ] All subscription UI removed from profile-based access

### Activation
- [ ] `ActiveSchema.swift` updated to V8 type aliases
- [ ] `PersistenceContainer.swift` schema version comments updated
- [ ] `PersistenceContainer.swift` log messages updated to V8
- [ ] `PersistenceContainer.swift` migration chain comment updated
- [ ] `PersistenceContainer.swift` V7→V8 change description added
- [ ] `SCHEMA-MIGRATION-GUIDE.md` current version updated to V8
- [ ] `SCHEMA-MIGRATION-GUIDE.md` total migrations updated to 7

### Testing
- [ ] Build succeeds with V8 schema
- [ ] Migration modal displays during V7→V8 upgrade
- [ ] V7 database migrates successfully to V8
- [ ] All profile data preserved (name, appearance, location, etc.)
- [ ] Subscription status displays correctly from service
- [ ] Mock purchases persist across app restarts
- [ ] Settings updates after purchase from Settings screen
- [ ] Settings updates after purchase from Habits screen
- [ ] Migration history shows V7→V8 in Debug Menu

## Related Documentation

- `docs/STOREKIT-IMPLEMENTATION-PLAN.md` - Overall StoreKit implementation
- `CLAUDE.md` - Architecture standards and migration patterns
- `SCHEMA-MIGRATION-GUIDE.md` - Complete schema migration procedures
- SwiftData migration best practices (pending iCloud sync work)
