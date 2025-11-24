# CloudKit Setup Guide

This guide covers the manual steps required to complete iCloud/CloudKit infrastructure setup for the Ritualist app.

## Prerequisites

- ✅ Entitlements updated (`Ritualist.entitlements` - automated)
- ⚠️ Apple Developer Account with appropriate permissions
- ⚠️ Access to Apple Developer Portal
- ⚠️ Xcode 15+ installed

---

## Step 1: Enable iCloud Capability in Xcode

### 1.1 Open Project Settings
1. Open `Ritualist.xcodeproj` in Xcode
2. Select the **Ritualist** target in the project navigator
3. Go to the **Signing & Capabilities** tab

### 1.2 Add iCloud Capability
1. Click **+ Capability** button
2. Search for and select **iCloud**
3. In the iCloud section, check:
   - ☑️ **CloudKit**
4. Xcode will automatically:
   - Create `iCloud.com.vladblajovan.Ritualist` container
   - Update provisioning profile
   - Sync with Apple Developer Portal

**Expected Result:**
```
✅ iCloud capability added
✅ CloudKit service enabled
✅ Container: iCloud.com.vladblajovan.Ritualist
```

---

## Step 2: Verify Apple Developer Portal Configuration

### 2.1 Access Certificates, Identifiers & Profiles
1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → Find your App ID (`com.vladblajovan.Ritualist`)

### 2.2 Verify App ID Capabilities
Ensure the following capabilities are enabled:

| Capability | Status | Notes |
|------------|--------|-------|
| **App Groups** | ✅ Enabled | `group.com.vladblajovan.Ritualist` |
| **iCloud** | ⚠️ **Must Enable** | CloudKit, including CloudKit support |

**To enable iCloud:**
1. Click on your App ID
2. Click **Edit** or **Configure**
3. Enable **iCloud** checkbox
4. Select **Include CloudKit support (requires Xcode 5)**
5. Click **Continue** → **Save**

### 2.3 Verify CloudKit Container
1. In Developer Portal, go to **iCloud Containers**
2. Verify `iCloud.com.vladblajovan.Ritualist` exists
3. If not, click **+** to create:
   - **Identifier:** `iCloud.com.vladblajovan.Ritualist`
   - **Description:** Ritualist App CloudKit Container

---

## Step 3: Configure CloudKit Schema

### 3.1 Access CloudKit Dashboard
1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. Sign in with Apple Developer Account
3. Select **iCloud.com.vladblajovan.Ritualist** container
4. Choose **Development** environment (for testing)

### 3.2 Create UserProfile Record Type

#### Record Type Setup
1. Click **Schema** in left sidebar
2. Click **Record Types** → **+ (Add Record Type)**
3. Enter Name: `UserProfile`
4. Click **Create**

#### Add Fields to UserProfile

Click **Add Field** for each field below:

| Field Name | Type | Options | Notes |
|------------|------|---------|-------|
| `recordID` | String | Index | Primary identifier (UUID string) |
| `name` | String | - | User's display name |
| `appearance` | Int(64) | - | 0=followSystem, 1=light, 2=dark |
| `homeTimezone` | String | - | IANA timezone identifier |
| `displayTimezoneMode` | String | - | "original", "current", "home" |
| `subscriptionPlan` | String | - | "free", "monthly", "annual" |
| `subscriptionExpiryDate` | Date/Time | - | Subscription expiration |
| `createdAt` | Date/Time | - | Record creation timestamp |
| `updatedAt` | Date/Time | **Index** | **Last update timestamp (for conflict resolution)** |
| `avatarAsset` | Asset | - | User avatar image (optional) |

**Important:**
- ✅ Index `recordID` for fast lookups
- ✅ Index `updatedAt` for conflict resolution queries
- ⚠️ Do NOT index other fields (unnecessary performance overhead)

#### Configure Indexes
1. Click **Indexes** tab in Record Type editor
2. Verify indexes exist:
   - `recordID` (QUERYABLE)
   - `updatedAt` (SORTABLE + QUERYABLE)

### 3.3 Save Schema
1. Click **Save Changes** in CloudKit Dashboard
2. Schema is now saved in **Development** environment

---

## Step 4: Deploy Schema to Production (When Ready)

⚠️ **DO NOT do this until app is tested and ready for App Store release**

### 4.1 Test in Development First
1. Complete all testing using **Development** environment
2. Verify sync works across multiple devices
3. Test conflict resolution scenarios

### 4.2 Deploy to Production
1. In CloudKit Dashboard, switch to **Development** environment
2. Click **Deploy to Production** button
3. Review schema changes
4. Confirm deployment
5. Production schema is now live

**Warning:** Production schema changes are **permanent** and cannot be reversed. Always test thoroughly in Development first.

---

## Step 5: Update Xcode Build Configurations

### 5.1 Development vs Production Environments

The code already handles environment selection via build configuration:

```swift
// Container+Services.swift
var userBusinessService: Factory<UserBusinessService> {
    #if DEBUG
    // Development: Use CloudKit Development environment
    return ICloudUserBusinessService(
        errorHandler: self.errorHandler(),
        environment: .development  // Will be implemented
    )
    #else
    // Production: Use CloudKit Production environment
    return ICloudUserBusinessService(
        errorHandler: self.errorHandler(),
        environment: .production  // Will be implemented
    )
    #endif
}
```

No manual configuration needed - environment is automatically selected based on build configuration.

---

## Step 6: Testing CloudKit Connection

