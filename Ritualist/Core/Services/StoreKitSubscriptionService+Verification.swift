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
        /// User has a valid premium subscription
        case premium
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
                    // Handle the result based on what StoreKit returned
                    switch result {
                    case .premium:
                        // User has valid subscription - always update cache
                        await SecurePremiumCache.shared.updateCache(isPremium: true)
                        return true

                    case .notPremiumConfirmed:
                        // StoreKit confirmed no valid subscription - safe to update cache
                        await SecurePremiumCache.shared.updateCache(isPremium: false)
                        return false

                    case .noEntitlementsReturned:
                        // StoreKit returned NO entitlements - could be:
                        // 1. User truly never purchased (should return false)
                        // 2. StoreKit Config file issue / race condition (preserve cache)
                        //
                        // To protect against StoreKit testing issues while still being correct
                        // for real users, only update cache if it's already expired/invalid.
                        // This preserves the 3-day grace period for purchased users.
                        let cacheStillValid = await SecurePremiumCache.shared.isCacheValid()
                        if cacheStillValid {
                            startupLogger.log(
                                "⚠️ StoreKit returned no entitlements but cache is valid - preserving cache",
                                level: .warning,
                                category: .subscription,
                                metadata: ["cache_age_hours": String(format: "%.1f", (await SecurePremiumCache.shared.getCacheAge() ?? 0) / 3600)]
                            )
                            return await SecurePremiumCache.shared.getCachedPremiumStatus()
                        } else {
                            // Cache expired or doesn't exist - user is not premium
                            await SecurePremiumCache.shared.updateCache(isPremium: false)
                            return false
                        }
                    }
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

    private static func queryCurrentEntitlements() async -> EntitlementQueryResult {
        var didReceiveAnyEntitlement = false

        for await result in Transaction.currentEntitlements {
            didReceiveAnyEntitlement = true

            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() { return .premium }
                        if await checkGracePeriodStatus() { return .premium }
                    } else {
                        return .premium
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
    /// - Returns: `true` if user is in grace period or billing retry, `false` otherwise
    ///
    static func checkGracePeriodStatus() async -> Bool {
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
}
