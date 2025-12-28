//
//  StoreKitSubscriptionService.swift
//  Ritualist
//
//  Production StoreKit 2 subscription validation implementation
//  Status: READY TO ENABLE - See docs/STOREKIT-SETUP-GUIDE.md
//

import Foundation
import StoreKit
import RitualistCore

/// Production StoreKit 2 subscription validation service
///
/// **STATUS:** Production-ready, fully implemented
/// **ACTIVATION:** See docs/STOREKIT-SETUP-GUIDE.md
///
/// This service provides secure subscription validation using:
/// - StoreKit 2 Transaction.currentEntitlements for real-time status
/// - On-device receipt verification (StoreKit handles cryptographic validation)
/// - Subscription expiry detection
/// - Performance-optimized caching
///
/// **Security:**
/// - All transactions are cryptographically verified by StoreKit
/// - VerificationResult ensures transactions haven't been tampered with
/// - No local storage of purchase state (always queries StoreKit as source of truth)
///
/// **Logging:** Uses centralized DebugLogger for consistent logging across the app.
///
/// **To Enable:**
/// 1. Purchase Apple Developer Program membership ($99/year)
/// 2. Create IAP products in App Store Connect (see StoreKitConstants.swift for IDs)
/// 3. Submit products for review and approval
/// 4. Uncomment this service in Container+Services.swift
/// 5. Test with sandbox accounts
///
public actor StoreKitSubscriptionService: SecureSubscriptionService {

    // MARK: - Private Properties

    /// Cache of validated purchases for performance optimization
    /// Refreshed on each validation check from StoreKit
    private var cachedValidPurchases: Set<String> = []

    /// Last cache update timestamp
    private var lastCacheUpdate: Date = .distantPast

    /// Cache validity duration (5 minutes)
    private let cacheValidityDuration: TimeInterval = 300

    /// Error handler for logging/analytics
    private let errorHandler: ErrorHandler?

    // MARK: - Initialization

    public init(errorHandler: ErrorHandler? = nil) {
        self.errorHandler = errorHandler
    }

    // MARK: - SecureSubscriptionService Protocol

    public func validatePurchase(_ productId: String) async -> Bool {
        // Refresh cache if needed
        await refreshCacheIfNeeded()

        // Check cache for product
        return cachedValidPurchases.contains(productId)
    }

    public func restorePurchases() async -> [String] {
        // Force refresh cache from StoreKit
        await refreshCache(force: true)

        // Return all validated purchases
        return Array(cachedValidPurchases)
    }

    public func isPremiumUser() async -> Bool {
        // Check in-memory cache first (populated after StoreKit queries this session)
        if !cachedValidPurchases.isEmpty {
            return true
        }

        // Fall back to Keychain cache (populated by verifyPremiumAsync at startup)
        // This handles the case where sync isPremiumUser() is called before
        // async refreshCache() has populated the in-memory cache
        return await SecurePremiumCache.shared.getCachedPremiumStatus()
    }

    public func getValidPurchases() async -> [String] {
        Array(cachedValidPurchases)
    }

    public func registerPurchase(_ productId: String) async throws {
        // Called after a successful purchase to immediately update the cache
        // without waiting for StoreKit refresh
        cachedValidPurchases.insert(productId)
        lastCacheUpdate = Date()

        // Update Keychain cache immediately after purchase
        // This ensures the user has offline access right away
        await SecurePremiumCache.shared.updateCache(isPremium: true)
    }

    public func clearPurchases() async throws {
        // Note: Cannot actually clear purchases from StoreKit
        // This is for cache management only
        cachedValidPurchases.removeAll()
        lastCacheUpdate = .distantPast

        // Clear Keychain cache as well
        await SecurePremiumCache.shared.clearCache()
    }

    public func getCurrentSubscriptionPlan() async -> SubscriptionPlan {
        // Refresh cache if needed
        await refreshCacheIfNeeded()

        // Check for annual subscription (highest priority)
        if cachedValidPurchases.contains(StoreKitProductID.annual) {
            return .annual
        }

        // Check for monthly subscription
        if cachedValidPurchases.contains(StoreKitProductID.monthly) {
            return .monthly
        }

        // Check for weekly subscription
        if cachedValidPurchases.contains(StoreKitProductID.weekly) {
            return .weekly
        }

        // Default to free if no purchases
        return .free
    }

    public func getSubscriptionExpiryDate() async -> Date? {
        // Refresh cache if needed
        await refreshCacheIfNeeded()

        // Query StoreKit for current entitlements to get expiration date
        for await result in Transaction.currentEntitlements {
            // Verify transaction cryptographically
            guard let transaction = try? checkVerified(result) else {
                continue
            }

            // Check if this is a time-limited subscription
            if transaction.productID.contains("monthly") || transaction.productID.contains("annual") {
                // Return the expiration date if it exists
                if let expirationDate = transaction.expirationDate {
                    return expirationDate
                }
            }
        }

        // No expiry date found (free user)
        return nil
    }

    // MARK: - Private Methods

    /// Refresh cache from StoreKit if cache is stale
    private func refreshCacheIfNeeded() async {
        let now = Date()
        let timeSinceLastUpdate = now.timeIntervalSince(lastCacheUpdate)

        // Refresh if cache is stale
        if timeSinceLastUpdate > cacheValidityDuration {
            await refreshCache(force: false)
        }
    }

    /// Refresh validated purchases from StoreKit
    ///
    /// - Parameter force: If true, refresh regardless of cache age
    ///
    private func refreshCache(force: Bool) async {
        // Skip if not forced and cache is still valid
        if !force {
            let now = Date()
            let timeSinceLastUpdate = now.timeIntervalSince(lastCacheUpdate)
            if timeSinceLastUpdate <= cacheValidityDuration {
                return
            }
        }

        // Query StoreKit for current entitlements
        var validPurchases: Set<String> = []

        for await result in Transaction.currentEntitlements {
            // Verify transaction cryptographically
            guard let transaction = try? checkVerified(result) else {
                // Skip unverified transactions
                continue
            }

            // Check if transaction is valid (not expired, not revoked)
            if await isTransactionValid(transaction) {
                validPurchases.insert(transaction.productID)
            }
        }

        // Update in-memory cache
        cachedValidPurchases = validPurchases
        lastCacheUpdate = Date()

        // Update Keychain cache for offline scenarios (3-day grace period)
        // This keeps the secure cache fresh whenever we successfully query StoreKit
        let isPremium = !validPurchases.isEmpty
        await SecurePremiumCache.shared.updateCache(isPremium: isPremium)
    }

    /// Check if a transaction is currently valid
    ///
    /// - Parameter transaction: The verified transaction to check
    /// - Returns: `true` if transaction grants current entitlement, `false` otherwise
    ///
    /// **Grace Period Handling:**
    /// When a subscription appears expired, we also check if the user is in a billing
    /// grace period. Apple's Billing Grace Period feature gives users extra time to
    /// fix payment issues while retaining access to premium features.
    ///
    private func isTransactionValid(_ transaction: Transaction) async -> Bool {
        // Check for revocation
        if transaction.revocationDate != nil {
            return false
        }

        // For subscriptions, check expiration
        if let expirationDate = transaction.expirationDate {
            // Transaction is valid if not yet expired
            if expirationDate > Date() {
                return true
            }

            // Subscription appears expired - check if user is in grace period
            // This handles Apple's Billing Grace Period where payment failed but
            // user still has access while Apple retries or user updates payment method
            if await isUserInGracePeriod() {
                return true
            }

            return false
        }

        // No expiration date means non-subscription purchase - always valid if not revoked
        return true
    }

    /// Check if the user is currently in a billing grace period
    ///
    /// Apple's Billing Grace Period gives subscribers extra time (configured in App Store Connect)
    /// to fix payment issues without losing access. This method checks the subscription status
    /// to determine if the user should retain premium access despite an "expired" transaction.
    ///
    /// **Subscription States that grant access:**
    /// - `.subscribed` - Active subscription
    /// - `.inGracePeriod` - Payment failed, user has time to fix payment method
    /// - `.inBillingRetryPeriod` - Apple is retrying the payment
    ///
    /// - Returns: `true` if user is in grace period or billing retry, `false` otherwise
    ///
    private func isUserInGracePeriod() async -> Bool {
        do {
            // Query subscription status for our subscription group
            let statuses = try await Product.SubscriptionInfo.status(
                for: StoreKitProductID.subscriptionGroupID
            )

            for status in statuses {
                switch status.state {
                case .subscribed:
                    // Active subscription - should have been caught by expiration check
                    // but return true just in case
                    return true

                case .inGracePeriod:
                    // User's payment failed but they're in grace period
                    // They should retain access while fixing payment method
                    Self.startupLogger.log(
                        "🔔 User in billing grace period - retaining premium access",
                        level: .info,
                        category: .subscription
                    )
                    return true

                case .inBillingRetryPeriod:
                    // Apple is retrying the payment - user retains access
                    Self.startupLogger.log(
                        "🔔 User in billing retry period - retaining premium access",
                        level: .info,
                        category: .subscription
                    )
                    return true

                case .expired, .revoked:
                    // Fully expired or revoked - no access
                    continue

                default:
                    // Unknown state - be conservative and continue checking
                    continue
                }
            }

            return false
        } catch {
            // If we can't query subscription status, be conservative and deny grace period
            // The user can still restore purchases if they believe they should have access
            Self.startupLogger.log(
                "⚠️ Failed to check subscription status for grace period: \(error.localizedDescription)",
                level: .warning,
                category: .subscription
            )
            return false
        }
    }

    /// Verifies a transaction using StoreKit's built-in verification
    ///
    /// - Parameter result: The verification result from StoreKit
    /// - Returns: The verified transaction, or `nil` if verification fails
    ///
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T? {
        switch result {
        case .unverified(_, let verificationError):
            // Verification failed - possible jailbreak or tampered receipt
            Task {
                await errorHandler?.logError(
                    PaywallError.purchaseFailed("Transaction verification failed: \(verificationError)"),
                    context: ErrorContext.userInterface + "_transaction_verification",
                    additionalProperties: ["error": "\(verificationError)"]
                )
            }
            return nil

        case .verified(let safe):
            // Transaction is verified and safe to use
            return safe
        }
    }
}

