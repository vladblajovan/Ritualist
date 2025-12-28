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

    static func queryStoreKitWithTimeout(timeout: Double) async -> Bool {
        let timeoutNanoseconds = UInt64(timeout) * 1_000_000_000

        return await withTaskGroup(of: Bool?.self) { group in
            group.addTask { await queryCurrentEntitlements() }
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                return nil
            }

            if let queryResult = await group.next() {
                group.cancelAll()
                if let value = queryResult {
                    await SecurePremiumCache.shared.updateCache(isPremium: value)
                    return value
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

    static func queryCurrentEntitlements() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() { return true }
                        if await checkGracePeriodStatus() { return true }
                    } else {
                        return true
                    }
                }
            }
        }
        return false
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
