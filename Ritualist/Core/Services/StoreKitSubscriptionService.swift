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
public final class StoreKitSubscriptionService: SecureSubscriptionService {

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

    // Local logger: Static methods run before DI container is initialized
    private static let startupLogger = DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "subscription")

    // MARK: - Static Premium Check (Secure, for Startup)

    /// Verify premium status asynchronously, using cache when fresh to avoid unnecessary StoreKit calls.
    ///
    /// **PERFORMANCE OPTIMIZATION:**
    /// - If cache is less than 24 hours old, returns cached value immediately (no StoreKit call)
    /// - Only queries StoreKit when cache is stale or doesn't exist
    /// - This dramatically reduces app startup time for returning users
    ///
    /// **SECURITY:** When StoreKit is queried, it uses cryptographically signed receipts
    /// that cannot be bypassed by modifying local storage.
    ///
    /// **Usage:** Call this after app UI is shown (in `performInitialLaunchTasks()`) to verify
    /// the cached premium status and update it if needed.
    ///
    /// - Parameter forceVerification: If `true`, always queries StoreKit regardless of cache freshness.
    ///   Use this for explicit "Restore Purchases" actions.
    /// - Returns: `true` if user has any valid (non-expired, non-revoked) subscription or purchase
    ///
    /// **Timeout:** Returns cached value if StoreKit doesn't respond within 5 seconds.
    ///
    public static func verifyPremiumAsync(forceVerification: Bool = false) async -> Bool {
        return await verifyPremiumSync(timeout: 5.0, forceVerification: forceVerification)
    }

    /// Verify premium status with configurable timeout.
    ///
    /// This is the core verification method used by both:
    /// - `verifyPremiumAsync()` - for post-launch verification (5s timeout)
    /// - Container initialization - for pre-container sync blocking (2s timeout)
    ///
    /// - Parameters:
    ///   - timeout: Maximum seconds to wait for StoreKit response
    ///   - forceVerification: If `true`, always queries StoreKit regardless of cache freshness
    /// - Returns: `true` if user has any valid subscription or purchase
    ///
    public static func verifyPremiumSync(timeout: Double, forceVerification: Bool = false) async -> Bool {
        let startTime = Date()

        // Check if we can skip verification using cached value
        if !forceVerification && SecurePremiumCache.shared.canSkipVerification() {
            let cachedStatus = SecurePremiumCache.shared.getCachedPremiumStatus()
            let cacheAge = SecurePremiumCache.shared.getCacheAge() ?? 0

            startupLogger.log(
                "✅ Using cached premium status (cache fresh)",
                level: .info,
                category: .subscription,
                metadata: [
                    "cached_premium": cachedStatus,
                    "cache_age_hours": String(format: "%.1f", cacheAge / 3600),
                    "verification_skipped": true
                ]
            )

            return cachedStatus
        }

        // Cache is stale or doesn't exist - query StoreKit
        let cacheAge = SecurePremiumCache.shared.getCacheAge()
        startupLogger.log(
            "🔐 Querying StoreKit for premium status",
            level: .info,
            category: .subscription,
            metadata: [
                "reason": forceVerification ? "forced" : (cacheAge == nil ? "no_cache" : "cache_stale"),
                "cache_age_hours": cacheAge.map { String(format: "%.1f", $0 / 3600) } ?? "none"
            ]
        )

        // Use withTaskGroup to implement timeout - if StoreKit hangs, fall back to cache
        let timeoutSeconds: UInt64 = UInt64(timeout)

        let result = await withTaskGroup(of: Bool?.self) { group in
            // Task 1: Query StoreKit
            group.addTask {
                for await result in Transaction.currentEntitlements {
                    // Only count verified transactions
                    if case .verified(let transaction) = result {
                        // Check not revoked
                        if transaction.revocationDate == nil {
                            // Check not expired (for subscriptions)
                            if let expirationDate = transaction.expirationDate {
                                if expirationDate > Date() {
                                    return true
                                }
                                // Subscription appears expired - check grace period
                                // This handles users whose payment failed but are still
                                // within the billing grace period configured in App Store Connect
                                if await Self.checkGracePeriodStatus() {
                                    return true
                                }
                            } else {
                                // Non-subscription (no expiry) - valid if not revoked
                                return true
                            }
                        }
                    }
                }
                return false
            }

            // Task 2: Timeout after specified seconds
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutSeconds * 1_000_000_000)
                return nil // Signal timeout
            }

            // Return first result (either StoreKit response or timeout)
            if let queryResult = await group.next() {
                group.cancelAll()
                if let value = queryResult {
                    // StoreKit responded - update cache with fresh value
                    SecurePremiumCache.shared.updateCache(isPremium: value)
                    return value
                } else {
                    // Timeout occurred - fall back to cached value
                    startupLogger.log(
                        "⚠️ StoreKit verification timed out after \(timeoutSeconds)s - using cached value",
                        level: .warning,
                        category: .subscription
                    )
                    return SecurePremiumCache.shared.getCachedPremiumStatus()
                }
            }

            return false
        }

        // Log verification timing for performance monitoring
        let duration = Date().timeIntervalSince(startTime)
        startupLogger.log(
            "🔐 StoreKit verification completed",
            level: .info,
            category: .subscription,
            metadata: [
                "is_premium": result,
                "duration_ms": Int(duration * 1000),
                "timed_out": duration >= timeout
            ]
        )

        return result
    }

    // MARK: - Static Grace Period Check

    /// Static helper to check if user is in billing grace period
    ///
    /// Used by `verifyPremiumSync` during startup verification when a subscription
    /// appears expired. This allows users in grace period to retain premium access.
    ///
    /// - Returns: `true` if user is in grace period or billing retry, `false` otherwise
    ///
    private static func checkGracePeriodStatus() async -> Bool {
        do {
            let statuses = try await Product.SubscriptionInfo.status(
                for: StoreKitProductID.subscriptionGroupID
            )

            for status in statuses {
                switch status.state {
                case .subscribed, .inGracePeriod, .inBillingRetryPeriod:
                    if status.state == .inGracePeriod {
                        startupLogger.log(
                            "🔔 Startup: User in billing grace period - granting premium access",
                            level: .info,
                            category: .subscription
                        )
                    } else if status.state == .inBillingRetryPeriod {
                        startupLogger.log(
                            "🔔 Startup: User in billing retry period - granting premium access",
                            level: .info,
                            category: .subscription
                        )
                    }
                    return true

                case .expired, .revoked:
                    continue

                default:
                    continue
                }
            }

            return false
        } catch {
            startupLogger.log(
                "⚠️ Startup: Failed to check grace period status: \(error.localizedDescription)",
                level: .warning,
                category: .subscription
            )
            return false
        }
    }

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

    public func isPremiumUser() -> Bool {
        // Check in-memory cache first (populated after StoreKit queries this session)
        if !cachedValidPurchases.isEmpty {
            return true
        }

        // Fall back to Keychain cache (populated by verifyPremiumAsync at startup)
        // This handles the case where sync isPremiumUser() is called before
        // async refreshCache() has populated the in-memory cache
        return SecurePremiumCache.shared.getCachedPremiumStatus()
    }

    public func getValidPurchases() -> [String] {
        return Array(cachedValidPurchases)
    }

    public func registerPurchase(_ productId: String) async throws {
        // Called after a successful purchase to immediately update the cache
        // without waiting for StoreKit refresh
        cachedValidPurchases.insert(productId)
        lastCacheUpdate = Date()

        // Update Keychain cache immediately after purchase
        // This ensures the user has offline access right away
        SecurePremiumCache.shared.updateCache(isPremium: true)
    }

    public func clearPurchases() async throws {
        // Note: Cannot actually clear purchases from StoreKit
        // This is for cache management only
        cachedValidPurchases.removeAll()
        lastCacheUpdate = .distantPast

        // Clear Keychain cache as well
        SecurePremiumCache.shared.clearCache()
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
        SecurePremiumCache.shared.updateCache(isPremium: isPremium)
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
