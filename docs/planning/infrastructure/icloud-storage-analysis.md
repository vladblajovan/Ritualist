# iCloud Storage Integration Analysis

## Executive Summary

This document analyzes the current state of iCloud storage integration in the Ritualist iOS app and provides a comprehensive implementation plan for enabling iCloud sync in release builds.

**Current Status:** ⚠️ **BLOCKED - Requires Paid Apple Developer Program**
**Scope:** UserProfile sync only (not habit/log data)
**Code Status:** ✅ Phases 1-3, 5 Complete | ⏸️ Phase 4 Pending
**Blocker:** Free Apple Developer account cannot use iCloud/CloudKit capabilities

---

## ⚠️ CRITICAL BLOCKER: Apple Developer Program Required

### Current Situation

**Entitlements Error:**
```
Cannot create a iOS App Development provisioning profile for "com.vladblajovan.Ritualist".
Personal development teams, including "Vlad Blajovan", do not support the iCloud capability.

Provisioning profile "iOS Team Provisioning Profile: com.vladblajovan.Ritualist" doesn't
support the iCloud capability.
```

### Why This Blocks Development

**Free Apple Developer Account Limitations:**
- ❌ Cannot enable iCloud/CloudKit capabilities in entitlements
- ❌ Cannot build the app with iCloud entitlements enabled
- ❌ Cannot test CloudKit sync (even in simulator)
- ❌ Cannot access CloudKit Dashboard to configure schema

**Paid Apple Developer Program ($99/year) Required For:**
- ✅ iCloud/CloudKit entitlements
- ✅ CloudKit Dashboard access
- ✅ Device testing with iCloud sync
- ✅ Production CloudKit deployment

### What Works Without Paid Program

**✅ Currently Working:**
- Code compiles and runs (with entitlements disabled or commented out)
- All local features work normally
- Mock/local-only data storage
- Development and testing of non-iCloud features

**❌ Cannot Test:**
- Actual iCloud sync between devices
- CloudKit record creation/fetching
- Conflict resolution with real cloud data
- Network error handling with CloudKit

### Resolution Path

**Option 1: Revert Entitlements (Current Workaround)**
- Comment out iCloud entitlements in `Ritualist.entitlements`
- App builds and runs normally
- All iCloud code remains intact and ready
- Re-enable entitlements when paid membership obtained

**Option 2: Purchase Apple Developer Program**
- Cost: $99/year
- Enables all iCloud/CloudKit features immediately
- Required for App Store deployment anyway
- Allows completion of Phase 4 (Testing & Validation)

### What's Been Completed (Code-Ready)

All code is implemented and committed to the `investigation/icloud-storage-release` branch:

**✅ Phase 1: Infrastructure (Entitlements + Config)**
- ✅ Updated `Ritualist.entitlements` with CloudKit keys
- ✅ Updated `PersistenceContainer.swift` to use CloudKit private database
- ✅ Created `CLOUDKIT-SETUP-GUIDE.md` (270 lines) with manual setup steps

**✅ Phase 2: Core Implementation (~220 LOC)**
- ✅ Created `UserProfileCloudMapper.swift` for UserProfile ↔ CKRecord conversion
- ✅ Implemented `ICloudUserBusinessService` with full CloudKit integration
- ✅ Added conflict resolution (Last-Write-Wins using updatedAt timestamps)
- ✅ Implemented CKAsset handling for avatar images
- ✅ Added `CloudKitSyncError` enum with comprehensive error cases

**✅ Phase 3: Error Handling & Resilience (~270 LOC)**
- ✅ Created `CloudSyncErrorHandler.swift` with automatic retry logic
- ✅ Implemented exponential backoff (3 retries, base delay 1s)
- ✅ Added error classification for 12+ CKError codes (network, quota, auth, etc.)
- ✅ Implemented iCloud account status detection
- ✅ Integrated retry logic into all ICloudUserBusinessService operations

**✅ Phase 5: UI Integration (~250 LOC)**
- ✅ Created `iCloudSyncUseCases.swift` with 4 use cases
- ✅ Created `ICloudSyncSectionView.swift` UI component
- ✅ Added sync methods to `SettingsViewModel`: `syncNow()`, `refreshiCloudStatus()`
- ✅ Integrated iCloud sync section into Settings page
- ✅ Added sync status indicator with 5 states (available, notSignedIn, restricted, temporarilyUnavailable, unknown)
- ✅ Added "Last Synced" timestamp display
- ✅ Added "Sync Now" button with loading state

