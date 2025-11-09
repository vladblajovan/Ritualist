# StoreKit Troubleshooting Guide

**Last Updated:** January 2025

This guide covers common issues when setting up and using StoreKit 2 in-app purchases for Ritualist.

---

## Table of Contents

1. [App Store Connect Issues](#app-store-connect-issues)
2. [Product Loading Issues](#product-loading-issues)
3. [Purchase Flow Issues](#purchase-flow-issues)
4. [Sandbox Testing Issues](#sandbox-testing-issues)
5. [Subscription Validation Issues](#subscription-validation-issues)
6. [Build & Compilation Issues](#build--compilation-issues)
7. [Production Issues](#production-issues)

---

## App Store Connect Issues

### ❌ "Cannot create subscription group"

**Symptoms:**
- Error when trying to create subscription group in App Store Connect
- "Group ID already exists" message

**Causes:**
- Group ID `ritualist_pro` already exists
- Previous test app used the same ID

**Solutions:**
1. **Use existing group:**
   - Check if group already exists
   - Use that group instead of creating new one
2. **Change group ID:**
   - Update `StoreKitConstants.swift`:
     ```swift
     public static let subscriptionGroupID = "ritualist_pro_v2"
     ```
   - Create new group in App Store Connect with matching ID

---

### ❌ "Product IDs must be unique"

**Symptoms:**
- Cannot create products with IDs from `StoreKitConstants.swift`
- "Product ID already in use" error

**Causes:**
- Product IDs used in another app or deleted product

**Solutions:**
1. **Check deleted products:**
   - App Store Connect → In-App Purchases → Deleted
   - Restore if needed
2. **Use new IDs:**
   - Update `StoreKitConstants.swift`:
     ```swift
     public static let monthly = "com.vladblajovan.ritualist.monthly.v2"
     public static let annual = "com.vladblajovan.ritualist.annual.v2"
     public static let lifetime = "com.vladblajovan.ritualist.lifetime.v2"
     ```
   - Update `.storekit` file to match

---

### ❌ "Agreements need to be signed"

**Symptoms:**
- Cannot submit products for review
- Red banner at top of App Store Connect

**Causes:**
- Paid Applications Agreement not signed
- Banking/tax info incomplete

**Solutions:**
1. **Sign agreements:**
   - App Store Connect → Agreements, Tax, and Banking
   - Sign all pending agreements
2. **Complete banking info:**
   - Add bank account details
   - Complete tax forms (W-8BEN or W-9)
3. **Wait for processing:**
   - Apple processes agreements within 24-48 hours

---

## Product Loading Issues

### ❌ "Products not available" error

**Symptoms:**
- `loadProducts()` returns empty array
- Error: `PaywallError.productsNotAvailable`

**Causes:**
1. Products not created in App Store Connect
2. Product IDs mismatch between code and App Store Connect
3. Network connectivity issue
4. App not configured in App Store Connect

**Solutions:**

**1. Verify Product IDs:**
```swift
// In StoreKitConstants.swift - these MUST match App Store Connect exactly
public static let monthly = "com.vladblajovan.ritualist.monthly"
public static let annual = "com.vladblajovan.ritualist.annual"
public static let lifetime = "com.vladblajovan.ritualist.lifetime"
```

**2. Check App Store Connect:**
- Navigate to your app → In-App Purchases
- Verify all 3 products exist
- Check product status (must be "Ready to Submit" or approved)

**3. Test with .storekit file:**
```bash
# In Xcode:
# 1. Product → Scheme → Edit Scheme
# 2. Run → Options → StoreKit Configuration
# 3. Select "Ritualist.storekit"
# 4. Run app and test
```

**4. Enable StoreKit logging:**
```swift
// Add to StoreKitPaywallService.swift temporarily
public func loadProducts() async throws -> [RitualistCore.Product] {
    do {
        print("🛍️ Loading products for IDs: \(StoreKitProductID.allProducts)")
        storeProducts = try await StoreKit.Product.products(for: StoreKitProductID.allProducts)
        print("🛍️ Loaded \(storeProducts.count) products")

        for product in storeProducts {
            print("  - \(product.id): \(product.displayName) (\(product.displayPrice))")
        }
        // ...rest of method
    }
}
```

---

### ❌ "Product prices showing as $0.00"

**Symptoms:**
- Products load but show no price
- `displayPrice` is empty or "$0.00"

**Causes:**
- Price not configured in App Store Connect
- Base territory not set

**Solutions:**
1. **Set pricing:**
   - App Store Connect → Product → Subscription Pricing
   - Set price for base territory (United States)
   - Save changes
2. **Wait for propagation:**
   - Pricing changes can take 15-30 minutes to propagate
3. **Clear cache:**
   - Delete app from device
   - Reinstall and test

---

## Purchase Flow Issues

### ❌ "Purchase sheet doesn't appear"

**Symptoms:**
- Tap purchase button, nothing happens
- No payment UI shown

**Causes:**
1. Running in simulator without .storekit configuration
2. MainActor context issue
3. Product not properly loaded

**Solutions:**

**1. Configure StoreKit for simulator:**
```bash
# Xcode → Product → Scheme → Edit Scheme
# Run → Options → StoreKit Configuration → Select Ritualist.storekit
```

**2. Verify MainActor:**
```swift
// StoreKitPaywallService is @MainActor @Observable
// Purchase should run on main actor
@MainActor
public final class StoreKitPaywallService: PaywallService {
    // ...
}
```

**3. Check product availability:**
```swift
public func purchase(_ product: RitualistCore.Product) async throws -> Bool {
    guard let storeProduct = storeProducts.first(where: { $0.id == product.id }) else {
        print("❌ Product not found: \(product.id)")
        throw PaywallError.productsNotAvailable
    }
    // ...
}
```

---

### ❌ "Purchase fails with 'User cancelled'"

**Symptoms:**
- Purchase immediately fails
- Error: `PaywallError.userCancelled`

**Causes:**
1. User actually cancelled
2. Payment method issue (sandbox)
3. StoreKit configuration error

**Solutions:**

**For sandbox testing:**
1. **Verify sandbox account:**
   - Settings → App Store → Sandbox Account
   - Sign in with test account
2. **Check account status:**
   - App Store Connect → Users and Access → Sandbox Testers
   - Ensure account is active
3. **Try different sandbox account:**
   - Some accounts can get "stuck" - create new one

**For production:**
1. **Check payment method:**
   - User needs valid payment method on Apple ID
2. **Try restore purchases:**
   - May unlock if previous purchase exists

---

### ❌ "Transaction verification failed"

**Symptoms:**
- Purchase completes but verification fails
- Error in logs: "Transaction verification failed"

**Causes:**
1. Jailbroken device (production)
2. Corrupted receipt
3. Clock/timezone issue

**Solutions:**

**1. Check device integrity:**
```swift
// StoreKitSubscriptionService already handles this
private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T? {
    switch result {
    case .unverified(_, let verificationError):
        // Log the specific error
        print("❌ Verification failed: \(verificationError)")
        return nil
    case .verified(let safe):
        return safe
    }
}
```

**2. For development:**
- Use simulator or non-jailbroken device
- Ensure .storekit file is configured

**3. Check device time:**
- Settings → General → Date & Time
- Enable "Set Automatically"

---

## Sandbox Testing Issues

### ❌ "Cannot connect to sandbox"

**Symptoms:**
- Purchases fail immediately
- Error: "Cannot connect to App Store"

**Causes:**
1. Not signed in to sandbox account
2. Using production Apple ID instead
3. Network connectivity

**Solutions:**

**1. Sign in to sandbox:**
```
iOS Device:
Settings → App Store → Sandbox Account → Sign In

Note: Do NOT sign in with production Apple ID in sandbox section!
```

**2. Sign out of production App Store:**
- Settings → [Your Name] → Media & Purchases → Sign Out
- This prevents conflicts

**3. Clear sandbox cache:**
```
1. Sign out of sandbox account
2. Restart device
3. Sign back in to sandbox account
4. Test purchase
```

---

### ❌ "Sandbox purchases showing in production"

**Symptoms:**
- Test purchases appear in real Apple ID
- Charged real money

**Causes:**
- **CRITICAL:** Signed in with production Apple ID during testing

**Solutions:**

**Prevention:**
1. **NEVER use production Apple ID for testing**
2. **Always use sandbox test accounts**
3. **Check before every test:**
   - Settings → App Store → Sandbox Account (should show test email)

**If already charged:**
1. **Request refund:**
   - reportaproblem.apple.com
   - Select purchase → Request refund
2. **Verify sandbox setup:**
   - Create new sandbox accounts
   - Document test procedures

---

### ❌ "Subscription renews every 5 minutes"

**Symptoms:**
- Monthly subscription renews constantly
- Rapid renewal notifications

**Cause:**
- **This is normal for sandbox!** Apple accelerates renewals for testing

**Sandbox renewal schedule:**
- 3 days = 2 minutes
- 1 week = 3 minutes
- 1 month = 5 minutes
- 2 months = 10 minutes
- 3 months = 15 minutes
- 6 months = 30 minutes
- 1 year = 1 hour

**No action needed** - this is expected behavior.

---

## Subscription Validation Issues

### ❌ "Lifetime purchase shows as expired"

**Symptoms:**
- User purchases lifetime
- App shows "Premium expired"

**Causes:**
- Incorrect `hasActiveSubscription` logic
- Expiry date set for non-consumable

**Solutions:**

**1. Verify SubscriptionPlan enum:**
```swift
// In SubscriptionPlan.swift
public enum SubscriptionPlan: String, Codable, CaseIterable {
    case free
    case monthly
    case annual
    case lifetime  // ✅ Must exist
}
```

**2. Check UserProfile logic:**
```swift
// In UserProfile.swift
public var hasActiveSubscription: Bool {
    switch subscriptionPlan {
    case .free:
        return false
    case .monthly, .annual:
        guard let expiryDate = subscriptionExpiryDate else { return false }
        return expiryDate > Date()
    case .lifetime:
        return true  // ✅ Never expires
    }
}
```

**3. Verify purchase mapping:**
```swift
// In StoreKitConstants.swift
public static func subscriptionPlan(for productID: String) -> SubscriptionPlan {
    switch productID {
    case monthly: return .monthly
    case annual: return .annual
    case lifetime: return .lifetime  // ✅ Not .monthly!
    default: return .free
    }
}
```

---

### ❌ "Premium features not unlocking"

**Symptoms:**
- Purchase succeeds
- Features still locked

**Causes:**
1. Subscription service not updated
2. Feature gating using wrong service
3. Cache not refreshed

**Solutions:**

**1. Check subscription service update:**
```swift
// In StoreKitPaywallService.purchase()
case .success(let verification):
    let transaction = try checkVerified(verification)

    // ✅ This must be called
    try await subscriptionService.mockPurchase(transaction.productID)

    await transaction.finish()
    purchaseState = .success(product)
    return true
```

**2. Verify feature gating:**
```swift
// Should use subscription service
@Injected(\.secureSubscriptionService) var subscriptionService

var isPremiumUser: Bool {
    #if ALL_FEATURES_ENABLED
    return true
    #else
    return subscriptionService.isPremiumUser()
    #endif
}
```

**3. Force cache refresh:**
- Close and reopen app
- Or call `restorePurchases()`

---

## Build & Compilation Issues

### ❌ "StoreKitPaywallService() missing parameter"

**Symptoms:**
```
error: missing argument for parameter 'subscriptionService' in call
```

**Cause:**
- Forgot to pass `subscriptionService` to initializer

**Solution:**
```swift
// In Container+Services.swift
var paywallService: Factory<PaywallService> {
    self {
        #if DEBUG
        // ... mock code
        #else
        return MainActor.assumeIsolated {
            StoreKitPaywallService(
                subscriptionService: self.secureSubscriptionService()  // ✅ Required
            )
        }
        #endif
    }
    .singleton
}
```

---

### ❌ "'Product' is ambiguous for type lookup"

**Symptoms:**
```
error: 'Product' is ambiguous for type lookup in this context
```

**Cause:**
- Conflict between `StoreKit.Product` and `RitualistCore.Product`

**Solution:**
```swift
// Use fully qualified type names
public func loadProducts() async throws -> [RitualistCore.Product] {
    storeProducts = try await StoreKit.Product.products(...)

    let products = storeProducts.compactMap { storeProduct -> RitualistCore.Product? in
        mapStoreProduct(storeProduct)
    }
    // ...
}
```

---

### ❌ "Build fails with Ritualist-Subscription scheme"

**Symptoms:**
- AllFeatures builds fine
- Subscription scheme fails

**Cause:**
- Missing mock fallbacks in DI container

**Solution:**
```swift
// In Container+Services.swift - Always use mocks until ready
var secureSubscriptionService: Factory<SecureSubscriptionService> {
    self {
        // Default to mock (safe for all schemes)
        return RitualistCore.MockSecureSubscriptionService(errorHandler: self.errorHandler())

        // Uncomment when ready:
        // return StoreKitSubscriptionService(errorHandler: self.errorHandler())
    }
    .singleton
}
```

---

## Production Issues

### ❌ "Purchases work in TestFlight but not App Store"

**Symptoms:**
- TestFlight users can purchase
- App Store users get errors

**Causes:**
1. Products not approved
2. App review pending
3. Agreements not signed

**Solutions:**
1. **Check product status:**
   - App Store Connect → In-App Purchases
   - All products must be "Ready for Sale"
2. **Verify app review:**
   - IAPs must be reviewed with app submission
3. **Check agreements:**
   - Paid Applications Agreement signed
   - Banking info complete

---

### ❌ "Restore purchases finds nothing"

**Symptoms:**
- User has valid purchase
- Restore finds no purchases

**Causes:**
1. Different Apple ID
2. Purchase was refunded
3. Family Sharing not configured

**Solutions:**
1. **Verify Apple ID:**
   - User must use same Apple ID as purchase
2. **Check purchase history:**
   - Settings → Apple ID → Subscriptions
   - Verify subscription exists
3. **Check refunds:**
   - App Store Connect → Sales and Trends
   - Look for refunded transactions

---

## Getting Help

### Enable Debug Logging

Add to both StoreKit services temporarily:

```swift
// In StoreKitPaywallService.swift
public func loadProducts() async throws -> [RitualistCore.Product] {
    print("🛍️ [StoreKit] Loading products...")
    // ... existing code
}

public func purchase(_ product: RitualistCore.Product) async throws -> Bool {
    print("🛍️ [StoreKit] Starting purchase for: \(product.id)")
    // ... existing code
}

// In StoreKitSubscriptionService.swift
private func refreshCache(force: Bool) async {
    print("🔐 [Subscription] Refreshing cache (force: \(force))...")
    // ... existing code
}
```

### Collect Diagnostic Info

Before reporting issues:
1. **Device info:**
   - iOS version
   - Device model
   - Scheme used (AllFeatures vs Subscription)
2. **Build info:**
   - Xcode version
   - Build configuration (Debug/Release)
3. **StoreKit config:**
   - Using .storekit file? (Yes/No)
   - Sandbox or Production?
4. **Error details:**
   - Exact error message
   - Console logs (with debug logging enabled)
   - Steps to reproduce

### Support Resources

- **Apple Documentation:** [StoreKit 2 Guide](https://developer.apple.com/documentation/storekit)
- **Setup Guide:** [STOREKIT-SETUP-GUIDE.md](STOREKIT-SETUP-GUIDE.md)
- **Migration Guide:** [REVENUECAT-MIGRATION.md](REVENUECAT-MIGRATION.md)
- **App Store Connect:** [appstoreconnect.apple.com](https://appstoreconnect.apple.com)

---

## Common Patterns

### Safe Testing Pattern

```swift
// 1. Always use sandbox accounts
// 2. Test each product individually
// 3. Verify in this order:
//    a. Purchase works
//    b. Features unlock
//    c. Restore works
//    d. Expiry detects correctly (wait 5 min for monthly)

// Example test checklist:
// ✅ Monthly: Purchase → Features unlock → Restore
// ✅ Annual: Purchase → Trial active → Features unlock → Restore
// ✅ Lifetime: Purchase → Features unlock → No expiry → Restore
```

### Safe Production Deployment

```swift
// 1. TestFlight first (AllFeatures scheme)
// 2. Monitor analytics for 1-2 weeks
// 3. App Store (Subscription scheme)
// 4. Gradual rollout via phased release
// 5. Monitor conversion metrics
```

---

## Quick Reference

| Issue | Quick Fix |
|-------|-----------|
| Products not loading | Check .storekit config, verify IDs match |
| Purchase fails | Verify sandbox account signed in |
| Transaction verification fails | Use non-jailbroken device, check .storekit |
| Lifetime shows expired | Verify `SubscriptionPlan.lifetime` case exists |
| Build fails | Check mock fallbacks in `Container+Services.swift` |
| Restore finds nothing | Verify same Apple ID, check refund status |

---

**Last Updated:** January 2025
**Version:** 1.0.0
