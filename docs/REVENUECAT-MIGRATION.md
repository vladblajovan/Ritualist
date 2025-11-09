# RevenueCat Migration Strategy

**Status:** Future Enhancement (Post-Launch)
**Last Updated:** January 2025

This document outlines the strategy for migrating from native StoreKit 2 to RevenueCat for enhanced subscription management.

---

## Why RevenueCat?

### Current Setup (StoreKit 2 Native)

**Pros:**
- ✅ Zero ongoing costs ($0/month)
- ✅ No external dependencies
- ✅ Full control over code
- ✅ Apple's official framework
- ✅ Built-in cryptographic verification
- ✅ Low complexity

**Cons:**
- ❌ iOS-only (no Android/web support)
- ❌ Limited analytics (basic metrics only)
- ❌ No server-side webhooks
- ❌ Manual implementation of promo codes
- ❌ No cross-platform user tracking
- ❌ Limited A/B testing capabilities

### Future Setup (RevenueCat)

**Pros:**
- ✅ Cross-platform (iOS, Android, Web)
- ✅ Advanced analytics dashboard
- ✅ Server-side webhooks for automation
- ✅ Built-in promo code management
- ✅ Experiments & A/B testing
- ✅ Customer support tools
- ✅ Integration with analytics platforms
- ✅ Subscription status webhooks

**Cons:**
- ❌ Monthly cost (Free tier: 10k tracked revenue, then $0.01/subscription/month)
- ❌ External dependency
- ❌ Additional API layer
- ❌ More complexity

---

## When to Migrate

### ✅ Migrate When:

1. **Cross-platform expansion:**
   - Planning Android version
   - Building web app with subscriptions
   - Need unified user accounts

2. **Revenue scales:**
   - $10k+/month in subscription revenue
   - Need detailed cohort analysis
   - Want to optimize conversion funnels

3. **Advanced features needed:**
   - A/B testing different paywalls
   - Promotional offers and campaigns
   - Webhooks for automation
   - Integration with marketing tools

4. **Customer support load:**
   - Manually managing refunds is time-consuming
   - Need subscription status API for support
   - Want self-service customer portal

### ❌ Don't Migrate If:

1. **Early stage:**
   - Just launched, < 100 paying users
   - Still validating product-market fit
   - Revenue < $1k/month

2. **iOS-only forever:**
   - No plans for Android/web
   - Happy with Apple's ecosystem

3. **Simple needs:**
   - Basic subscription model works
   - Don't need advanced analytics
   - Manual processes acceptable

---

## Migration Strategy

### Phase 1: Preparation (Week 1)

#### 1.1 RevenueCat Account Setup