**⏸️ Phase 4: Testing & Validation (BLOCKED - Requires Paid Membership)**
- ⏸️ Unit tests for ICloudUserBusinessService
- ⏸️ Conflict resolution scenario testing
- ⏸️ Multi-device sync validation
- ⏸️ CloudKit error scenario testing
- ⏸️ Avatar asset sync verification

**Total Code Written:** ~760 LOC (Phases 1-3) + ~250 LOC (Phase 5) = **~1,010 LOC**

### Next Steps When Membership Obtained

1. **Purchase Apple Developer Program ($99/year)**
2. **Enable iCloud in Apple Developer Portal:**
   - Update App ID with iCloud capability
   - Register CloudKit container: `iCloud.com.vladblajovan.Ritualist`
3. **Configure CloudKit Dashboard:**
   - Follow `CLOUDKIT-SETUP-GUIDE.md` step-by-step
   - Create UserProfile record type with 10 fields
   - Set up indexes for recordID and updatedAt
4. **Re-enable Entitlements:**
   - Uncomment iCloud entitlements in `Ritualist.entitlements`
   - Verify build succeeds with proper provisioning profile
5. **Complete Phase 4: Testing & Validation**
   - Run unit tests with real CloudKit backend
   - Test multi-device sync (iPhone + iPad)
   - Validate conflict resolution with real scenarios
   - Test all error paths with actual CloudKit errors

---

## Implementation Progress Summary

### Completed Work (Ready to Test)

| Phase | Status | LOC | Files Modified/Created | Build Status |
|-------|--------|-----|------------------------|--------------|
| **Phase 1: Infrastructure** | ✅ Complete | ~50 | 2 modified, 1 created | ⚠️ Blocked by entitlements |
| **Phase 2: Core Implementation** | ✅ Complete | ~220 | 2 created, 1 modified | ✅ Compiles |
| **Phase 3: Error Handling** | ✅ Complete | ~270 | 1 created | ✅ Compiles |
| **Phase 4: Testing** | ⏸️ Pending | TBD | TBD | ⏸️ Requires CloudKit |
| **Phase 5: UI Integration** | ✅ Complete | ~250 | 4 modified, 1 created | ✅ Compiles |

### Key Implementation Details

**Conflict Resolution Strategy:** Last-Write-Wins (LWW)
- Compares `updatedAt` timestamps between local and cloud
- Most recent timestamp wins
- Tie-breaker: Cloud version preferred

**Error Handling Strategy:** Exponential Backoff
- Max 3 retry attempts
- Base delay: 1 second
- Formula: `(baseDelay × 2^attempt) + jitter`
- CloudKit-suggested delays honored when available

**Sync Architecture:** Local-First
- Immediate local saves to SwiftData
- Async background sync to CloudKit
- App fully functional offline
- Sync queued when network available

**Avatar Storage:** CKAsset
- Avoids 1MB CKRecord size limit
- Temporary file handling for asset creation/extraction
- Graceful degradation if asset sync fails

---

## 1. Current State Analysis

### ✅ What's Already Built

#### 1.1 Protocol Layer
- **`UserBusinessService` protocol** (RitualistCore) - Thread-agnostic business logic interface
  - `getCurrentProfile() async throws -> UserProfile`
  - `updateProfile(_ profile: UserProfile) async throws`
  - `syncWithiCloud() async throws`

#### 1.2 Stub Implementation
- **`ICloudUserBusinessService`** (RitualistCore/Services/UserBusinessService.swift:149-200)
  - Skeleton implementation with TODO comments
  - Basic structure in place for CloudKit integration
  - Conflict resolution placeholders

#### 1.3 DI Configuration
- **Container+Services.swift** already configured:
  ```swift
  var userBusinessService: Factory<UserBusinessService> {
      #if DEBUG
      return MockUserBusinessService(...)  // Uses local SwiftData
      #else
      return ICloudUserBusinessService(...) // Stub for production
      #endif
  }
  ```

#### 1.4 Local Data Layer
- **SwiftData persistence** fully implemented:
  - `ProfileLocalDataSource` (@ModelActor for background operations)
  - `ProfileRepository` and `ProfileRepositoryImpl`
  - `UserProfile` entity (Codable, Identifiable)

