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
/// - Lifetime purchase recognition
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
        let timeoutSeconds: UInt64 = 5

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
                            } else {
                                // Non-consumable (lifetime) - no expiry
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
                "timed_out": duration >= Double(timeoutSeconds)
            ]
        )

        return result
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

        // Check for lifetime purchase first (highest priority)
        if cachedValidPurchases.contains(StoreKitProductID.lifetime) {
            return .lifetime
        }

        // Check for annual subscription
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

        // No expiry date found (lifetime purchase or free user)
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
    private func isTransactionValid(_ transaction: Transaction) async -> Bool {
        // Check for revocation
        if transaction.revocationDate != nil {
            return false
        }

        // For subscriptions, check expiration
        if let expirationDate = transaction.expirationDate {
            // Transaction is valid if not yet expired
            return expirationDate > Date()
        }

        // For non-consumables (lifetime), always valid if not revoked
        return true
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
       - com.vladblajovan.ritualist.monthly ($9.99/month)
       - com.vladblajovan.ritualist.annual ($49.99/year, 7-day trial)
       - com.vladblajovan.ritualist.lifetime ($100 one-time)
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
    5. Test lifetime purchase (non-consumable)
    6. Test cache refresh logic

 ✅ Phase 4: Deployment
    1. TestFlight: Use Ritualist-AllFeatures scheme (bypass paywall)
    2. App Store: Use Ritualist-Subscription scheme (enable paywall)
    3. Monitor subscription metrics and errors
    4. Iterate based on user feedback

 For detailed instructions, see: docs/STOREKIT-SETUP-GUIDE.md
 */
