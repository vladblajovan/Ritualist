# UserProfile Subscription Fields Cleanup Plan

## Problem Statement

UserProfile domain entity still has `subscriptionPlan` and `subscriptionExpiryDate` fields that were removed from the database schema in V8. This creates a critical mismatch between the domain layer and data layer.

**Database (SchemaV8)**: ❌ NO subscription fields
**Domain (UserProfile.swift)**: ✅ HAS subscription fields
**Result**: CloudKit mapper tries to sync non-existent data, computed properties use default values

## Root Cause

In SchemaV8 migration, subscription fields were removed from UserProfileModel to establish SubscriptionService as the single source of truth. However, the domain entity (UserProfile.swift) was not updated, leaving vestigial fields that:

1. Are always set to defaults (.free, nil) when loading from database (SchemaV8.swift:444-445)
2. Cause UserProfileCloudMapper to sync meaningless default values
3. Create confusion about where subscription status comes from
4. Break computed properties like `hasActiveSubscription` (always returns false)

## Files Requiring Changes

### 1. **UserProfile.swift** - Remove subscription fields
- **File**: `/Users/vladblajovan/Developer/GitHub/Ritualist/RitualistCore/Sources/RitualistCore/Entities/UserProfile/UserProfile.swift`
- **Changes**:
  - Remove `subscriptionPlan: SubscriptionPlan` property
  - Remove `subscriptionExpiryDate: Date?` property
  - Remove computed property `hasActiveSubscription: Bool`
  - Remove computed property `isPremiumUser: Bool`
  - Update initializer to remove these parameters
  - Update `Codable`, `Hashable`, `Equatable` conformance (if explicit)

### 2. **SchemaV8.swift** - Remove default subscription values from mapper
- **File**: `/Users/vladblajovan/Developer/GitHub/Ritualist/RitualistCore/Sources/RitualistCore/Storage/SchemaV8.swift`
- **Changes**:
  - Line 444-445: Remove `subscriptionPlan: .free` and `subscriptionExpiryDate: nil` from toEntity()
  - Update toEntity() comment to remove subscription reference

### 3. **UserProfileCloudMapper.swift** - Remove subscription field mapping
- **File**: `/Users/vladblajovan/Developer/GitHub/Ritualist/RitualistCore/Sources/RitualistCore/Mappers/UserProfileCloudMapper.swift`
- **Changes**:
  - Remove `FieldKey.subscriptionPlan` and `FieldKey.subscriptionExpiryDate` (lines 39-40)
  - Remove subscription field mapping in `toCKRecord()` (lines 68, 77-79)
  - Remove subscription field parsing in `fromCKRecord()` (lines 139-146, 164, 201-202)
  - Update CloudKit schema version comment if needed

### 4. **SubscriptionManagementSectionView.swift** - Fix preview mocks
- **File**: `/Users/vladblajovan/Developer/GitHub/Ritualist/Ritualist/Features/Settings/Presentation/Components/SubscriptionManagementSectionView.swift`
- **Changes**:
  - Remove any `profile.subscriptionPlan = plan` assignments in preview mocks
  - Remove any `profile.subscriptionExpiryDate = expiryDate` assignments in preview mocks
  - Verify preview still compiles after UserProfile changes

### 5. **iCloudSyncSectionView.swift** - Already correct (no changes needed)
- **File**: `/Users/vladblajovan/Developer/GitHub/Ritualist/Ritualist/Features/Settings/Presentation/Components/iCloudSyncSectionView.swift`
- **Analysis**: This file has `loadProfile` and `saveProfile` UseCases but doesn't actually use subscription fields from profile
- **Action**: Verify no references to `profile.subscriptionPlan` or `profile.subscriptionExpiryDate`

### 6. **Old Schemas (V1-V7)** - NO CHANGES
- **Files**: SchemaV1.swift through SchemaV7.swift
- **Reason**: These schemas are only used during migration and need to maintain their historical structure
- **Action**: Leave subscription field handling intact in all old schema toEntity() methods

## Implementation Steps

1. ✅ Create this planning document
2. ⬜ Search for all usages of `profile.subscriptionPlan` and `profile.subscriptionExpiryDate` in codebase
3. ⬜ Update UserProfile.swift - Remove subscription fields and computed properties
4. ⬜ Update SchemaV8.swift - Remove default subscription values from toEntity()
5. ⬜ Update UserProfileCloudMapper.swift - Remove subscription field mapping
6. ⬜ Update SubscriptionManagementSectionView.swift - Fix preview mocks
7. ⬜ Verify iCloudSyncSectionView.swift - Confirm no subscription field usage
8. ⬜ Build and test - Ensure no compilation errors
9. ⬜ Commit changes with architecture violation fix

## Expected Impact

### Benefits:
- ✅ Domain entity matches database schema (consistency)
- ✅ Single source of truth: SubscriptionService is the sole authority
- ✅ CloudKit sync won't try to sync non-existent data when re-enabled
- ✅ Cleaner architecture - no vestigial fields
- ✅ Computed properties removed (were broken anyway)

### Risks:
- ⚠️ **Low Risk**: Subscription status is already queried from SubscriptionService everywhere in the app
- ⚠️ **Migration**: Old CloudKit records may have subscription fields, but mapper will ignore them (safe)
- ⚠️ **Breaking Change**: Any code directly accessing `profile.subscriptionPlan` will break (need to find and fix)

## Verification Checklist

After implementation:
- [ ] Build succeeds on all configurations (Debug/Release × AllFeatures/Subscription)
- [ ] No compiler errors about missing UserProfile fields
- [ ] SettingsViewModel still shows correct subscription status (from SubscriptionService)
- [ ] Preview mocks compile and display correctly
- [ ] No grep results for `profile.subscriptionPlan` or `profile.subscriptionExpiryDate` (except in old schemas)

## Related Issues

- **Architecture Violation**: SettingsViewModel directly injecting SubscriptionService (fixed in this PR)
- **Schema V8 Migration**: Removed subscription fields from database but not domain entity
- **CloudKit Sync**: Currently disabled, but mapper would fail when re-enabled

## Notes

- This cleanup should be done BEFORE re-enabling CloudKit sync
- Old schemas (V1-V7) maintain subscription fields for historical migration purposes only
- SubscriptionService remains the single source of truth via StoreKit 2
- UserProfile entity should only contain fields that are actually persisted in the database