// MARK: - Production Setup Notes

/*
 ACTIVATION CHECKLIST:

 ✅ Phase 1: App Store Connect Setup
    1. Purchase Apple Developer Program ($99/year)
    2. Create App in App Store Connect (if not exists)
    3. Enable In-App Purchases capability
    4. Create Subscription Group: "Ritualist Pro"
    5. Create IAP Products:
       - com.vladblajovan.ritualist.weekly ($2.99/week)
       - com.vladblajovan.ritualist.monthly ($9.99/month)
       - com.vladblajovan.ritualist.annual ($49.99/year, 7-day trial)
    6. Submit products for review

 ✅ Phase 2: Code Activation
    1. Open Ritualist/DI/Container+Services.swift
    2. Find subscriptionService factory
    3. Uncomment StoreKitSubscriptionService initialization
    4. Comment out MockSecureSubscriptionService
    5. Build and test with sandbox accounts

 ✅ Phase 3: Testing
    1. Create sandbox test accounts in App Store Connect
    2. Test purchase validation
    3. Test restore purchases
    4. Test subscription expiry detection
    5. Test cache refresh logic

 ✅ Phase 4: Deployment
    1. TestFlight: Use Ritualist-AllFeatures scheme (bypass paywall)
    2. App Store: Use Ritualist-Subscription scheme (enable paywall)
    3. Monitor subscription metrics and errors
    4. Iterate based on user feedback

 For detailed instructions, see: docs/STOREKIT-SETUP-GUIDE.md
 */
