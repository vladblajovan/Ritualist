# StoreKit2 + iCloud Sync Integration Issues

## Analysis Date: 2025-12-05

This document outlines critical issues, edge cases, and recommended fixes for the StoreKit2 and iCloud sync integration in Ritualist.

---

## ✅ FIXED: Security Vulnerability (Premium Status Storage)

### Previous Problem:
- Premium status was cached in `UserDefaults` via `MockSecureSubscriptionService.isPremiumFromCache()`
- UserDefaults can be easily modified by users (jailbreak, plist editing, device backup manipulation)
- This allowed bypassing payment entirely

### Implemented Fix (2025-12-05, Updated 2025-12-06):
- **Production builds**: `PersistenceContainer.premiumCheckProvider` uses two-phase startup:
  1. **Phase 1 (Sync)**: `SecurePremiumCache.shared.getCachedPremiumStatus()` - instant Keychain read (~5ms)
  2. **Phase 2 (Async)**: `StoreKitSubscriptionService.verifyPremiumAsync()` - verifies and updates cache after UI shows
- **Development builds** (`ALL_FEATURES_ENABLED`): Uses mock service for testing
- StoreKit receipts are cryptographically signed by Apple and cannot be forged
- No main thread blocking (removed 1.5-second semaphore wait)

### Files Changed:
- `Container+DataSources.swift` - Sets up `premiumCheckProvider` to use Keychain cache
- `StoreKitSubscriptionService.swift` - Added `verifyPremiumAsync()` async method, deprecated `isPremiumFromStoreKit()`
- `SecurePremiumCache.swift` - Added `isCacheStale()` method with 7-day staleness threshold
- `PersistenceContainer.swift` - Injectable `premiumCheckProvider` closure
- `RitualistApp.swift` - Added `verifyAndUpdatePremiumStatus()` as first async launch task

---

## ✅ FIXED: Premium Check Before StoreKit Loads

### Previous Problem:
- `PersistenceContainer` checks premium cache at init (app startup)
- `StoreKitPaywallService` is lazy-initialized later via DI
- Result: Premium users may see no sync until app restart

### Implemented Fix (2025-12-05, Updated 2025-12-06):
- **Two-phase startup** eliminates main thread blocking:
  1. **Sync bootstrap**: Uses `SecurePremiumCache` (Keychain) for instant premium check (~5ms)
  2. **Async verification**: `verifyAndUpdatePremiumStatus()` runs after UI shows, corrects cache if needed
- If cache doesn't match StoreKit, user sees toast: "Premium activated! Restart to enable iCloud sync"
- Cache is always updated after async verification, so next launch is correct

---

## ✅ FIXED: Offline Subscription Access

### Previous Problem:
- StoreKit check at startup could timeout when offline
- User would lose premium features despite valid subscription
- No graceful degradation for airplane mode / poor connectivity

### Implemented Fix (2025-12-05):
- **Primary**: StoreKit's `Transaction.currentEntitlements` (works offline with cached data)
- **Fallback**: `SecurePremiumCache` - Keychain-based cache with 3-day grace period
- **Industry Standard**: 3-day offline grace period matches RevenueCat SDK

### How It Works (Two-Phase Startup):
```
App Startup (Sync Bootstrap - ~5ms):
1. Read from SecurePremiumCache (Keychain)
   ├── Cache exists AND < 3 days old → Use cached value
   └── No cache OR > 3 days old → Default to non-premium

After UI Shows (Async Verification):
2. Query StoreKit.currentEntitlements (non-blocking)
   ├── Matches cache → Log success, update cache timestamp
   └── Mismatch → Update cache, show toast if newly premium
       └── "Premium activated! Restart to enable iCloud sync"
```

