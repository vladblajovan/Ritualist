//
//  StoreKitSubscriptionService+Verification.swift
//  Ritualist
//
//  Static premium verification methods for startup checks
//

import Foundation
import StoreKit
import RitualistCore

// MARK: - Static Premium Verification

extension StoreKitSubscriptionService {

    // Local logger: Static methods run before DI container is initialized
    static let startupLogger = DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "subscription")

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
        await verifyPremiumSync(timeout: 5.0, forceVerification: forceVerification)
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

        if let cachedResult = await checkCachedPremiumStatus(forceVerification: forceVerification) {
            return cachedResult
        }

        await logStoreKitQueryStart(forceVerification: forceVerification)
        let result = await queryStoreKitWithTimeout(timeout: timeout)
        logVerificationCompleted(result: result, startTime: startTime, timeout: timeout)
        return result
    }

    static func checkCachedPremiumStatus(forceVerification: Bool) async -> Bool? {
        guard !forceVerification else { return nil }
        guard await SecurePremiumCache.shared.canSkipVerification() else { return nil }

        let cachedStatus = await SecurePremiumCache.shared.getCachedPremiumStatus()
        let cacheAge = await SecurePremiumCache.shared.getCacheAge() ?? 0

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

    static func logStoreKitQueryStart(forceVerification: Bool) async {
        let cacheAge = await SecurePremiumCache.shared.getCacheAge()
        startupLogger.log(
            "🔐 Querying StoreKit for premium status",
            level: .info,
            category: .subscription,
            metadata: [
                "reason": forceVerification ? "forced" : (cacheAge == nil ? "no_cache" : "cache_stale"),
                "cache_age_hours": cacheAge.map { String(format: "%.1f", $0 / 3600) } ?? "none"
            ]
        )
    }

    /// Result of querying StoreKit for entitlements
    private enum EntitlementQueryResult {
        /// User has a valid premium subscription with specific plan
        case premium(SubscriptionPlan)
        /// StoreKit returned entitlements but none are valid (all expired/revoked)
        case notPremiumConfirmed
        /// StoreKit returned NO entitlements at all (could be: never purchased, OR StoreKit failure)
        case noEntitlementsReturned
    }

    static func queryStoreKitWithTimeout(timeout: Double) async -> Bool {
        let timeoutNanoseconds = UInt64(timeout) * 1_000_000_000

        return await withTaskGroup(of: EntitlementQueryResult?.self) { group in
            group.addTask { await queryCurrentEntitlements() }
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                return nil
            }

            if let queryResult = await group.next() {
                group.cancelAll()
                if let result = queryResult {
                    return await handleEntitlementQueryResult(result)
                } else {
                    startupLogger.log(
                        "⚠️ StoreKit verification timed out after \(Int(timeout))s - using cached value",
                        level: .warning,
                        category: .subscription
                    )
                    return await SecurePremiumCache.shared.getCachedPremiumStatus()
                }
            }
            return false
        }
    }

    /// Handles the result of an entitlement query and returns premium status.
    private static func handleEntitlementQueryResult(_ result: EntitlementQueryResult) async -> Bool {
        switch result {
        case .premium(let plan):
            // User has valid subscription - update cache
            // NOTE: We do NOT clear the billing flag here because .premium can mean:
            // 1. Active subscription (expiration in future)
            // 2. Grace period (expiration in past, but billing grace active)
            // The billing flag is cleared ONLY in checkGracePeriodStatus() when
            // we confirm the status is .subscribed (not .inGracePeriod)
            await SecurePremiumCache.shared.updateCache(plan: plan)
            return true

        case .notPremiumConfirmed:
            // StoreKit confirmed no valid subscription (all expired/revoked)
            startupLogger.log(
                "🔔 StoreKit confirmed not premium - clearing all caches",
                level: .info,
                category: .subscription
            )
            await SecurePremiumCache.shared.clearCache()
            return false

        case .noEntitlementsReturned:
            return await handleNoEntitlementsResult()
        }
    }

    /// Handles the case when StoreKit returns no entitlements.
    private static func handleNoEntitlementsResult() async -> Bool {
        // StoreKit returned NO entitlements - could be:
        // 1. User truly never purchased (should return false)
        // 2. Subscription fully expired and removed (should return false)
        // 3. StoreKit Config file issue / race condition (preserve cache briefly)
        let cacheStillValid = await SecurePremiumCache.shared.isCacheValid()
        if cacheStillValid {
            startupLogger.log(
                "⚠️ StoreKit returned no entitlements but cache is valid - preserving cache briefly",
                level: .warning,
                category: .subscription,
                metadata: ["cache_age_hours": String(format: "%.1f", (await SecurePremiumCache.shared.getCacheAge() ?? 0) / 3600)]
            )
            return await SecurePremiumCache.shared.getCachedPremiumStatus()
        } else {
            startupLogger.log(
                "🔔 No entitlements and cache expired - clearing all caches, falling back to free",
                level: .info,
                category: .subscription
            )
            await SecurePremiumCache.shared.clearCache()
            return false
        }
    }

    private static func queryCurrentEntitlements() async -> EntitlementQueryResult {
        var didReceiveAnyEntitlement = false

        for await result in Transaction.currentEntitlements {
            didReceiveAnyEntitlement = true

            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    let plan = StoreKitProductID.subscriptionPlan(for: transaction.productID)
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() { return .premium(plan) }
                        if await checkGracePeriodStatus() { return .premium(plan) }
                    } else {
                        return .premium(plan)
                    }
                }
            }
        }

        // Distinguish between "received entitlements but all invalid" vs "received nothing"
        return didReceiveAnyEntitlement ? .notPremiumConfirmed : .noEntitlementsReturned
    }

    static func logVerificationCompleted(result: Bool, startTime: Date, timeout: Double) {
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
    }

    // MARK: - Static Grace Period Check

    /// Static helper to check if user is in billing grace period
    ///
    /// Used by `verifyPremiumSync` during startup verification when a subscription
    /// appears expired. This allows users in grace period to retain premium access.
    ///
    /// **Billing Dialog Handling:**
    /// - Calling `Product.SubscriptionInfo.status()` when user is in grace period
    ///   triggers Apple's "Billing Problem" system dialog
    /// - We suppress this dialog for 24 hours after it's shown (daily reminder pattern)
    /// - When suppressed, we STILL check if user should get premium via cache validity
    /// - When subscription is `.expired` or `.revoked`, we clear ALL caches
    ///
    /// **State Transitions:**
    /// - `.inGracePeriod` / `.inBillingRetryPeriod` → Grant premium, suppress dialog 24h
    /// - `.expired` / `.revoked` → Clear all caches, deny premium
    ///
    /// - Returns: `true` if user is in grace period or billing retry, `false` otherwise
    ///
    static func checkGracePeriodStatus() async -> Bool {
        if let suppressedResult = await checkBillingDialogSuppression() {
            return suppressedResult
        }
        return await querySubscriptionStatuses()
    }

    /// Checks if billing dialog should be suppressed and returns cached premium status if so.
    /// - Returns: `true` if premium should be granted (dialog suppressed), `nil` if we need to query StoreKit
    private static func checkBillingDialogSuppression() async -> Bool? {
        let shouldSuppressDialog = await SecurePremiumCache.shared.shouldSuppressBillingDialog()
        let cacheValid = await SecurePremiumCache.shared.isCacheValid()
        let cacheAge = await SecurePremiumCache.shared.getCacheAge()

        startupLogger.log(
            "🔍 Billing dialog check",
            level: .debug,
            category: .subscription,
            metadata: [
                "should_suppress": shouldSuppressDialog,
                "cache_valid": cacheValid,
                "cache_age_hours": cacheAge.map { String(format: "%.2f", $0 / 3600) } ?? "nil"
            ]
        )

        guard shouldSuppressDialog else { return nil }

        // Dialog is suppressed - grant premium (either cache valid or known billing issue)
        let reason = cacheValid ? "cache valid" : "known billing issue"
        startupLogger.log(
            "🔔 Startup: Billing dialog suppressed (24h), \(reason) - granting premium",
            level: .info,
            category: .subscription
        )
        return true
    }

    /// Queries StoreKit for subscription statuses and handles each state.
    private static func querySubscriptionStatuses() async -> Bool {
        do {
            let statuses = try await Product.SubscriptionInfo.status(
                for: StoreKitProductID.subscriptionGroupID
            )

            for status in statuses {
                if let result = await handleSubscriptionState(status.state) {
                    return result
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

    /// Handles a single subscription state, returning premium status or nil to continue checking.
    private static func handleSubscriptionState(_ state: StoreKit.Product.SubscriptionInfo.RenewalState) async -> Bool? {
        switch state {
        case .subscribed:
            await SecurePremiumCache.shared.clearBillingIssueFlag()
            return true

        case .inGracePeriod:
            startupLogger.log(
                "🔔 Startup: User in billing grace period - granting premium access",
                level: .info,
                category: .subscription
            )
            await SecurePremiumCache.shared.recordBillingIssueDetected()
            return true

        case .inBillingRetryPeriod:
            startupLogger.log(
                "🔔 Startup: User in billing retry period - granting premium access",
                level: .info,
                category: .subscription
            )
            await SecurePremiumCache.shared.recordBillingIssueDetected()
            return true

        case .expired:
            startupLogger.log(
                "🔔 Startup: Subscription expired - clearing all caches, falling back to free",
                level: .info,
                category: .subscription
            )
            await SecurePremiumCache.shared.clearCache()
            return false

        case .revoked:
            startupLogger.log(
                "🔔 Startup: Subscription revoked - clearing all caches, falling back to free",
                level: .info,
                category: .subscription
            )
            await SecurePremiumCache.shared.clearCache()
            return false

        default:
            return nil
        }
    }
}