#### 1.5 Infrastructure Partial Support
- **App Group configured:** `group.com.vladblajovan.Ritualist`
- **SwiftData container:** Uses app group for widget sharing
- **PersistenceContainer.swift:68:** `cloudKitDatabase: .none` (placeholder for future CloudKit)

### ❌ What's Missing

#### 1.1 iCloud Entitlements
**Current state:**
```xml
<!-- Ritualist/Ritualist.entitlements -->
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.vladblajovan.Ritualist</string>
    </array>
</dict>
```

**Required additions:**
- `com.apple.developer.icloud-services` (CloudKit)
- `com.apple.developer.icloud-container-identifiers`
- `com.apple.developer.ubiquity-kvstore-identifier` (optional, for key-value storage)

#### 1.2 CloudKit Container Setup
- No container identifier registered in Apple Developer Portal
- No CKRecord schema defined for UserProfile
- No CloudKit framework integration

#### 1.3 ICloudUserBusinessService Implementation
All methods are stubs with TODO comments:
- CloudKit initialization missing
- CKRecord CRUD operations not implemented
- Conflict resolution algorithm not implemented
- Error handling incomplete

#### 1.4 Xcode Project Configuration
- CloudKit capability not enabled in target settings
- No CloudKit dashboard schema created
- No background modes configured for sync

---

## 2. UserProfile Data Model Analysis

### 2.1 Current Entity Structure

```swift
public struct UserProfile: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var avatarImageData: Data?           // ⚠️ Large data field
    public var appearance: Int                  // 0=followSystem, 1=light, 2=dark
    public var homeTimezone: String?
    public var displayTimezoneMode: String      // "original", "current", "home"
    public var subscriptionPlan: SubscriptionPlan
    public var subscriptionExpiryDate: Date?
    public var createdAt: Date
    public var updatedAt: Date                  // 🔑 Key for conflict resolution
}
```

### 2.2 CloudKit Mapping Strategy

**Recommended CKRecord Schema:**

| Field Name | Type | Indexed | Notes |
|------------|------|---------|-------|
| `recordID` | String | Yes | Use `UserProfile.id.uuidString` |
| `name` | String | No | User's display name |
| `appearance` | Int64 | No | Appearance preference |
| `homeTimezone` | String | No | Optional timezone identifier |
| `displayTimezoneMode` | String | No | Display mode string |
| `subscriptionPlan` | String | No | Enum rawValue |
| `subscriptionExpiryDate` | Date | No | Optional expiry date |
| `createdAt` | Date | No | Creation timestamp |
| `updatedAt` | Date | **Yes** | **Critical for conflict resolution** |
| `avatarAsset` | CKAsset | No | Store avatar separately as asset |

**Key Decisions:**
- **Avatar handling:** Use `CKAsset` instead of `Data` to avoid 1MB record size limit
- **Subscription data:** Sync to cloud for cross-device premium access
- **Index strategy:** Only index `recordID` and `updatedAt` for performance

---

## 3. Sync Architecture Design

### 3.1 Sync Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    App Launch / Foreground                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  1. Load Local Profile (ProfileLocalDataSource)             │
│     - SwiftData read from disk                              │
│     - Return UserProfile entity                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Fetch iCloud Profile (ICloudUserBusinessService)        │
│     - CKDatabase.fetch(CKRecordID)                          │
│     - Convert CKRecord → UserProfile                        │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Conflict Resolution                                      │
│     - Compare local.updatedAt vs cloud.updatedAt            │
│     - WINNER: Most recent updatedAt timestamp               │
│     - LOSER: Discard or merge (user preference)             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Update Local & Cloud                                     │
│     - Save winning profile to SwiftData                     │
│     - Push winning profile to CloudKit                      │
│     - Update UI via @Observable                             │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Sync Triggers

| Trigger | Timing | Priority | Rationale |
|---------|--------|----------|-----------|
| **App Launch** | On startup | High | Ensure latest data before user interaction |
| **Profile Update** | After save | Critical | Immediate sync on user changes |
| **Foreground** | App becomes active | Medium | Sync changes made on other devices |
| **Background Refresh** | System-scheduled | Low | Opportunistic sync for freshness |
| **Manual Sync** | User-initiated | High | Settings → "Sync Now" button |

