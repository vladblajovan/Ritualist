//
//  StoreKitSubscriptionService+GracePeriod.swift
//  Ritualist
//
//  Grace period and cache management extracted to reduce type body length.
//

import Foundation
import StoreKit
import RitualistCore
import FactoryKit

// MARK: - Grace Period Handling

extension StoreKitSubscriptionService {

    /// Checks grace period status (billing dialog suppressed for 24h after shown)
    func isUserInGracePeriod() async -> Bool {
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

    func handleGracePeriodState(_ state: StoreKit.Product.SubscriptionInfo.RenewalState) async -> Bool? {
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
}

// MARK: - Cache Update

extension StoreKitSubscriptionService {

    func updateSecureCache(with result: EntitlementResult) async {
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

    func subscriptionPlanFromPurchases(_ purchases: Set<String>) -> SubscriptionPlan {
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
}
