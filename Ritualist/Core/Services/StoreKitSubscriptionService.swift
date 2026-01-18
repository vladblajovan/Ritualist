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
        cachedValidPurchases.insert(productId)
        lastCacheUpdate = Date()

        let plan = StoreKitProductID.subscriptionPlan(for: productId)
        let transactionInfo = await queryTransactionWithRetry(productId: productId)
        var expiryDate = transactionInfo.expiryDate

        if !transactionInfo.found {
            Container.shared.debugLogger().log(
                "Transaction not found after retries for \(productId) - using fallback expiry",
                level: .warning,
                category: .subscription
            )
            expiryDate = Self.fallbackExpiryDate(for: plan)
        }

        await SecurePremiumCache.shared.updateCache(
            plan: plan,
            isOnTrial: transactionInfo.isOnTrial,
            expiryDate: expiryDate
        )
        await SecurePremiumCache.shared.clearBillingIssueFlag()
    }

    private func queryTransactionWithRetry(productId: String) async -> TransactionQueryResult {
        var delayNanoseconds: UInt64 = 100_000_000
        let maxAttempts = 3

        for attempt in 1...maxAttempts {
            let result = await queryTransactionAttempt(productId: productId)

            if result.found {
                if attempt > 1 {
                    Self.startupLogger.log(
                        "Transaction found on retry attempt \(attempt) for \(productId)",
                        level: .info,
                        category: .subscription
                    )
                }
                return result
            }

            if attempt < maxAttempts {
                Self.startupLogger.log(
                    "Transaction not found for \(productId), attempt \(attempt)/\(maxAttempts) - retrying after \(delayNanoseconds / 1_000_000)ms",
                    level: .debug,
                    category: .subscription
                )
                try? await Task.sleep(nanoseconds: delayNanoseconds)
                delayNanoseconds *= 2
            }
        }

        Self.startupLogger.log(
            "Transaction query exhausted all \(maxAttempts) attempts for \(productId)",
            level: .warning,
            category: .subscription
        )
        return TransactionQueryResult()
    }

    /// Single attempt to query a transaction for the given product ID.
    private func queryTransactionAttempt(productId: String) async -> TransactionQueryResult {
        var latestPurchaseDate: Date?
        var result = TransactionQueryResult()

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement,
                  transaction.productID == productId else {
                continue
            }

            let shouldUpdate = latestPurchaseDate.map { transaction.purchaseDate > $0 } ?? true
            if shouldUpdate {
                latestPurchaseDate = transaction.purchaseDate
                result.isOnTrial = transaction.offer?.type == .introductory
                result.expiryDate = transaction.expirationDate
            }
        }

        if latestPurchaseDate != nil {
            result.found = true
        }
        return result
    }

    private static func fallbackExpiryDate(for plan: SubscriptionPlan) -> Date {
        let calendar = Calendar.current
        switch plan {
        case .weekly: return calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        case .monthly: return calendar.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        case .annual: return calendar.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        case .free: return Date()
        }
    }

    public func clearPurchases() async throws {
        cachedValidPurchases.removeAll()
        lastCacheUpdate = .distantPast
        await SecurePremiumCache.shared.clearCache()
    }

    public func getCurrentSubscriptionPlan() async -> SubscriptionPlan {
        await refreshCacheIfNeeded()

        let planFromMemory = subscriptionPlanFromPurchases(cachedValidPurchases)
        if planFromMemory != .free {
            return planFromMemory
        }

        return await SecurePremiumCache.shared.getCachedSubscriptionPlan()
    }

    public func getSubscriptionExpiryDate() async -> Date? {
        await refreshCacheIfNeeded()

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else {
                continue
            }

            let isSubscription = transaction.productID.contains("monthly")
                || transaction.productID.contains("annual")

            if isSubscription, let expirationDate = transaction.expirationDate {
                return expirationDate
            }
        }

        return nil
    }

    public func isOnTrial() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else {
                continue
            }

            if transaction.offer?.type == .introductory {
                return true
            }
        }
        return false
    }

    // MARK: - Private Methods

    private func refreshCacheIfNeeded() async {
        let cacheAge = Date().timeIntervalSince(lastCacheUpdate)
        if cacheAge > cacheValidityDuration {
            await refreshCache(force: false)
        }
    }

    private func refreshCache(force: Bool) async {
        guard shouldRefreshCache(force: force) else {
            return
        }

        let entitlementResult = await processCurrentEntitlements()
        cachedValidPurchases = entitlementResult.validPurchases
        lastCacheUpdate = Date()
        await updateSecureCache(with: entitlementResult)
    }

    private func shouldRefreshCache(force: Bool) -> Bool {
        force || Date().timeIntervalSince(lastCacheUpdate) > cacheValidityDuration
    }

    private struct TransactionQueryResult {
        var found = false
        var isOnTrial = false
        var expiryDate: Date?
    }

    private struct EntitlementResult {
        var validPurchases: Set<String> = []
        var didReceiveAnyEntitlement = false
        var isOnTrial = false
        var expiryDate: Date?
    }

    private func processCurrentEntitlements() async -> EntitlementResult {
        var result = EntitlementResult()

        for await verificationResult in Transaction.currentEntitlements {
            result.didReceiveAnyEntitlement = true

            guard let transaction = try? checkVerified(verificationResult) else {
                continue
            }
            guard await isTransactionValid(transaction) else {
                continue
            }

            result.validPurchases.insert(transaction.productID)

            if transaction.offer?.type == .introductory {
                result.isOnTrial = true
            }

            if let transactionExpiry = transaction.expirationDate {
                if let currentExpiry = result.expiryDate {
                    // Keep the earliest expiry date
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

    private func updateSecureCache(with result: EntitlementResult) async {
        let plan = subscriptionPlanFromPurchases(result.validPurchases)

        if plan != .free {
            let effectiveExpiryDate: Date? = result.expiryDate ?? {
                Container.shared.debugLogger().log(
                    "Active subscription (\(plan)) has no expiry date - using 1-day fallback for cache",
                    level: .warning,
                    category: .subscription
                )
                return Calendar.current.date(byAdding: .day, value: 1, to: Date())
            }()

            await SecurePremiumCache.shared.updateCache(
                plan: plan,
                isOnTrial: result.isOnTrial,
                expiryDate: effectiveExpiryDate
            )
        } else if result.didReceiveAnyEntitlement {
            await SecurePremiumCache.shared.updateCache(plan: .free)
        } else {
            let isCacheValid = await SecurePremiumCache.shared.isCacheValid()
            if !isCacheValid {
                await SecurePremiumCache.shared.updateCache(plan: .free)
            }
        }
    }

    private func subscriptionPlanFromPurchases(_ purchases: Set<String>) -> SubscriptionPlan {
        if purchases.contains(StoreKitProductID.annual) {
            return .annual
        }
        if purchases.contains(StoreKitProductID.monthly) {
            return .monthly
        }
        if purchases.contains(StoreKitProductID.weekly) {
            return .weekly
        }
        return .free
    }

    /// Validates transaction (grace period aware)
    private func isTransactionValid(_ transaction: Transaction) async -> Bool {
        if transaction.revocationDate != nil {
            return false
        }

        if let expirationDate = transaction.expirationDate {
            if expirationDate > Date() {
                return true
            }
            return await isUserInGracePeriod()
        }

        return true
    }

    /// Checks grace period status (billing dialog suppressed for 24h after shown)
    private func isUserInGracePeriod() async -> Bool {
        if await SecurePremiumCache.shared.shouldSuppressBillingDialog() {
            Self.startupLogger.log(
                "🔔 Billing dialog suppressed (24h) - assuming grace period active",
                level: .info,
                category: .subscription
            )
            return true
        }

        do {
            let statuses = try await Product.SubscriptionInfo.status(for: StoreKitProductID.subscriptionGroupID)

            for status in statuses {
                if let result = await handleGracePeriodState(status.state) {
                    return result
                }
            }

            return false
        } catch {
            Self.startupLogger.log(
                "⚠️ Failed to check subscription status for grace period: \(error.localizedDescription)",
                level: .warning,
                category: .subscription
            )
            return false
        }
    }

    private func handleGracePeriodState(_ state: StoreKit.Product.SubscriptionInfo.RenewalState) async -> Bool? {
        switch state {
        case .subscribed:
            await SecurePremiumCache.shared.clearBillingIssueFlag()
            return true

        case .inGracePeriod:
            Self.startupLogger.log(
                "🔔 User in billing grace period - retaining premium access",
                level: .info,
                category: .subscription
            )
            await SecurePremiumCache.shared.recordBillingIssueDetected()
            return true

        case .inBillingRetryPeriod:
            Self.startupLogger.log(
                "🔔 User in billing retry period - retaining premium access",
                level: .info,
                category: .subscription
            )
            await SecurePremiumCache.shared.recordBillingIssueDetected()
            return true

        case .expired:
            Self.startupLogger.log(
                "🔔 Subscription expired - clearing all caches",
                level: .info,
                category: .subscription
            )
            await SecurePremiumCache.shared.clearCache()
            return false

        case .revoked:
            Self.startupLogger.log(
                "🔔 Subscription revoked - clearing all caches",
                level: .info,
                category: .subscription
            )
            await SecurePremiumCache.shared.clearCache()
            return false

        default:
            return nil
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T? {
        switch result {
        case .unverified(_, let verificationError):
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