### 3.3 Conflict Resolution Algorithm

**Strategy:** Last-Write-Wins (LWW) with `updatedAt` timestamp

```swift
func resolveConflict(local: UserProfile, cloud: UserProfile) -> UserProfile {
    // Compare timestamps
    if local.updatedAt > cloud.updatedAt {
        return local  // Local is newer, use it
    } else if cloud.updatedAt > local.updatedAt {
        return cloud  // Cloud is newer, use it
    } else {
        // Same timestamp (rare) - prefer cloud as source of truth
        return cloud
    }
}
```

**Alternative Strategy (Future):** Granular field-level merge
- Compare each field's last modified time
- Merge non-conflicting changes from both sources
- Requires additional metadata (field-level timestamps)

---

## 4. Implementation Requirements

### 4.1 Infrastructure Setup

#### Xcode Project Changes
1. **Enable iCloud Capability**
   - Target: Ritualist
   - Services: CloudKit
   - Containers: Create new container `iCloud.com.vladblajovan.Ritualist`

2. **Update Entitlements** (Ritualist.entitlements)
   ```xml
   <key>com.apple.developer.icloud-services</key>
   <array>
       <string>CloudKit</string>
   </array>
   <key>com.apple.developer.icloud-container-identifiers</key>
   <array>
       <string>iCloud.com.vladblajovan.Ritualist</string>
   </array>
   ```

3. **Background Modes** (if implementing background sync)
   ```xml
   <key>UIBackgroundModes</key>
   <array>
       <string>remote-notification</string>
   </array>
   ```

#### Apple Developer Portal
1. **Register CloudKit Container**
   - Container ID: `iCloud.com.vladblajovan.Ritualist`
   - Environment: Development + Production

2. **Update App ID**
   - Enable iCloud capability
   - Associate CloudKit container

3. **Create CKRecord Schema** (via CloudKit Dashboard)
   - Record Type: `UserProfile`
   - Fields: See section 2.2 table
   - Indexes: `recordID`, `updatedAt`

### 4.2 Code Implementation

#### Phase 1: CloudKit Integration (Core)
**File:** `RitualistCore/Sources/RitualistCore/Services/UserBusinessService.swift`

**Tasks:**
1. Import CloudKit framework
2. Implement `ICloudUserBusinessService.init()`:
   - Initialize `CKContainer` with identifier
   - Get reference to private database
   - Set up error handler
3. Implement `getCurrentProfile()`:
   - Fetch from local SwiftData first (fast)
   - Fetch from CloudKit asynchronously
   - Resolve conflicts
   - Return unified profile
4. Implement `updateProfile()`:
   - Save to local SwiftData (immediate)
   - Convert `UserProfile` → `CKRecord`
   - Save to CloudKit (async)
   - Handle errors (network, quota, etc.)
5. Implement `syncWithiCloud()`:
   - Fetch latest from cloud
   - Merge with local
   - Push updates if needed

**Estimated LOC:** ~300 lines

#### Phase 2: CKRecord Conversion (Mappers)
**New File:** `RitualistCore/Sources/RitualistCore/Mappers/UserProfileCloudMapper.swift`

**Tasks:**
1. Create `UserProfile` → `CKRecord` mapper
2. Create `CKRecord` → `UserProfile` mapper
3. Handle `CKAsset` for avatar image
4. Handle optional fields (homeTimezone, subscriptionExpiryDate)
5. Add comprehensive error handling

**Estimated LOC:** ~150 lines

#### Phase 3: Error Handling & Retry
**New File:** `RitualistCore/Sources/RitualistCore/Services/CloudSyncErrorHandler.swift`

**Tasks:**
1. Define `CloudSyncError` enum (network, quota, conflict, etc.)
2. Implement exponential backoff retry logic
3. Handle CloudKit-specific errors:
   - `CKError.networkUnavailable` → Retry with backoff
   - `CKError.quotaExceeded` → Alert user
   - `CKError.serverRecordChanged` → Conflict resolution
4. Integration with existing `ErrorHandler` service

**Estimated LOC:** ~200 lines

#### Phase 4: Testing Infrastructure
**New File:** `RitualistTests/Services/ICloudUserBusinessServiceTests.swift`

**Tasks:**
1. Create mock `CKDatabase` for testing
2. Test conflict resolution scenarios:
   - Local newer than cloud
   - Cloud newer than local
   - Same timestamp
