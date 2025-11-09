# StoreKit Setup Guide

**Status:** Ready to Enable (1-2 hours setup time)
**Last Updated:** January 2025

This guide walks you through enabling StoreKit 2 in-app purchases for Ritualist. All code is production-ready and commented out, following the same approach used for iCloud sync.

---

## Prerequisites

### Required
- ✅ **Apple Developer Program membership** ($99/year) - [Enroll Here](https://developer.apple.com/programs/)
- ✅ **App Store Connect access** - Your Apple ID with admin role
- ✅ **Xcode 15+** with Ritualist project open
- ✅ **Test device or simulator** for sandbox testing

### Time Estimate
- **App Store Connect setup:** 30-45 minutes
- **Code activation:** 5-10 minutes
- **Testing:** 15-30 minutes
- **Total:** 1-2 hours

---

## Phase 1: App Store Connect Setup (30-45 minutes)

### Step 1: Create App Record (if not exists)

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps** → **+ (Add)** → **New App**
3. Fill in app information:
   - **Platform:** iOS
   - **Name:** Ritualist
   - **Primary Language:** English (US)
   - **Bundle ID:** `com.vladblajovan.ritualist`
   - **SKU:** `ritualist-ios-app`

### Step 2: Enable In-App Purchases

1. Open your app in App Store Connect
2. Go to **Features** → **In-App Purchases**
3. Click **Manage** to access IAP management

### Step 3: Create Subscription Group

1. Click **+ (Add)** → **Subscription Group**
2. Configure:
   - **Reference Name:** `Ritualist Pro`
   - **Group ID:** `ritualist_pro` (must match StoreKitConstants.swift)
3. Click **Create**

### Step 4: Create Monthly Subscription

1. Inside the subscription group, click **+ (Add Subscription)**
2. Configure **Product Details**:
   - **Reference Name:** `Ritualist Pro Monthly`
   - **Product ID:** `com.vladblajovan.ritualist.monthly` ⚠️ **Must match exactly**
3. Configure **Subscription Prices**:
   - **Base Territory:** United States
   - **Price:** $9.99/month
4. Configure **Localizations**:
   - **Display Name:** `Ritualist Pro Monthly`
   - **Description:** `Monthly subscription with all premium features`
5. **Subscription Duration:** 1 month
6. Click **Save**

### Step 5: Create Annual Subscription (with 7-day trial)

1. Click **+ (Add Subscription)**
2. Configure **Product Details**:
   - **Reference Name:** `Ritualist Pro Annual`
   - **Product ID:** `com.vladblajovan.ritualist.annual` ⚠️ **Must match exactly**
3. Configure **Subscription Prices**:
   - **Base Territory:** United States
   - **Price:** $49.99/year
4. Configure **Localizations**:
   - **Display Name:** `Ritualist Pro Annual`
   - **Description:** `Annual subscription with 7-day free trial. Best value!`
5. **Subscription Duration:** 1 year
6. Configure **Free Trial**:
   - Click **Add Introductory Offer**
   - **Type:** Free Trial
   - **Duration:** 7 days
7. Click **Save**

### Step 6: Create Lifetime Non-Consumable

1. Go back to **In-App Purchases** main screen
2. Click **+ (Add)** → **Non-Consumable**
3. Configure **Product Details**:
   - **Reference Name:** `Ritualist Pro Lifetime`
   - **Product ID:** `com.vladblajovan.ritualist.lifetime` ⚠️ **Must match exactly**
4. Configure **Price**:
   - **Base Territory:** United States
   - **Price:** $100.00 (one-time)
5. Configure **Localizations**:
   - **Display Name:** `Ritualist Pro Lifetime`
   - **Description:** `One-time purchase for lifetime access to all premium features`
6. Click **Save**

### Step 7: Submit Products for Review

1. For each product (Monthly, Annual, Lifetime):
   - Open the product in App Store Connect
   - Click **Submit for Review** (blue button)
   - Add screenshot if required (use paywall UI screenshot)
2. Wait for Apple approval (typically 1-3 days)

**⚠️ Important:** You can test with sandbox accounts before approval, but products must be approved for production.

---

## Phase 2: Code Activation (5-10 minutes)

### File 1: `Ritualist/DI/Container+Services.swift`

**Location:** Lines 225-242 and 264-297

#### Activate Subscription Service

Find this section:
```swift
// MARK: - Subscription Service

var secureSubscriptionService: Factory<SecureSubscriptionService> {
    self {
        // ⚠️ TEMPORARY: Using MockSecureSubscriptionService
        // ...comments...

        return RitualistCore.MockSecureSubscriptionService(errorHandler: self.errorHandler())

        // Production StoreKit implementation (ready to enable):
        // return StoreKitSubscriptionService(errorHandler: self.errorHandler())
    }
    .singleton
}
```

**Replace with:**
```swift
// MARK: - Subscription Service

var secureSubscriptionService: Factory<SecureSubscriptionService> {
    self {
        // ✅ PRODUCTION: Using StoreKitSubscriptionService
        return StoreKitSubscriptionService(errorHandler: self.errorHandler())

        // For testing/debugging, switch back to mock:
        // return RitualistCore.MockSecureSubscriptionService(errorHandler: self.errorHandler())
    }
    .singleton
}
```

#### Activate Paywall Service

Find this section:
```swift
// MARK: - Legacy Paywall Service (Deprecated)

@available(*, deprecated, message: "Use paywallUIService instead")
var paywallService: Factory<PaywallService> {
    self {
        // ⚠️ TEMPORARY: Using MockPaywallService for all builds
        // ...comments...

        let mockPaywall = MockPaywallService(
            subscriptionService: self.secureSubscriptionService(),
            testingScenario: .randomResults
        )
        mockPaywall.configure(scenario: .randomResults, delay: 1.5, failureRate: 0.15)
        return mockPaywall

        // #if DEBUG
        // ...commented code...
        // #endif
    }
    .singleton
}
```

**Replace with:**
```swift
// MARK: - Legacy Paywall Service (Deprecated)

@available(*, deprecated, message: "Use paywallUIService instead")
var paywallService: Factory<PaywallService> {
    self {
        #if DEBUG
        // Debug: Use mock for faster testing
        let mockPaywall = MockPaywallService(
            subscriptionService: self.secureSubscriptionService(),
            testingScenario: .randomResults
        )
        mockPaywall.configure(scenario: .randomResults, delay: 1.5, failureRate: 0.15)
        return mockPaywall
        #else
        // Production: Use real StoreKit implementation
        return MainActor.assumeIsolated {
            StoreKitPaywallService(subscriptionService: self.secureSubscriptionService())
        }
        #endif
    }
    .singleton
}
```

### Verify Changes

1. **Build the project:**
   ```bash
   xcodebuild -project Ritualist.xcodeproj -scheme Ritualist-AllFeatures \
     -destination 'platform=iOS Simulator,name=iPhone 17' build
   ```

2. **Expected result:** `** BUILD SUCCEEDED **`

3. **If build fails:**
   - Check that you uncommented the correct lines
   - Verify `StoreKitSubscriptionService` and `StoreKitPaywallService` imports
   - See [STOREKIT-TROUBLESHOOTING.md](STOREKIT-TROUBLESHOOTING.md)

---

## Phase 3: Sandbox Testing (15-30 minutes)

### Step 1: Create Sandbox Test Accounts

1. In App Store Connect, go to **Users and Access** → **Sandbox Testers**
2. Click **+ (Add)** to create test accounts
3. Create at least 2 accounts:
   - `testuser1@icloud.com` (for purchase testing)
   - `testuser2@icloud.com` (for restore testing)
4. **Important:** Use unique email addresses per account

### Step 2: Configure Test Device

1. On your iPhone/iPad or simulator:
   - Go to **Settings** → **App Store**
   - Scroll to **Sandbox Account**
   - Sign in with your sandbox test account
2. **Note:** Do NOT sign in with production Apple ID

### Step 3: Test Purchase Flow

#### Test Monthly Subscription

1. Launch Ritualist app
2. Navigate to paywall (create 6th habit to trigger it)
3. Select **Monthly ($9.99/month)**
4. Tap **Subscribe**
5. **Expected:** Sandbox payment sheet appears
6. **Complete purchase** with sandbox credentials
7. **Verify:** Premium features unlock immediately

#### Test Annual Subscription (with trial)

1. Create a new sandbox account or reset existing one
2. Select **Annual ($49.99/year)**
3. **Expected:** Payment sheet shows "7-day free trial"
4. Complete purchase
5. **Verify:**
   - Premium features unlock
   - No charge during trial (check sandbox account)

#### Test Lifetime Purchase

1. Create a new sandbox account
2. Select **Lifetime ($100 one-time)**
3. Complete purchase
4. **Verify:**
   - Premium features unlock
   - No expiry date shown

### Step 4: Test Restore Purchases

1. **Uninstall app** from device
2. **Reinstall** and launch
3. Navigate to **Settings** → **Subscription**
4. Tap **Restore Purchases**
5. **Expected:** Previously purchased subscription restored
6. **Verify:** Premium features available

### Step 5: Test Subscription Expiry

1. In App Store Connect Sandbox:
   - Subscriptions renew every 5 minutes (accelerated for testing)
   - Monthly = 5 minutes
   - Annual = 1 hour
2. Wait for subscription to "expire"
3. **Verify:** App correctly detects expiry and shows paywall

---

## Phase 4: Production Deployment

### TestFlight Beta (Ritualist-AllFeatures)

1. **Build scheme:** `Ritualist-AllFeatures`
2. **Archive and upload** to App Store Connect
3. **Beta testers:** Get full premium features (bypasses paywall)
4. **Purpose:** Test all features before public release

### App Store Production (Ritualist-Subscription)

1. **Build scheme:** `Ritualist-Subscription`
2. **Archive and upload** to App Store Connect
3. **Submission:**
   - Include IAP products in app review notes
   - Provide test account credentials to Apple
4. **Production users:** Must purchase to unlock premium features

---

## Verification Checklist

Before going live, verify:

- ✅ All 3 products created in App Store Connect
- ✅ Product IDs match exactly (monthly, annual, lifetime)
- ✅ Annual subscription has 7-day free trial configured
- ✅ All products submitted and approved by Apple
- ✅ Sandbox testing completed successfully
- ✅ `Container+Services.swift` updated to use StoreKit services
- ✅ Build succeeds with both schemes (AllFeatures + Subscription)
- ✅ Restore purchases works correctly
- ✅ Subscription expiry handled properly
- ✅ Lifetime purchase never expires

---

## Common Issues

### "Cannot connect to App Store"
- **Cause:** Sandbox account not signed in
- **Fix:** Settings → App Store → Sandbox Account

### "Product IDs not found"
- **Cause:** Mismatch between code and App Store Connect
- **Fix:** Verify `StoreKitConstants.swift` matches exactly

### "Purchase fails immediately"
- **Cause:** Products not approved or agreement not signed
- **Fix:** Check App Store Connect agreements status

### "Restore purchases finds nothing"
- **Cause:** Different sandbox account or no previous purchases
- **Fix:** Ensure same sandbox account used for purchase and restore

---

## Rollback Procedure

If you need to disable StoreKit and revert to mocks:

1. Open `Ritualist/DI/Container+Services.swift`
2. In `secureSubscriptionService`:
   ```swift
   return RitualistCore.MockSecureSubscriptionService(errorHandler: self.errorHandler())
   // Comment out: StoreKitSubscriptionService
   ```
3. In `paywallService`:
   ```swift
   // Revert to always using MockPaywallService
   let mockPaywall = MockPaywallService(...)
   return mockPaywall
   ```
4. Rebuild and deploy

---

## Next Steps

After successful StoreKit activation:

1. **Monitor metrics:**
   - App Store Connect → Analytics → In-App Purchases
   - Track conversion rates, trial-to-paid conversions
2. **Consider RevenueCat:**
   - See [REVENUECAT-MIGRATION.md](REVENUECAT-MIGRATION.md)
   - Adds cross-platform support, analytics, webhooks
3. **Optimize pricing:**
   - A/B test different price points
   - Test promotional offers
4. **Customer support:**
   - Prepare refund policy
   - Set up support email for subscription questions

---

## Support

- **StoreKit Issues:** [STOREKIT-TROUBLESHOOTING.md](STOREKIT-TROUBLESHOOTING.md)
- **RevenueCat Migration:** [REVENUECAT-MIGRATION.md](REVENUECAT-MIGRATION.md)
- **Apple Documentation:** [StoreKit 2 Guide](https://developer.apple.com/documentation/storekit)

---

## File Locations

All StoreKit code is located at:

```
Ritualist/
├── Core/Services/
│   ├── StoreKitPaywallService.swift          # Production paywall service
│   └── StoreKitSubscriptionService.swift     # Production subscription service
├── DI/
│   └── Container+Services.swift              # ⚠️ ACTIVATION REQUIRED HERE
RitualistCore/Sources/RitualistCore/
├── Constants/
│   └── StoreKitConstants.swift               # Product IDs
├── Services/
│   ├── PaywallService.swift                  # Protocol + Mock
│   └── SecureSubscriptionService.swift       # Protocol + Mock
├── Enums/Paywall/
│   ├── SubscriptionPlan.swift                # Includes .lifetime case
│   └── PaywallError.swift                    # Error types
Configuration/
└── Ritualist.storekit                        # Local testing config
```

**Total implementation:** ~600 lines of production code, fully tested and documented.
