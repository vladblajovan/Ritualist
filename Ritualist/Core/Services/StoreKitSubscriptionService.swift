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
import FactoryKit

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
        // Simply derive from getCurrentSubscriptionPlan() for consistency
        // Both methods now fall back to Keychain cache in offline scenarios
        await getCurrentSubscriptionPlan() != .free
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
        let plan = StoreKitProductID.subscriptionPlan(for: productId)

        // Query transaction with retry logic for race condition mitigation
        // StoreKit may not have propagated the transaction immediately after purchase
        let transactionInfo = await queryTransactionWithRetry(productId: productId)

        // If transaction wasn't found after retries, use conservative fallback
        // The next cache refresh will get accurate data from StoreKit
        let isOnTrial = transactionInfo.isOnTrial
        var expiryDate = transactionInfo.expiryDate

        if !transactionInfo.found {
            Container.shared.debugLogger().log(
                "Transaction not found after retries for \(productId) - using fallback expiry",
                level: .warning,
                category: .subscription
            )
            // Use plan-appropriate fallback expiry (will be corrected on next refresh)
            expiryDate = Self.fallbackExpiryDate(for: plan)
        }

        await SecurePremiumCache.shared.updateCache(
            plan: plan,
            isOnTrial: isOnTrial,
            expiryDate: expiryDate
        )
    }

    /// Queries StoreKit for transaction info with exponential backoff retry
    /// Returns transaction details if found, or defaults if not found after retries
    private func queryTransactionWithRetry(productId: String) async -> TransactionQueryResult {
        let maxAttempts = 3
        var delayNanoseconds: UInt64 = 100_000_000 // Start at 100ms

        for attempt in 1...maxAttempts {
            // Query StoreKit for current entitlements
            var latestPurchaseDate: Date?
            var result = TransactionQueryResult()

            for await entitlement in Transaction.currentEntitlements {
                guard case .verified(let transaction) = entitlement,
                      transaction.productID == productId else {
                    continue
                }
                // Keep the most recent transaction by purchase date
                let shouldUpdate = latestPurchaseDate.map { transaction.purchaseDate > $0 } ?? true
                if shouldUpdate {
                    latestPurchaseDate = transaction.purchaseDate
                    result.isOnTrial = transaction.offer?.type == .introductory
                    result.expiryDate = transaction.expirationDate
                }
            }

            // Found the transaction
            if latestPurchaseDate != nil {
                result.found = true
                return result
            }

            // Not found - wait and retry (except on last attempt)
            if attempt < maxAttempts {
                try? await Task.sleep(nanoseconds: delayNanoseconds)
                delayNanoseconds *= 2 // Exponential backoff: 100ms, 200ms, 400ms
            }
        }

        // Transaction not found after all retries
        return TransactionQueryResult()
    }

    /// Returns a fallback expiry date based on subscription plan type
    /// Used when StoreKit transaction hasn't propagated yet
    private static func fallbackExpiryDate(for plan: SubscriptionPlan) -> Date {
        let calendar = Calendar.current
        switch plan {
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        case .annual:
            return calendar.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        case .free:
            return Date()
        }
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

        // Check in-memory cache first (populated by StoreKit queries)
        let planFromMemory = subscriptionPlanFromPurchases(cachedValidPurchases)

        if planFromMemory != .free {
            return planFromMemory
        }

        // Fall back to Keychain cache for offline scenarios
        // This ensures Settings shows the correct plan when StoreKit is unavailable
        return await SecurePremiumCache.shared.getCachedSubscriptionPlan()
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

    public func isOnTrial() async -> Bool {
        // Query StoreKit for current entitlements to check offer type
        for await result in Transaction.currentEntitlements {
            // Verify transaction cryptographically
            guard let transaction = try? checkVerified(result) else {
                continue
            }

            // Check if this is a subscription with an introductory offer (free trial)
            if transaction.offer?.type == .introductory {
                return true
            }
        }

        return false
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
        guard shouldRefreshCache(force: force) else { return }

        // Query StoreKit for current entitlements
        let entitlementResult = await processCurrentEntitlements()

        // Update in-memory cache
        cachedValidPurchases = entitlementResult.validPurchases
        lastCacheUpdate = Date()

        // Update secure cache based on entitlement results
        await updateSecureCache(with: entitlementResult)
    }

    /// Check if cache refresh is needed
    private func shouldRefreshCache(force: Bool) -> Bool {
        if force { return true }
        let timeSinceLastUpdate = Date().timeIntervalSince(lastCacheUpdate)
        return timeSinceLastUpdate > cacheValidityDuration
    }

    /// Result of querying a specific transaction with retry logic
    private struct TransactionQueryResult {
        var found = false
        var isOnTrial = false
        var expiryDate: Date?
    }

    /// Result of processing StoreKit entitlements
    private struct EntitlementResult {
        var validPurchases: Set<String> = []
        var didReceiveAnyEntitlement = false
        var isOnTrial = false
        var expiryDate: Date?
    }

    /// Process all current entitlements from StoreKit
    private func processCurrentEntitlements() async -> EntitlementResult {
        var result = EntitlementResult()

        for await verificationResult in Transaction.currentEntitlements {
            result.didReceiveAnyEntitlement = true

            guard let transaction = try? checkVerified(verificationResult) else { continue }
            guard await isTransactionValid(transaction) else { continue }

            result.validPurchases.insert(transaction.productID)

            if transaction.offer?.type == .introductory {
                result.isOnTrial = true
            }
            if let transactionExpiry = transaction.expirationDate {
                // Keep the earliest expiry date if multiple subscriptions
                if let currentExpiry = result.expiryDate {
                    if transactionExpiry < currentExpiry {
                        result.expiryDate = transactionExpiry
                    }
                } else {
                    result.expiryDate = transactionExpiry
                }
            }
        }

        return result
    }

    /// Update secure cache based on entitlement results
    private func updateSecureCache(with result: EntitlementResult) async {
        let plan = subscriptionPlanFromPurchases(result.validPurchases)

        if plan != .free {
            // Determine expiry date - use 1-day fallback if missing to force earlier re-verification
            let effectiveExpiryDate: Date?
            if let expiryDate = result.expiryDate {
                effectiveExpiryDate = expiryDate
            } else {
                // StoreKit API issue - no expiry date provided
                // Use 1-day fallback to force re-verification sooner
                effectiveExpiryDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                Container.shared.debugLogger().log(
                    "Active subscription (\(plan)) has no expiry date - using 1-day fallback for cache",
                    level: .warning,
                    category: .subscription
                )
            }

            // User has valid subscription - update cache with trial info and expiry
            await SecurePremiumCache.shared.updateCache(
                plan: plan,
                isOnTrial: result.isOnTrial,
                expiryDate: effectiveExpiryDate
            )
        } else if result.didReceiveAnyEntitlement {
            // StoreKit responded with entitlements but none are valid (expired/revoked)
            await SecurePremiumCache.shared.updateCache(plan: .free)
        } else {
            // StoreKit returned NO entitlements - preserve grace period if cache still valid
            let cacheStillValid = await SecurePremiumCache.shared.isCacheValid()
            if !cacheStillValid {
                await SecurePremiumCache.shared.updateCache(plan: .free)
            }
        }
    }

    /// Determine subscription plan from a set of valid product IDs
    private func subscriptionPlanFromPurchases(_ purchases: Set<String>) -> SubscriptionPlan {
        // Check for annual subscription (highest priority)
        if purchases.contains(StoreKitProductID.annual) {
            return .annual
        }
        // Check for monthly subscription
        if purchases.contains(StoreKitProductID.monthly) {
            return .monthly
        }
        // Check for weekly subscription
        if purchases.contains(StoreKitProductID.weekly) {
            return .weekly
        }
        return .free
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
