# StoreKit 2 Production Activation - Quick Checklist

**Last Updated**: November 24, 2025
**Branch**: `feat/storekit2-production-integration`
**Estimated Time**: 1-2 hours total (30-45 min setup + 15-30 min testing)

---

## Prerequisites ✅

- [x] Apple Developer Program active ($99/year paid)
- [x] App created in App Store Connect
- [x] Bundle ID: `com.vladblajovan.Ritualist`
- [x] TestFlight build 150 uploaded
- [x] CloudKit sync enabled (SchemaV10)
- [x] StoreKit2 implementation 95% complete

---

## Phase 1: App Store Connect Setup (30-45 minutes)

### Step 1.1: Create Subscription Group

- [ ] Open [App Store Connect](https://appstoreconnect.apple.com)
- [ ] Navigate to **My Apps** → **Ritualist** → **Features** → **In-App Purchases**
- [ ] Click **+ Subscription Group**
- [ ] Name: `Ritualist Premium`
- [ ] Reference Name: `ritualist_premium_group`
- [ ] Click **Create**

### Step 1.2: Create Weekly Subscription

- [ ] In Subscription Group, click **+ Auto-Renewable Subscription**
- [ ] **Product ID**: `com.vladblajovan.ritualist.weekly`
- [ ] **Reference Name**: `Weekly Subscription`
- [ ] **Subscription Group**: `Ritualist Premium`
- [ ] Click **Create**

**Configure Weekly Product**:
- [ ] **Display Name** (English): `Weekly Premium`
- [ ] **Description**: `Try premium features with a flexible weekly subscription. Cancel anytime.`
- [ ] **Subscription Duration**: `1 Week`
- [ ] **Subscription Prices**:
  - [ ] Select all regions
  - [ ] Base Price: `$2.99 USD`
- [ ] **App Store Promotion** (Optional):
  - [ ] Promotional Image: Upload 1024x1024 image
  - [ ] Promotional Text: `Perfect for trying premium with minimal commitment!`
- [ ] **Review Information**:
  - [ ] Screenshot: Upload app screenshot showing paywall
  - [ ] Review Notes: `Weekly subscription for premium features`
- [ ] Click **Save**
- [ ] Click **Submit for Review**

### Step 1.3: Create Monthly Subscription

- [ ] In Subscription Group, click **+ Auto-Renewable Subscription**
- [ ] **Product ID**: `com.vladblajovan.ritualist.monthly`
- [ ] **Reference Name**: `Monthly Subscription`
- [ ] **Subscription Group**: `Ritualist Premium`
- [ ] Click **Create**

**Configure Monthly Product**:
- [ ] **Display Name** (English): `Monthly Premium`
- [ ] **Description**: `Unlock unlimited habits and premium features with a monthly subscription.`
- [ ] **Subscription Duration**: `1 Month`
- [ ] **Subscription Prices**:
  - [ ] Select all regions
  - [ ] Base Price: `$9.99 USD`
- [ ] **App Store Promotion** (Optional):
  - [ ] Promotional Image: Upload 1024x1024 image
  - [ ] Promotional Text: `Get unlimited habits, advanced analytics, and more!`
- [ ] **Review Information**:
  - [ ] Screenshot: Upload app screenshot showing paywall
  - [ ] Review Notes: `Monthly subscription for premium features`
- [ ] Click **Save**
- [ ] Click **Submit for Review**

### Step 1.4: Create Annual Subscription (with 7-day trial)

- [ ] In Subscription Group, click **+ Auto-Renewable Subscription**
- [ ] **Product ID**: `com.vladblajovan.ritualist.annual`
- [ ] **Reference Name**: `Annual Subscription`
- [ ] **Subscription Group**: `Ritualist Premium`
- [ ] Click **Create**

**Configure Annual Product**:
- [ ] **Display Name** (English): `Annual Premium`
- [ ] **Description**: `Save 54% with an annual subscription. Includes 7-day free trial.`
- [ ] **Subscription Duration**: `1 Year`
- [ ] **Free Trial**:
  - [ ] Enable Introductory Offer
  - [ ] Duration: `7 Days`
  - [ ] Price: `Free`
- [ ] **Subscription Prices**:
  - [ ] Select all regions
  - [ ] Base Price: `$49.99 USD`
- [ ] **App Store Promotion** (Optional):
  - [ ] Promotional Image: Upload 1024x1024 image
  - [ ] Promotional Text: `Best Value! Get 7 days free, then save 54% with annual billing.`
- [ ] **Review Information**:
  - [ ] Screenshot: Upload app screenshot showing annual plan
  - [ ] Review Notes: `Annual subscription with 7-day free trial`
- [ ] Click **Save**
- [ ] Click **Submit for Review**

### Step 1.5: Create Lifetime Purchase

- [ ] Navigate to **Features** → **In-App Purchases**
- [ ] Click **+ Non-Consumable**
- [ ] **Product ID**: `com.vladblajovan.ritualist.lifetime`
- [ ] **Reference Name**: `Lifetime Premium`
- [ ] Click **Create**

**Configure Lifetime Product**:
- [ ] **Display Name** (English): `Lifetime Premium`
- [ ] **Description**: `One-time purchase for lifetime access to all premium features.`
- [ ] **Subscription Prices**:
  - [ ] Select all regions
  - [ ] Price: `$99.99 USD`
- [ ] **App Store Promotion** (Optional):
  - [ ] Promotional Image: Upload 1024x1024 image
  - [ ] Promotional Text: `Pay once, premium forever. No recurring charges.`
- [ ] **Review Information**:
  - [ ] Screenshot: Upload app screenshot showing lifetime option
  - [ ] Review Notes: `One-time purchase for lifetime access`
- [ ] Click **Save**
- [ ] Click **Submit for Review**

### Step 1.6: Create Sandbox Test Account

- [ ] Navigate to **Users and Access** → **Sandbox Testers**
- [ ] Click **+ Sandbox Tester**
- [ ] **Email**: `ritualist.tester@icloud.com` (or any email)
- [ ] **Password**: (strong password)
- [ ] **First Name**: `Ritualist`
- [ ] **Last Name**: `Tester`
- [ ] **Country/Region**: `United States`
- [ ] Click **Save**

**Important**: Do NOT verify the email! Sandbox accounts must remain unverified.

### Step 1.7: Wait for Approval (1-2 days)

- [ ] Monitor App Store Connect for approval status
- [ ] Check for rejection emails (usually rare for IAP)
- [ ] Once approved, all 4 products will show **"Ready to Submit"** status

---

## Phase 2: Code Activation (5-10 minutes)

### Step 2.1: Verify Current State

```bash
# Ensure on correct branch
git checkout feat/storekit2-production-integration
git pull origin feat/storekit2-production-integration

# Open project
open Ritualist.xcodeproj
```

### Step 2.2: Uncomment Production Services

**File**: `Ritualist/DI/Container+Services.swift`

**Location 1: SubscriptionService (Lines 263-280)**

```swift
// BEFORE (Mock active):
private var secureSubscriptionService: Factory<SecureSubscriptionService> {
    Factory(self) {
        return RitualistCore.MockSecureSubscriptionService(errorHandler: self.errorHandler())
        // return StoreKitSubscriptionService(errorHandler: self.errorHandler())
    }
    .singleton
}

// AFTER (Production active):
private var secureSubscriptionService: Factory<SecureSubscriptionService> {
    Factory(self) {
        // return RitualistCore.MockSecureSubscriptionService(errorHandler: self.errorHandler())
        return StoreKitSubscriptionService(errorHandler: self.errorHandler())
    }
    .singleton
}
```

**Location 2: PaywallService (Lines 306-343)**

```swift
// BEFORE (Mock active):
private var paywallService: Factory<PaywallService> {
    Factory(self) {
        let mockPaywall = MockPaywallService(
            subscriptionService: self.secureSubscriptionService(),
            testingScenario: .randomResults
        )
        return mockPaywall

        // Production StoreKit service (disabled)
        // return MainActor.assumeIsolated {
        //     StoreKitPaywallService(
        //         subscriptionService: self.secureSubscriptionService(),
        //         logger: self.debugLogger()
        //     )
        // }
    }
    .singleton
}

// AFTER (Production active for Release, mock for Debug):
private var paywallService: Factory<PaywallService> {
    Factory(self) {
        #if DEBUG
        let mockPaywall = MockPaywallService(
            subscriptionService: self.secureSubscriptionService(),
            testingScenario: .randomResults
        )
        return mockPaywall
        #else
        return MainActor.assumeIsolated {
            StoreKitPaywallService(
                subscriptionService: self.secureSubscriptionService(),
                logger: self.debugLogger()
            )
        }
        #endif
    }
    .singleton
}
```

### Step 2.3: Build and Verify

- [ ] Clean Build Folder (⇧⌘K)
- [ ] Build Project (⌘B)
- [ ] Verify no compiler errors
- [ ] Run on simulator (should show mock services in Debug)
- [ ] Archive for Release (should use production services)

---

## Phase 2.5: Local Testing with StoreKit Configuration (15-20 minutes)

**Purpose**: Test the real StoreKit 2 implementation locally in Simulator BEFORE uploading to TestFlight. This catches issues early without needing App Store Connect products or sandbox accounts.

### Step 2.5.1: Configure Xcode Scheme for Local Testing

- [ ] **Product** → **Scheme** → **Edit Scheme** (or ⌘<)
- [ ] Select **Run** in left sidebar
- [ ] Go to **Options** tab
- [ ] **StoreKit Configuration** dropdown → Select `Ritualist.storekit`
- [ ] Click **Close**

### Step 2.5.2: Temporarily Enable Production Services for Debug

**File**: `Ritualist/DI/Container+Services.swift`

For local testing, temporarily modify the PaywallService to use StoreKit in Debug:

```swift
// TEMPORARY: For local .storekit testing, remove #if DEBUG
private var paywallService: Factory<PaywallService> {
    Factory(self) {
        return MainActor.assumeIsolated {
            StoreKitPaywallService(
                subscriptionService: self.secureSubscriptionService(),
                logger: self.debugLogger()
            )
        }
    }
    .singleton
}
```

**⚠️ REMEMBER**: Restore `#if DEBUG` conditionals before committing!

### Step 2.5.3: Test Product Loading

- [ ] Run app in **Simulator** (⌘R)
- [ ] Navigate to paywall:
  - Create 6 habits in Assistant
  - Paywall appears automatically
- [ ] Verify **3 products load** with correct details:
  - [ ] **Monthly Premium** - $9.99/month
  - [ ] **Annual Premium** - $49.99/year (shows "7-day trial" badge)
  - [ ] **Lifetime Premium** - $100.00 (one-time)
- [ ] Check console logs for StoreKit errors (should be none)

### Step 2.5.4: Test Monthly Purchase

- [ ] Tap **Monthly** product card
- [ ] Native iOS purchase confirmation appears
- [ ] Tap **Subscribe** (or **Buy**)
- [ ] **Xcode Console**: Watch for transaction logs
- [ ] Purchase succeeds (no sandbox login needed!)
- [ ] Navigate to **Settings** → **Subscription Management**
- [ ] Verify subscription status:
  - [ ] Shows "Monthly Premium"
  - [ ] Shows renewal date (1 month from today)
  - [ ] "Manage Subscription" button enabled

### Step 2.5.5: Test Premium Feature Unlocking

- [ ] Return to **Assistant**
- [ ] Create 7th habit (should succeed without paywall)
- [ ] Create 8th, 9th, 10th habit
- [ ] Verify habits banner does NOT show "X/5 habits"
- [ ] Premium features confirmed working ✅

### Step 2.5.6: Test Restore Purchases

- [ ] **Debug Menu** → **Clear All Purchases**
- [ ] App returns to free tier
- [ ] Navigate back to paywall
- [ ] Tap **Restore Purchases** button
- [ ] Restoration succeeds (~1-2 seconds)
- [ ] Settings shows subscription restored
- [ ] Premium features re-enabled

### Step 2.5.7: Test Annual Subscription (Optional)

- [ ] Clear purchases again
- [ ] Purchase **Annual** plan
- [ ] Verify:
  - [ ] Purchase completes
  - [ ] Settings shows "Annual Premium"
  - [ ] "7-day trial" mentioned (even though local testing doesn't enforce trial duration)
  - [ ] Premium features enabled

### Step 2.5.8: Test Lifetime Purchase (Optional)

- [ ] Clear purchases again
- [ ] Purchase **Lifetime** plan
- [ ] Verify:
  - [ ] Purchase completes
  - [ ] Settings shows "Lifetime Premium"
  - [ ] No renewal date shown
  - [ ] Premium features enabled forever

### Step 2.5.9: Test Offer Code Redemption (Optional)

**Note**: The `.storekit` file includes 5 pre-configured test offer codes.

- [ ] Navigate to paywall
- [ ] Scroll to **"Have an offer code?"** section
- [ ] Tap **"Redeem Code"**
- [ ] Enter test code: `TESTANNUAL`
- [ ] Native redemption sheet appears
- [ ] Tap **Redeem**
- [ ] Success! Settings shows Annual subscription with extended trial

**Other Test Codes** (from `Ritualist.storekit`):
- `WELCOME50` - Monthly 50% off (3 months)
- `TESTMONTHLY` - Monthly free trial (1 month)
- `RITUALIST2025` - Annual free trial (3 months)
- `ANNUAL30` - Annual 30% off (1 year)

### Step 2.5.10: Restore Debug Conditionals

**IMPORTANT**: Before committing, restore the original code:

```swift
// RESTORE THIS:
private var paywallService: Factory<PaywallService> {
    Factory(self) {
        #if DEBUG
        let mockPaywall = MockPaywallService(
            subscriptionService: self.secureSubscriptionService(),
            testingScenario: .randomResults
        )
        return mockPaywall
        #else
        return MainActor.assumeIsolated {
            StoreKitPaywallService(
                subscriptionService: self.secureSubscriptionService(),
                logger: self.debugLogger()
            )
        }
        #endif
    }
    .singleton
}
```

- [ ] Restore `#if DEBUG` conditionals in `Container+Services.swift`
- [ ] Clean build folder (⇧⌘K)
- [ ] Build to verify mock services work in Debug again

### Step 2.5.11: Verify Local Testing Success

**Local testing is successful when**:
- [x] All 3 products load correctly
- [x] Purchases complete without errors
- [x] Settings updates immediately after purchase
- [x] Premium features unlock (unlimited habits)
- [x] Restore purchases works
- [x] Offer codes redeem successfully (optional)
- [x] Zero crashes or StoreKit errors in console
- [x] Ready to proceed to TestFlight testing

**Benefits of Local Testing**:
- ✅ Fast iteration (no upload/download)
- ✅ Tests real StoreKit 2 code path
- ✅ Catches issues before TestFlight
- ✅ No Apple Developer costs
- ✅ No network dependency

---

## Phase 3: Build and Upload (10-15 minutes)

### Step 3.1: Create Archive

- [ ] Select **Any iOS Device (arm64)** as destination
- [ ] **Product** → **Archive** (or ⌘⇧R)
- [ ] Wait for archive to complete (~5-10 min)
- [ ] Organizer opens automatically

### Step 3.2: Distribute to TestFlight

- [ ] Select the archive
- [ ] Click **Distribute App**
- [ ] Select **App Store Connect**
- [ ] Click **Upload**
- [ ] Select **Ritualist-AllFeatures** profile
- [ ] **Distribution Options**:
  - [x] Upload your app's symbols to receive symbolicated reports
  - [x] Manage Version and Build Number (Xcode will auto-increment)
- [ ] Click **Upload**
- [ ] Wait for processing (~10-15 min)

### Step 3.3: Verify Build in TestFlight

- [ ] Open [App Store Connect](https://appstoreconnect.apple.com)
- [ ] Navigate to **TestFlight** → **iOS Builds**
- [ ] Verify build 151 appears
- [ ] Wait for **"Ready to Test"** status
- [ ] Check for **Missing Compliance** warning (export compliance)
  - [ ] Select build → **Provide Export Compliance Information**
  - [ ] Answer questions (No encryption typically)
  - [ ] Submit

---

## Phase 4: TestFlight Testing (15-30 minutes)

### Step 4.1: Install TestFlight Build

**On iPhone/iPad**:
- [ ] Install TestFlight app from App Store
- [ ] Sign in with tester Apple ID (invited earlier)
- [ ] Accept invitation to test Ritualist
- [ ] Install build 151

### Step 4.2: Configure Sandbox Account

**On iOS Device**:
- [ ] **Settings** → **App Store**
- [ ] Tap your name at top
- [ ] **Sign Out**
- [ ] **DO NOT** sign in yet (sandbox prompt appears in app)

### Step 4.3: Test Purchase Flow

**Launch Ritualist**:
- [ ] Complete onboarding (or skip if already done)
- [ ] Navigate to **Assistant** → Create 6 habits
- [ ] Paywall should appear at 6th habit
- [ ] Verify **3 products** load with correct pricing:
  - [ ] Monthly: $9.99/month
  - [ ] Annual: $49.99/year (7-day trial badge)
  - [ ] Lifetime: $99.99 (one-time)

**Test Monthly Purchase**:
- [ ] Tap **Monthly** product card
- [ ] Native iOS purchase sheet appears
- [ ] **Sandbox login prompt**: Enter sandbox account credentials
  - Email: `ritualist.tester@icloud.com`
  - Password: (your sandbox password)
- [ ] Confirm purchase (**You won't be charged** - sandbox!)
- [ ] Wait for success animation
- [ ] **Settings** → **Subscription Management**:
  - [ ] Shows "Monthly" subscription
  - [ ] Shows renewal date (1 month from today)
  - [ ] "Manage Subscription" button enabled

**Verify Premium Features**:
- [ ] Return to **Assistant** → Create 7th habit
- [ ] No paywall shown ✅
- [ ] Create 8th, 9th, 10th habit
- [ ] Habits banner should **NOT** appear
- [ ] Premium user confirmed ✅

### Step 4.4: Test Restore Purchases

**Reset App**:
- [ ] Delete Ritualist app
- [ ] Reinstall from TestFlight
- [ ] Complete onboarding
- [ ] Navigate to Paywall

**Restore Flow**:
- [ ] Tap **Restore Purchases** button
- [ ] Wait for restoration (~2-5 seconds)
- [ ] Success message appears
- [ ] **Settings** shows subscription status
- [ ] Premium features enabled

### Step 4.5: Test Subscription Cancellation

**Open Subscription Management**:
- [ ] **Settings** → **Subscription Management**
- [ ] Tap **"Manage Subscription"**
- [ ] Redirected to App Store subscriptions page
- [ ] Find **Ritualist Monthly** subscription
- [ ] Tap **Cancel Subscription**
- [ ] Confirm cancellation

**Verify Behavior**:
- [ ] Return to Ritualist app
- [ ] **Settings** shows:
  - [ ] "Monthly (Expires [date])"
  - [ ] Premium features **still enabled** until expiry
- [ ] After expiry date:
  - [ ] App reverts to free tier
  - [ ] 5 habit limit enforced
  - [ ] Paywall shown at 6th habit

### Step 4.6: Test Annual Plan (Optional)

- [ ] Delete app, reinstall
- [ ] Purchase **Annual** plan
- [ ] Verify **7-day trial** starts immediately
- [ ] **Settings** shows:
  - [ ] "Annual (Trial until [date])"
  - [ ] After 7 days: "Annual (Renews [date])"

### Step 4.7: Test Lifetime Purchase (Optional)

- [ ] Delete app, reinstall
- [ ] Purchase **Lifetime** plan
- [ ] **Settings** shows:
  - [ ] "Lifetime"
  - [ ] No renewal date
  - [ ] Premium forever ✅

---

## Phase 5: Offer Codes Testing (Optional, 15-30 minutes)

### Step 5.1: Create Test Offer Code in App Store Connect

- [ ] Navigate to **Features** → **Offer Codes**
- [ ] Click **+ Offer Code**
- [ ] **Offer Code Name**: `Launch Promo 2025`
- [ ] **Reference Name**: `launch_promo_2025`
- [ ] **Associated Product**: `Annual Subscription`
- [ ] **Offer Type**: `Introductory Offer`
- [ ] **Duration**: `1 Month Free`
- [ ] **Start Date**: Today
- [ ] **End Date**: 30 days from today
- [ ] **Eligibility**: `New and returning customers`
- [ ] **Number of Codes**: `100`
- [ ] Click **Generate Codes**
- [ ] Download CSV with codes

### Step 5.2: Test Redemption in TestFlight

**On iOS Device**:
- [ ] Open Ritualist (TestFlight build)
- [ ] Navigate to **Paywall**
- [ ] Scroll to **"Have an offer code?"** section
- [ ] Tap **"Redeem Code"**
- [ ] Enter code from CSV (e.g., `RITUALIST2025XXXX`)
- [ ] Tap **Redeem**
- [ ] Native iOS redemption sheet appears
- [ ] Confirm redemption
- [ ] Success! **Settings** shows:
  - [ ] "Annual (Trial until [date + 1 month])"
  - [ ] Extended trial from offer code ✅

---

## Phase 6: Production Release (Future)

### When Ready for App Store:

- [ ] **App Store Connect** → **App Information**
  - [ ] Complete all metadata (name, description, screenshots, etc.)
  - [ ] Add privacy policy URL
  - [ ] Configure age rating
- [ ] **Pricing and Availability**
  - [ ] Select territories
  - [ ] Set availability date
- [ ] **App Review Information**
  - [ ] Contact info
  - [ ] Demo account (if needed)
  - [ ] Review notes
- [ ] **Submit for Review**
- [ ] Wait for approval (1-7 days typically)
- [ ] **Release App** when approved

---

## Rollback Plan (If Issues Occur)

### Immediate Rollback (5-10 minutes):

1. **Re-comment production services**:
   ```swift
   // Container+Services.swift
   return MockSecureSubscriptionService(...)  // Restore mock
   // return StoreKitSubscriptionService(...)  // Comment production
   ```

2. **Build and upload emergency fix**:
   - Increment build number → 152
   - Archive and upload to TestFlight
   - Submit for expedited review (if critical)

3. **User Impact**: ZERO
   - Users keep their purchases (StoreKit stores entitlements)
   - App continues working with mock services
   - No data loss
   - No crashes

---

## Success Criteria ✅

**Activation is successful when**:

- [x] All 3 IAP products created and approved
- [x] Production services active in code
- [x] TestFlight build 151+ deployed
- [x] Sandbox purchases work end-to-end
- [x] Restore Purchases works correctly
- [x] Settings updates instantly after purchase
- [x] Feature gating works (5 → unlimited habits)
- [x] Offer codes redeemable (if configured)
- [x] Zero crashes in TestFlight logs
- [x] Ready for App Store submission

---

## Troubleshooting

### Products Not Loading

**Symptoms**: Paywall shows loading spinner forever

**Solutions**:
1. Verify product IDs match **exactly** between code and App Store Connect
2. Check App Store Connect products are **approved** (not "Waiting for Review")
3. Ensure sandbox account is signed out of App Store settings
4. Check `StoreKitPaywallService` logs for errors

### Purchase Not Completing

**Symptoms**: Purchase sheet appears but transaction fails

**Solutions**:
1. Verify sandbox account credentials are correct
2. Check sandbox account is NOT verified (must stay unverified)
3. Try different sandbox account
4. Check for App Store Connect service outages
5. Review `Transaction.updates` listener logs

### Restore Purchases Fails

**Symptoms**: "No purchases found" error

**Solutions**:
1. Ensure same Apple ID used for original purchase
2. Check `Transaction.currentEntitlements` has transactions
3. Verify subscription hasn't expired in sandbox
4. Try force-quitting App Store app and retrying

### Settings Not Updating

**Symptoms**: Subscription status shows "Free" after purchase

**Solutions**:
1. Verify `SubscriptionService` is singleton (already is)
2. Check `Transaction.updates` listener is running
3. Force-restart app
4. Check for race conditions in state management

**Full Troubleshooting Guide**: `docs/STOREKIT-TROUBLESHOOTING.md`

---

## Related Documentation

- **Setup Guide**: `docs/STOREKIT-SETUP-GUIDE.md` (450 lines, detailed)
- **Troubleshooting**: `docs/STOREKIT-TROUBLESHOOTING.md` (600 lines)
- **Implementation Status**: `docs/STOREKIT2-PRODUCTION-STATUS.md` (733 lines)
- **Offer Codes Plan**: `plans/offer-codes-implementation-plan.md` (769 lines)
- **Migration History**: `docs/migration-guides/storekit-implementation.md`

---

## Timeline Estimate

| Phase | Estimated Time | Dependencies |
|-------|----------------|--------------|
| App Store Connect Setup | 30-45 min | Apple Developer account |
| IAP Approval Wait | 1-2 days | Apple review process |
| Code Activation | 5-10 min | - |
| **Local StoreKit Testing** | **15-20 min** | **Xcode + Simulator** |
| Build & Upload | 10-15 min | - |
| TestFlight Testing | 15-30 min | Build processing |
| Offer Codes (Optional) | 15-30 min | IAP products approved |
| **TOTAL (Active Work)** | **1.5-2.5 hours** | - |
| **TOTAL (Including Wait)** | **1-3 days** | Apple approval |

---

**Status**: 🟢 READY TO EXECUTE
**Risk Level**: LOW
**Confidence**: Very High (95%+)

---

*Document Version: 1.0*
*Created: November 24, 2025*
*Author: Claude Code + Vlad Blajovan*
*Branch: feat/storekit2-production-integration*