### 6.1 Run App in Simulator
1. Build and run app in iPhone simulator
2. Ensure you're signed into iCloud in simulator:
   - Settings → Sign in to your iPhone → Use Apple ID
3. Check Xcode console for CloudKit logs

### 6.2 Expected Console Output
```
✅ CloudKit container initialized: iCloud.com.vladblajovan.Ritualist
✅ Connected to CloudKit Development environment
✅ UserProfile schema available
```

### 6.3 Test on Physical Device
1. Connect iPhone with Apple ID signed in
2. Build and run on device
3. Verify CloudKit sync in Settings → Apple ID → iCloud
4. Enable **iCloud Drive** if prompted

---

## Step 7: Troubleshooting

### Common Issues

#### Issue: "CloudKit container not found"
**Solution:**
- Verify container exists in Apple Developer Portal
- Check entitlements match container identifier exactly
- Clean build folder (Cmd+Shift+K) and rebuild

#### Issue: "User not logged into iCloud"
**Solution:**
- Sign into iCloud on device/simulator: Settings → Sign in
- Grant iCloud permission when app requests it

#### Issue: "Schema not found" errors
**Solution:**
- Deploy schema in CloudKit Dashboard (Development environment)
- Wait 1-2 minutes for propagation
- Restart app

#### Issue: "Insufficient CloudKit quota"
**Solution:**
- Check CloudKit Dashboard → Usage
- Free tier: 1 GB database, 250 MB/day transfer
- UserProfile is tiny (~1 KB per user) - should not hit limits in development

---

## Step 8: Verification Checklist

Before proceeding to Phase 2 (implementation), verify:

- [ ] **Xcode:** iCloud capability added to Ritualist target
- [ ] **Entitlements:** CloudKit keys present in Ritualist.entitlements
- [ ] **Developer Portal:** App ID has iCloud enabled
- [ ] **Developer Portal:** CloudKit container `iCloud.com.vladblajovan.Ritualist` exists
- [ ] **CloudKit Dashboard:** UserProfile record type created with all fields
- [ ] **CloudKit Dashboard:** Indexes on `recordID` and `updatedAt`
- [ ] **CloudKit Dashboard:** Schema saved in Development environment
- [ ] **Testing:** App builds successfully with new entitlements
- [ ] **Testing:** No entitlement errors in Xcode console
- [ ] **iCloud:** Signed into iCloud on test device/simulator

---

## Next Steps

Once all checklist items are complete:

1. ✅ **Phase 1 Complete** - Infrastructure ready
2. ➡️ **Phase 2** - Implement `ICloudUserBusinessService`
3. ➡️ **Phase 3** - Error handling & resilience
4. ➡️ **Phase 4** - Testing & validation
5. ➡️ **Phase 5** - UI integration

See `ICLOUD-STORAGE-ANALYSIS.md` for full implementation plan.

---

## Reference Links

- [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
- [Apple Developer Portal](https://developer.apple.com/account/)
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [CloudKit Quick Start](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitQuickStart/Introduction/Introduction.html)

---

## Sync Behavior

### Automatic Sync

The app implements **automatic iCloud sync** that matches industry standards and user expectations:

#### When Automatic Sync Happens:
1. **App Launch** - Syncs profile when app starts
2. **App Becomes Active** - Syncs when returning from background
3. **After Profile Changes** - Syncs immediately after:
   - Name updates
   - Theme/appearance changes
   - Timezone settings changes
   - Avatar updates

#### Silent Operation:
- Auto-sync runs in the background without blocking the UI
- Sync failures are logged but don't interrupt the user experience
- Users can always manually sync from Settings if auto-sync fails

### Manual Sync

The Settings screen provides a **"Sync Now" button** for:
- Forcing an immediate sync when needed
- Verifying that sync is working
- Syncing after being offline for extended periods

**UI Elements:**
- Sync status indicator (with color-coded icons)
- Last sync timestamp
- Manual "Sync Now" button

### Conflict Resolution

The app uses **Last-Write-Wins (LWW)** conflict resolution:

#### How It Works:
1. When syncing, both local and cloud profiles are fetched
2. **CloudKit server timestamps** are compared (more reliable than device clocks)
3. The profile with the most recent timestamp wins
4. If timestamps are identical, cloud version is preferred

#### Reliability Features:
- Uses CloudKit's `modificationDate` instead of client-provided timestamps
- Eliminates clock skew issues across devices
- Analytics tracking for conflict monitoring in production

#### What Gets Synced:
- User name
- Theme/appearance preference
- Timezone settings (current, home, display mode)
- Timezone change history
- Avatar image
- Profile metadata (created/updated dates)

### Multi-Device Experience

**New Device Setup:**
1. User installs app on new device
2. Signs into iCloud
3. Launches app
4. Profile is automatically restored from CloudKit

**Data Safety:**
- Local changes are never overwritten on first sync
- If no cloud profile exists, local profile is uploaded
- No data loss during initial sync

**Cross-Device Updates:**
- Changes on Device A appear on Device B within seconds
- Auto-sync ensures changes propagate automatically
- Manual sync can force immediate synchronization

---

## Notes

- **Development vs Production:** Always test in Development environment first
- **Schema Changes:** Production schema is immutable - plan carefully
- **Quota Limits:** Free tier is sufficient for initial launch (10K+ users)
- **Privacy:** CloudKit uses user's iCloud account - no custom auth needed
- **Sync:** Automatic background sync at app launch, app active, and after profile changes
- **Conflict Resolution:** Last-Write-Wins using CloudKit server timestamps