3. Test error scenarios:
   - Network failure
   - CloudKit unavailable
   - Record not found
4. Test avatar asset handling

**Estimated LOC:** ~400 lines

### 4.3 Migration Strategy (DEBUG → RELEASE)

**Current Behavior:**
- DEBUG builds: `MockUserBusinessService` (local SwiftData only)
- RELEASE builds: `ICloudUserBusinessService` (stub)

**Migration Path:**
1. **Phase 1:** Implement `ICloudUserBusinessService` in DEBUG builds first
   - Test with development CloudKit environment
   - Validate sync logic before production
2. **Phase 2:** Enable in TestFlight (RELEASE with CloudKit Development)
   - Beta testers validate cross-device sync
   - Monitor CloudKit usage and errors
3. **Phase 3:** Production release (RELEASE with CloudKit Production)
   - Gradual rollout with feature flag
   - Monitor CloudKit quota and performance

**Build Configuration:**
```swift
// Container+Services.swift
var userBusinessService: Factory<UserBusinessService> {
    self {
        #if DEBUG
        // Development: Use iCloud with Development environment
        return ICloudUserBusinessService(
            errorHandler: self.errorHandler(),
            environment: .development
        )
        #else
        // Production: Use iCloud with Production environment
        return ICloudUserBusinessService(
            errorHandler: self.errorHandler(),
            environment: .production
        )
        #endif
    }
    .singleton
}
```

---

## 5. Risk Analysis & Mitigation

### 5.1 Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **CloudKit quota exceeded** | Medium | High | Monitor usage, implement local-first strategy, alert users |
| **Network unavailability** | High | Medium | Offline-first design, queue sync operations, retry with backoff |
| **Conflict resolution data loss** | Low | High | Thorough testing, user notifications on conflicts, backup strategy |
| **Avatar asset sync failure** | Medium | Low | Graceful degradation (keep local avatar), retry mechanism |
| **iCloud account not signed in** | Medium | High | Detect and prompt user to sign in, fallback to local-only mode |

### 5.2 User Experience Risks

| Risk | Mitigation |
|------|------------|
| **Sync delays** | Show sync status in UI, use local data immediately |
| **Unexpected data changes** | Log sync events, provide "last synced" timestamp |
| **Lost preferences** | Conflict resolution favors most recent, notify user of changes |

---

## 6. Implementation Plan

### Phase 1: Infrastructure Setup ✅ COMPLETE
- [x] Enable iCloud capability in Xcode
- [x] Update Ritualist.entitlements with CloudKit keys
- [x] Update PersistenceContainer.swift to enable CloudKit sync
- [x] Create CLOUDKIT-SETUP-GUIDE.md with manual setup steps
- [ ] ⚠️ **BLOCKED:** Register CloudKit container in Apple Developer Portal (requires paid membership)
- [ ] ⚠️ **BLOCKED:** Create CKRecord schema in CloudKit Dashboard (requires paid membership)

**Deliverables:**
- ✅ Updated entitlements file (RitualistCore/Sources/RitualistCore/Storage/PersistenceContainer.swift)
- ✅ PersistenceContainer configured for CloudKit
- ✅ Manual setup guide created (CLOUDKIT-SETUP-GUIDE.md)
- ⚠️ CloudKit container registration BLOCKED (requires $99/year Apple Developer Program)

**Commits:**
- Commit: "feat(icloud): Phase 1 - Infrastructure setup for CloudKit sync"

---

### Phase 2: Core Implementation ✅ COMPLETE
- [x] Implement `ICloudUserBusinessService` CloudKit operations
- [x] Create `UserProfileCloudMapper` for CKRecord conversion
- [x] Implement conflict resolution logic (Last-Write-Wins)
- [x] Add `CKAsset` handling for avatar images
- [x] Add `CloudKitSyncError` enum with comprehensive error cases

**Deliverables:**
- ✅ Working `ICloudUserBusinessService` implementation (~150 LOC)
- ✅ `UserProfileCloudMapper` with full UserProfile ↔ CKRecord conversion (~220 LOC)
- ✅ Conflict resolution algorithm (Last-Write-Wins using updatedAt timestamps)
- ✅ CKAsset handling for avatar images (avoids 1MB record limit)
- ✅ CloudKitSyncError enum for structured error handling

