# StoreKit2 + iCloud Sync Integration Issues

## Analysis Date: 2025-12-05
## Updated: 2025-12-16 (Free iCloud Sync Migration)

This document outlines critical issues, edge cases, and recommended fixes for the StoreKit2 integration in Ritualist.

> **IMPORTANT UPDATE (2025-12-16):** iCloud sync is now **free for all users**. Premium subscription is only required for feature gating (habit limits, advanced analytics). This significantly simplifies the architecture and eliminates most sync-related timing issues.

---

## Architecture Change: Free iCloud Sync

### Previous Architecture (Premium-Gated Sync)
- `PersistenceContainer` checked premium status at init to determine sync mode
- Required blocking StoreKit check or Keychain cache read at startup
- "Restart app to enable sync" was needed after purchase
- Complex timing issues between StoreKit init and ModelContainer creation

### Current Architecture (Free Sync)
- iCloud sync is **always enabled** for all users
- No premium check needed for `PersistenceContainer` init
- Premium status only affects feature gating (habit limits, analytics)
- Simpler startup flow, no blocking checks

### Benefits
- ~2.5s faster worst-case startup time
- No "restart required" after purchase
- Returning users always get their data synced
- ~300+ lines of code removed

---

## ✅ RESOLVED: Premium Status Timing Issues

### Previous Problem:
- `PersistenceContainer` needed premium status before StoreKit loaded
- Required complex two-phase startup with Keychain cache

### Resolution (2025-12-16):
- **Sync no longer requires premium** - this entire class of issues is eliminated
- Premium check is now only for feature gating (non-blocking, can be async)
- `SecurePremiumCache` retained for feature gating caching only

---

## ✅ RESOLVED: Restart Required for Sync

### Previous Problem:
- `ModelContainer` configuration is immutable (cloudKitDatabase set once at init)
- Purchasing subscription mid-session required app restart

### Resolution (2025-12-16):
- **Sync is always enabled** - no configuration change needed
- Premium purchase immediately unlocks features without restart

---

## Remaining StoreKit2 Issues

### 1. Premium Feature Gating

Premium subscription still gates these features:
- Unlimited habits (free: 5 habit limit)
- Advanced analytics
- Future premium features

**Current Implementation:**
- `SecurePremiumCache` (Keychain) for startup caching
- Async verification via `StoreKitSubscriptionService.verifyPremiumAsync()`
- Feature gating is non-blocking (features lock/unlock without restart)

### 2. Subscription Expiry During Session

**Problem:**
- No periodic subscription validation during app session
- Features may remain unlocked after subscription expires

**Recommended Fix:**
- Validate subscription on app foreground
- Lock features immediately when expiry detected
- (Lower priority since sync is now free)

### 3. Cross-Device Subscription Detection

**Problem:**
- Device B may not immediately detect subscription from Device A

**Current Mitigation:**
- Query `Transaction.currentEntitlements` at startup
- Async verification after UI loads

---

## HIGH PRIORITY ISSUES (Remaining)

### StoreKit2

| Issue | Impact | Fix |
|-------|--------|-----|
| ~~No grace period handling~~ | ~~Premature feature lockout~~ | ~~Check `gracePeriodExpiresDate`~~ ✅ FIXED |
| No pending purchase state | Confusing UX for Ask to Buy | Add `.pending` to `PurchaseState` |
| Verification failures silent | Security events undetected | Log and alert on verification failure |
| No retry logic | Users give up on failed purchases | Exponential backoff, max 3 retries |

### iCloud Sync (Lower Priority - Now Free)

| Issue | Impact | Fix |
|-------|--------|-----|
| iCloud disabled mid-session | Data stops syncing | Monitor `CKContainer.accountStatus()` |
| Network loss during sync | Temporary data divergence | SwiftData handles automatically |
| iCloud storage full | Sync fails silently | Detect quota errors, show guidance |

---

## RECOMMENDED IMPLEMENTATION ORDER

### Phase 1: Complete ✅
1. ~~Remove premium gating from iCloud sync~~
2. ~~Query StoreKit for feature gating only (non-blocking)~~
3. ~~Use Keychain cache for startup feature state~~

### Phase 2: Subscription Lifecycle (Remaining)
1. Add subscription expiry validation on foreground
2. Implement grace period detection
3. Add `.pending` purchase state for Ask to Buy
4. Handle refunds/revocations with UI notification

### Phase 3: Error Handling (Remaining)
1. Add purchase retry with exponential backoff
2. Implement network failure classification
3. Fix silent verification failure handling

---

## FILES (Updated for Free Sync)

### Core Files
- `StoreKitSubscriptionService.swift` - Premium verification for features only
- `SecurePremiumCache.swift` - Keychain cache for feature gating
- `PersistenceContainer.swift` - **Simplified: always enables CloudKit**

### Supporting Files
- `RitualistApp.swift` - Async premium verification for features
- `RootTabViewModel.swift` - **Simplified: no premium check for returning users**
- `iCloudSyncSectionView.swift` - **Simplified: status only, no premium toggle**

---

## TESTING REQUIREMENTS

### Premium Feature Tests
- [ ] Purchase completes → premium features unlock immediately (no restart)
- [ ] Cross-device: subscribe on A → features unlock on B at startup
- [ ] Subscription expires → features locked (sync continues)
- [ ] Offline launch → cached feature state works

### Sync Tests (All Users)
- [x] Fresh install → sync enabled automatically
- [x] Reinstall → data syncs from iCloud
- [x] New device → data syncs from iCloud
- [x] Free user → full sync functionality

### Security Tests
- [ ] Modified Keychain → premium features NOT granted
- [ ] No StoreKit receipt → premium features NOT granted