1. **Sign up:**
   - Create account at [revenuecat.com](https://www.revenuecat.com)
   - Start with free tier
2. **Configure project:**
   - Add iOS app
   - Upload App Store Connect API key
   - Configure products (copy from StoreKitConstants.swift)

#### 1.2 Install SDK

```swift
// In Package.swift or Podfile
dependencies: [
    .package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "4.0.0")
]
```

#### 1.3 Create New Service

**Create:** `Ritualist/Core/Services/RevenueCatPaywallService.swift`

```swift
import RevenueCat
import RitualistCore

public final class RevenueCatPaywallService: PaywallService {
    private let errorHandler: ErrorHandler?

    public init(errorHandler: ErrorHandler? = nil) {
        self.errorHandler = errorHandler

        // Configure RevenueCat
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "your_api_key_here")
    }

    public func loadProducts() async throws -> [Product] {
        // Implementation using RevenueCat SDK
    }

    // ... rest of PaywallService protocol
}
```

---

### Phase 2: Parallel Implementation (Week 2-3)

#### 2.1 Dual Service Architecture

Run both services side-by-side for validation:

```swift
// In Container+Services.swift
var paywallService: Factory<PaywallService> {
    self {
        #if REVENUECAT_ENABLED
        return RevenueCatPaywallService(errorHandler: self.errorHandler())
        #else
        return MainActor.assumeIsolated {
            StoreKitPaywallService(subscriptionService: self.secureSubscriptionService())
        }
        #endif
    }
    .singleton
}

// Also keep StoreKit service for comparison
var storeKitPaywallService: Factory<PaywallService> {
    self {
        return MainActor.assumeIsolated {
            StoreKitPaywallService(subscriptionService: self.secureSubscriptionService())
        }
    }
    .singleton
}
```

#### 2.2 Feature Flag Migration

```swift
// In BuildConfigurationService.swift
public var isRevenueCatEnabled: Bool {
    #if REVENUECAT_ENABLED
    return true
    #else
    return false
    #endif
}
```

---

### Phase 3: Migration Testing (Week 3-4)

#### 3.1 Test Checklist

**Purchases:**
- ✅ Monthly subscription
- ✅ Annual subscription (with trial)
- ✅ Lifetime purchase
- ✅ Restore purchases
- ✅ Subscription renewals
- ✅ Subscription cancellations
- ✅ Refunds

**Validation:**
- ✅ Receipt validation matches StoreKit
- ✅ Expiry detection works
- ✅ Lifetime purchase never expires
- ✅ Cross-device restore works

**Analytics:**
- ✅ Events tracked correctly
- ✅ Revenue matches App Store Connect
- ✅ Cohort analysis accurate

#### 3.2 TestFlight Beta

1. **Deploy with REVENUECAT_ENABLED flag**
2. **Monitor for 1-2 weeks:**
   - Purchase success rate
   - Validation accuracy
   - Error rates
3. **Compare metrics:**
   - RevenueCat dashboard vs App Store Connect
   - Should match within 1-2%

---

### Phase 4: Production Rollout (Week 4-5)

#### 4.1 Gradual Rollout

**Week 1: 10% of users**
```swift
// In feature flag service
var isRevenueCatEnabled: Bool {
    #if REVENUECAT_ENABLED
    // Enable for 10% of users
    let userId = currentUser.id.uuidString
    let hash = abs(userId.hashValue)
    return hash % 100 < 10
    #else
    return false
    #endif
}
```

**Week 2: 50% of users**
```swift
return hash % 100 < 50
```

**Week 3: 100% of users**
```swift
return true
```

#### 4.2 Monitoring

**Key Metrics:**
- Purchase success rate (should be ≥99%)
- Validation error rate (should be <0.1%)
- API latency (should be <500ms)
- Customer support tickets (watch for increase)

**Rollback Criteria:**
- Purchase success rate drops >5%
- Validation errors >1%
- Customer complaints increase >10%

---

### Phase 5: Cleanup (Week 6)

#### 5.1 Remove StoreKit Services (Optional)

Once RevenueCat is stable for 30+ days:

```swift
// Keep StoreKit services as backup, but deprecate
@available(*, deprecated, message: "Use RevenueCatPaywallService instead")
public final class StoreKitPaywallService: PaywallService {
    // ... keep code for emergency rollback
}
```

#### 5.2 Update Documentation

- Update STOREKIT-SETUP-GUIDE.md → REVENUECAT-SETUP-GUIDE.md
- Archive StoreKit implementation notes
- Document rollback procedure

---

## Migration Compatibility

### User Data Migration

**Good news:** No user data migration needed!

- RevenueCat syncs with App Store Connect automatically
- Existing purchases recognized via Apple ID
- Subscription status imported from receipts
- No data loss or manual migration

### Code Compatibility

**PaywallService Protocol:**
```swift
// Existing protocol works with both implementations
public protocol PaywallService {
    func loadProducts() async throws -> [Product]
    func purchase(_ product: Product) async throws -> Bool
    func restorePurchases() async throws -> Bool
    // ... etc
}

// StoreKit implementation
class StoreKitPaywallService: PaywallService { }

// RevenueCat implementation (same interface!)
class RevenueCatPaywallService: PaywallService { }
```

**Zero UI Changes Required:**
- Views use `PaywallService` protocol
- Swap implementation in DI container only
- No paywall UI changes needed

---

## Cost Analysis

### Pricing Tiers

**Free Tier:**
- Up to $10k tracked monthly revenue
- Unlimited users
- All core features
- **Best for:** Early stage (< 100 paying users)

**Starter ($125/month):**
- Up to $100k tracked monthly revenue
- RevenueCat Billing (optional)
- Priority support
- **Best for:** Growing apps (100-500 paying users)

**Pro ($250+/month):**
- Up to $500k tracked monthly revenue
- Advanced integrations
- Scheduled data exports
- **Best for:** Established apps (500+ paying users)

### ROI Calculation

**Break-even analysis:**

Assume:
- Monthly subscription: $9.99
- Annual subscription: $49.99 (most popular)
- Average revenue per user (ARPU): ~$40/year

**Free tier ($0/month):**
- Up to $10k/month = $120k/year
- ~3,000 annual subscribers
- **Free until you hit scale**

**Starter tier ($125/month = $1,500/year):**
- Costs $1,500/year
- Need 38 additional paying users to break even
- If RevenueCat improves conversion by 2%, likely worth it

**When to upgrade:**
- Free tier: Use until you hit $10k/month
- Starter tier: When analytics/webhooks add value
- Pro tier: When enterprise features needed

---

## Technical Implementation

### RevenueCat SDK Integration

```swift
// In RevenueCatPaywallService.swift
import RevenueCat

public final class RevenueCatPaywallService: PaywallService {

    public init(errorHandler: ErrorHandler? = nil) {
        self.errorHandler = errorHandler

        // Configure RevenueCat
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: RevenueCatConfig.apiKey)
    }

    public func loadProducts() async throws -> [RitualistCore.Product] {
        do {
            // Load offerings from RevenueCat
            let offerings = try await Purchases.shared.offerings()

            guard let currentOffering = offerings.current else {
                throw PaywallError.productsNotAvailable
            }

            // Map RevenueCat packages to domain products
            let products = currentOffering.availablePackages.compactMap { package in
                mapRevenueCatPackage(package)
            }

            return products.sorted { $0.isPopular && !$1.isPopular }

        } catch {
            throw PaywallError.productsNotAvailable
        }
    }

    public func purchase(_ product: RitualistCore.Product) async throws -> Bool {
        do {
            let result = try await Purchases.shared.purchase(package: findPackage(for: product))

            if result.customerInfo.entitlements["pro"]?.isActive == true {
                // Update subscription service
                try await subscriptionService.mockPurchase(product.id)
                return true
            }

            return false

        } catch let error as RevenueCat.ErrorCode {
            if error == .purchaseCancelledError {
                throw PaywallError.userCancelled
            }
            throw PaywallError.purchaseFailed(error.localizedDescription)
        }
    }

    public func restorePurchases() async throws -> Bool {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()

            if customerInfo.entitlements["pro"]?.isActive == true {
                return true
            }

            return false

        } catch {
            throw PaywallError.noPurchasesToRestore
        }
    }

    // ... rest of implementation
}
```

### Webhook Integration (Optional)

```swift
// Server-side webhook handler (Node.js example)
app.post('/webhooks/revenuecat', async (req, res) => {
    const event = req.body

    switch (event.type) {
        case 'INITIAL_PURCHASE':
            // New subscription
            await sendWelcomeEmail(event.app_user_id)
            break

        case 'RENEWAL':
            // Subscription renewed
            await logRevenue(event)
            break

        case 'CANCELLATION':
            // Subscription cancelled
            await sendWinbackEmail(event.app_user_id)
            break

        case 'EXPIRATION':
            // Subscription expired
            await downgradeUser(event.app_user_id)
            break
    }

    res.sendStatus(200)
})
```

---

## Rollback Plan

### Emergency Rollback (Same Day)

**If critical issues occur:**

1. **Revert DI container:**
```swift
var paywallService: Factory<PaywallService> {
    self {
        // Immediately switch back to StoreKit
        return MainActor.assumeIsolated {
            StoreKitPaywallService(subscriptionService: self.secureSubscriptionService())
        }
    }
    .singleton
}
```

2. **Deploy hotfix:**
   - Build with REVENUECAT_ENABLED flag removed
   - Upload to App Store Connect
   - Request expedited review (if critical)

3. **Monitor recovery:**
   - Purchase success rate returns to normal
   - Customer support tickets decrease

**Rollback time:** 1-2 hours for build + 24-48 hours for review

---

## Long-term Strategy

### Hybrid Approach (Recommended)

**Use both services strategically:**

```swift
// iOS: Native StoreKit (simpler, cheaper)
#if os(iOS)
return StoreKitPaywallService(...)
#endif

// Android: RevenueCat (cross-platform)
#if os(Android)
return RevenueCatPaywallService(...)
#endif

// Web: RevenueCat (webhooks needed)
#if PLATFORM_WEB
return RevenueCatPaywallService(...)
#endif
```

**Benefits:**
- iOS users: Fast, native experience
- Android/Web: RevenueCat handles complexity
- Lower costs (iOS doesn't count toward RevenueCat limits)

---

## Decision Matrix

| Factor | StoreKit Native | RevenueCat |
|--------|-----------------|------------|
| **Cost** | $0/month | $0-250+/month |
| **Complexity** | Medium | Low (SDK handles it) |
| **Analytics** | Basic | Advanced |
| **Cross-platform** | iOS only | iOS, Android, Web |
| **Webhooks** | No | Yes |
| **A/B Testing** | Manual | Built-in |
| **Time to implement** | 2-3 weeks | 1-2 weeks |
| **Maintenance** | Higher | Lower |

---

## Recommended Timeline

### Immediate (Months 1-3):
- ✅ Launch with native StoreKit
- ✅ Validate product-market fit
- ✅ Optimize pricing manually

### Short-term (Months 3-6):
- 📊 Analyze growth and needs
- 🔍 Evaluate if cross-platform needed
- 💰 Check if hitting free tier limit

### Long-term (Months 6-12):
- 🚀 Migrate to RevenueCat if:
  - Revenue > $10k/month
  - Need advanced analytics
  - Planning Android/web
- 🎯 Or stay with StoreKit if:
  - iOS-only app
  - Happy with App Store Connect analytics
  - Want to minimize costs

---

## Support Resources

- **RevenueCat Documentation:** [docs.revenuecat.com](https://docs.revenuecat.com)
- **Migration Guide:** [docs.revenuecat.com/docs/migrating-to-revenuecat](https://docs.revenuecat.com/docs/migrating-to-revenuecat)
- **Slack Community:** [revenuecat-users.slack.com](https://revenuecat-users.slack.com)
- **StoreKit Guide:** [STOREKIT-SETUP-GUIDE.md](STOREKIT-SETUP-GUIDE.md)

---

## Conclusion

**Recommendation:** Start with native StoreKit, migrate to RevenueCat when:
1. Revenue > $10k/month
2. Need cross-platform support
3. Want advanced analytics/webhooks

**Timeline:** 3-12 months post-launch (monitor metrics)

**Risk:** Low (easy rollback, proven migration path)

---

**Last Updated:** January 2025
**Version:** 1.0.0