### Why Keychain (not UserDefaults):
- Encrypted by iOS
- Tied to app signature (can't be copied between apps)
- Much harder to tamper with than UserDefaults
- Survives app reinstall (optional)

### Files:
- `RitualistCore/Sources/RitualistCore/Services/SecurePremiumCache.swift` - Keychain wrapper
- `StoreKitSubscriptionService.swift` - Uses cache as fallback, updates cache on success

### 2. ModelContainer Configuration Is Immutable

**Problem:**
- `cloudKitDatabase: .none` vs `.private(...)` is set once at init
- Cannot change sync mode without app restart

**Fix:**
- Show "Restart app to enable iCloud sync" when premium status changes
- Or: Implement ModelContainer recreation (complex, may cause data issues)

### 3. Subscription Expiry Not Handled During Session

**Problem:**
- No periodic subscription validation during app session
- 5-minute cache TTL means stale status
- Sync continues after subscription expires

**Fix:**
- Validate subscription on app foreground
- Reduce cache TTL to 30 seconds when near expiry
- Disable sync immediately when expiry detected

### 4. Cross-Device Subscription Detection

**Problem:**
- Device B doesn't detect subscription purchased on Device A
- StoreKit listener starts too late

**Fix:**
- Query `Transaction.currentEntitlements` at startup before any premium-gated features

---

## HIGH PRIORITY ISSUES

### StoreKit2

| Issue | Impact | Fix |
|-------|--------|-----|
| No grace period handling | Premature feature lockout | Check `gracePeriodExpiresDate` (iOS 18+) |
| No pending purchase state | Confusing UX for Ask to Buy | Add `.pending` to `PurchaseState` |
| Verification failures silent | Security events undetected | Log and alert on verification failure |
| No retry logic | Users give up on failed purchases | Exponential backoff, max 3 retries |
| No billing retry period | Users think subscription failed | Detect and show "Payment issue" UI |

### iCloud Sync

| Issue | Impact | Fix |
|-------|--------|-----|
| iCloud disabled mid-session | Silent data loss | Monitor `CKContainer.accountStatus()` |
| Network loss during sync | Batch data loss | Implement offline queue |
| iCloud storage full | Confusing failures | Detect quota errors, show guidance |
| Partial sync failures | Data inconsistency | Implement atomic batching |

---

## MISSING EDGE CASES

### StoreKit2 Scenarios Not Handled

1. **Interrupted purchases** - App killed mid-transaction
2. **Pending transactions** - Ask to Buy, parental controls
3. **Billing retry period** - 16-day grace for failed renewals
4. **Subscription upgrades/downgrades** - Within same group
5. **Refunds and revocations** - No notification to user
6. **Family sharing** - No detection or UI
7. **Offline entitlements** - No graceful degradation

### iCloud Scenarios Not Handled

1. **Account sign-out** - Mid-session iCloud logout
2. **Storage quota exceeded** - No user guidance
3. **Schema migration conflicts** - CloudKit merge issues
4. **Fresh install with cloud data** - 0.3s timeout too short
5. **Subscription lapse + re-subscribe** - Duplicate data conflicts

---

## RECOMMENDED IMPLEMENTATION ORDER

### Phase 1: Security & Core Fixes
1. Remove premium status from UserDefaults
2. Query StoreKit entitlements at startup (before PersistenceContainer)
3. Use in-memory cache only for premium status
4. Add "restart to enable sync" prompt on premium change

### Phase 2: Subscription Lifecycle
1. Add subscription expiry validation on foreground
2. Implement grace period detection
3. Add `.pending` purchase state
4. Handle refunds/revocations with UI notification

### Phase 3: Error Handling
1. Add purchase retry with exponential backoff
2. Implement network failure classification
3. Fix silent verification failure handling
4. Add billing retry period detection

### Phase 4: iCloud Robustness
1. Monitor iCloud account status changes
2. Implement offline sync queue
3. Handle quota exceeded errors
4. Increase iCloud KV sync timeout to 2s

### Phase 5: Edge Cases
1. Family sharing detection
2. Subscription upgrade/downgrade tracking
3. Cross-device sync indicators
4. Conflict resolution for simultaneous edits

---

## FILES REQUIRING CHANGES

### Core Files
- `RitualistCore/Sources/RitualistCore/Services/SecureSubscriptionService.swift`
- `Ritualist/Core/Services/StoreKitSubscriptionService.swift`
- `Ritualist/Core/Services/StoreKitPaywallService.swift`
- `Ritualist/DI/Container+Services.swift`
- `RitualistCore/Sources/RitualistCore/Storage/PersistenceContainer.swift`

### Supporting Files
- `Ritualist/Application/RitualistApp.swift`
- `Ritualist/Application/RootTabViewModel.swift`
- `RitualistCore/Sources/RitualistCore/Enums/Paywall/PurchaseState.swift`

---

## TESTING REQUIREMENTS

### Critical Path Tests
- [ ] Purchase completes → premium detected immediately
- [ ] Cross-device: subscribe on A → detected on B at startup
- [ ] Subscription expires → features locked immediately
- [ ] App restart → premium status correct from StoreKit
- [ ] Offline launch → cached entitlements work
- [ ] Ask to Buy → pending state shown correctly

### Security Tests
- [ ] Modified UserDefaults → premium NOT granted
- [ ] No StoreKit receipt → premium NOT granted
- [ ] Verification failure → logged and purchase rejected