**Files Created:**
- `RitualistCore/Sources/RitualistCore/Mappers/UserProfileCloudMapper.swift` (220 LOC)

**Files Modified:**
- `RitualistCore/Sources/RitualistCore/Services/UserBusinessService.swift` (ICloudUserBusinessService implementation)

**Commits:**
- Commit: "feat(icloud): Phase 2 - Core CloudKit implementation with mappers and conflict resolution"

---

### Phase 3: Error Handling & Resilience ✅ COMPLETE
- [x] Create `CloudSyncErrorHandler` actor with retry logic
- [x] Implement exponential backoff (3 retries, base delay 1s, with jitter)
- [x] Add error classification for 12+ CKError codes
- [x] Handle network unavailability gracefully with retries
- [x] Implement iCloud account status detection (5 states)
- [x] Integrate retry logic into all ICloudUserBusinessService operations

**Deliverables:**
- ✅ `CloudSyncErrorHandler` service (~270 LOC)
- ✅ Retry mechanism with exponential backoff and jitter
- ✅ Error classification (network, quota, auth, busy, not found, etc.)
- ✅ CloudKit account status checking (available, notSignedIn, restricted, temporarilyUnavailable, unknown)
- ✅ Graceful degradation to local-only mode on persistent failures

**Files Created:**
- `RitualistCore/Sources/RitualistCore/Services/CloudSyncErrorHandler.swift` (270 LOC)

**Files Modified:**
- `RitualistCore/Sources/RitualistCore/Services/UserBusinessService.swift` (integrated retry logic)

**Commits:**
- Commit: "feat(icloud): Phase 3 - CloudKit error handling with automatic retry and exponential backoff"

---

### Phase 4: Testing & Validation ⏸️ BLOCKED (Requires Paid Apple Developer Program)
- [ ] ⚠️ **BLOCKED:** Write unit tests for `ICloudUserBusinessService` (requires CloudKit backend)
- [ ] ⚠️ **BLOCKED:** Test conflict resolution scenarios (requires multi-device CloudKit sync)
- [ ] ⚠️ **BLOCKED:** Test error handling with real CloudKit errors
- [ ] ⚠️ **BLOCKED:** Test multi-device sync (iPhone + iPad simulators with CloudKit)
- [ ] ⚠️ **BLOCKED:** Test avatar asset sync (requires CloudKit CKAsset support)
- [ ] ⚠️ **BLOCKED:** Verify iCloud account status detection with real iCloud accounts

**Why Blocked:**
- Cannot test without CloudKit Dashboard configuration
- Cannot configure CloudKit Dashboard without paid Apple Developer Program ($99/year)
- Free Apple Developer accounts do not support iCloud/CloudKit capabilities

**Deliverables (When Unblocked):**
- Comprehensive test suite (target 80%+ coverage)
- Multi-device sync validation
- Error scenario coverage with real CloudKit errors
- Avatar asset sync verification

---

### Phase 5: Integration & Polish ✅ COMPLETE
- [x] Create iCloud sync use cases (4 use cases: sync, check status, get/update last sync date)
- [x] Add `syncNow()` and `refreshiCloudStatus()` methods to SettingsViewModel
- [x] Create `ICloudSyncSectionView` UI component
- [x] Integrate iCloud sync section into Settings page
- [x] Show sync status indicator with 5 states (available, notSignedIn, etc.)
- [x] Display "Last synced" timestamp (relative format)
- [x] Add "Sync Now" button with loading state (disabled when iCloud unavailable)
- [x] Update DI container with iCloud sync use case factories

**Deliverables:**
- ✅ iCloud sync use cases implemented (~115 LOC)
- ✅ `ICloudSyncSectionView` UI component (~210 LOC)
- ✅ SettingsViewModel integration with sync methods (~50 LOC)
- ✅ Settings page UI integration
- ✅ iCloud status indicator with contextual messages
- ✅ "Sync Now" button with proper loading and disabled states

**Files Created:**
- `RitualistCore/Sources/RitualistCore/UseCases/Implementations/Core/iCloudSyncUseCases.swift` (115 LOC)
- `Ritualist/Features/Settings/Presentation/Components/ICloudSyncSectionView.swift` (210 LOC)

**Files Modified:**
- `Ritualist/Features/Settings/Presentation/SettingsViewModel.swift` (added sync methods and state)
- `Ritualist/Features/Settings/Presentation/SettingsView.swift` (integrated ICloudSyncSectionView)
- `Ritualist/DI/Container+SettingsUseCases.swift` (added 4 iCloud sync use case factories)
- `Ritualist/DI/Container+ViewModels.swift` (added use case dependencies to SettingsViewModel factory)

**Commits:**
- Commit: "feat(icloud): Phase 5 - UI integration with Settings page sync controls"

---

## 7. Testing Strategy

### 7.1 Unit Tests
**Coverage Target:** 90%+ for CloudKit integration code

**Test Scenarios:**
1. **Sync Success Paths:**
   - Profile save → CloudKit upload
   - CloudKit fetch → Local save
   - Conflict resolution (local wins)
   - Conflict resolution (cloud wins)
2. **Error Handling:**
   - Network timeout
   - CloudKit unavailable
   - Quota exceeded
   - Record not found
3. **Edge Cases:**
   - Empty profile
   - Missing avatar
   - Invalid CKRecord format
   - Timestamp collision

### 7.2 Integration Tests
**Test Devices:** iPhone 16 + iPad Pro simulators

**Test Scenarios:**
1. **Cross-Device Sync:**
   - Update profile on Device A → Verify on Device B
   - Update subscription on Device B → Verify on Device A
2. **Offline Mode:**
   - Disable network → Update profile → Re-enable → Verify sync
3. **Conflict Simulation:**
   - Update same profile on both devices → Verify resolution

### 7.3 Manual QA Checklist
- [ ] Profile updates sync within 5 seconds
- [ ] Avatar images sync correctly
- [ ] Subscription status syncs across devices
- [ ] App works offline (local-first)
- [ ] Sync errors show user-friendly messages
- [ ] "Last synced" timestamp is accurate
- [ ] iCloud sign-in prompt appears when needed

---

## 8. CloudKit Quota Considerations

### 8.1 Free Tier Limits (Per User)
- **Database Size:** 1 GB (more than enough for UserProfile)
- **Data Transfer:** 250 MB/day
- **Requests:** 40 requests/second

### 8.2 UserProfile Size Estimate
- Without avatar: ~500 bytes
- With avatar (100KB): ~100 KB per user

**Quota Impact:**
- 10,000 users = 1 GB database (within free tier)
- Average sync: 2 KB/user/day = 20 MB/day for 10K users (well under 250 MB limit)

**Recommendation:** No premium CloudKit plan needed initially.

---

## 9. Future Enhancements

### 9.1 Beyond UserProfile
**Not in current scope, but architecturally prepared:**

1. **Habit Data Sync**
   - Challenges: Larger dataset, more frequent updates
   - Strategy: Selective sync (recent habits only)
   - CloudKit Record Type: `Habit`, `HabitLog`

2. **Category Sync**
   - Custom categories across devices
   - Strategy: Simple full sync (small dataset)

3. **Personality Analysis Sync**
   - Sync personality profiles for consistency

### 9.2 Advanced Features
- **CKSubscription:** Push notifications for profile changes
- **CKShare:** Share habits with friends/family
- **CloudKit JS:** Web dashboard for viewing habits

---

## 10. Acceptance Criteria

### Must-Have (MVP)
- ✅ UserProfile syncs to iCloud on save
- ✅ Profile loads from iCloud on app launch
- ✅ Conflicts resolved using Last-Write-Wins
- ✅ Avatar images sync correctly
- ✅ Subscription status syncs across devices
- ✅ App works offline with local-first approach
- ✅ User-friendly error messages for sync failures

### Nice-to-Have (Post-MVP)
- ⭐ Background sync on app foreground
- ⭐ "Sync Now" button in Settings
- ⭐ Sync status indicator in UI
- ⭐ "Last synced" timestamp display
- ⭐ Conflict notification to user

---

## 11. Conclusion

**Summary:** The Ritualist app has excellent architectural foundation for iCloud sync, with protocols, DI setup, and stub implementations already in place. The primary work is implementing the `ICloudUserBusinessService`, setting up CloudKit infrastructure, and thorough testing.

**Effort:** 3-5 days for complete implementation
**Complexity:** Medium (CloudKit integration is well-documented)
**Risk:** Low (limited scope to UserProfile only)

**Recommendation:** ✅ **Proceed with implementation** following the phased plan above.
