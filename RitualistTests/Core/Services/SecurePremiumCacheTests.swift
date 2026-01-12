//
//  SecurePremiumCacheTests.swift
//  RitualistTests
//
//  Tests for SecurePremiumCache - the Keychain-based premium status cache.
//  These tests run against the real Keychain (requires simulator).
//

import Testing
import Foundation
@testable import RitualistCore

@Suite("SecurePremiumCache", .tags(.businessLogic, .critical), .serialized)
struct SecurePremiumCacheTests {

    // MARK: - Setup Helper

    /// Clear cache before each test to ensure isolation
    private func clearCacheForTest() async {
        await SecurePremiumCache.shared.clearCache()
    }

    // MARK: - Basic Cache Operations

    @Test("Fresh cache returns free status")
    func freshCache_returnsFreeStatus() async {
        await clearCacheForTest()

        let isPremium = await SecurePremiumCache.shared.getCachedPremiumStatus()
        let plan = await SecurePremiumCache.shared.getCachedSubscriptionPlan()

        #expect(isPremium == false)
        #expect(plan == .free)
    }

    @Test("Update cache with monthly plan stores premium status")
    func updateCache_monthlyPlan_storesPremiumStatus() async {
        await clearCacheForTest()

        await SecurePremiumCache.shared.updateCache(plan: .monthly)

        let isPremium = await SecurePremiumCache.shared.getCachedPremiumStatus()
        let plan = await SecurePremiumCache.shared.getCachedSubscriptionPlan()

        #expect(isPremium == true)
        #expect(plan == .monthly)
    }

    @Test("Update cache with yearly plan stores premium status")
    func updateCache_yearlyPlan_storesPremiumStatus() async {
        await clearCacheForTest()

        await SecurePremiumCache.shared.updateCache(plan: .annual)

        let isPremium = await SecurePremiumCache.shared.getCachedPremiumStatus()
        let plan = await SecurePremiumCache.shared.getCachedSubscriptionPlan()

        #expect(isPremium == true)
        #expect(plan == .annual)
    }

    @Test("Update cache with free plan stores non-premium status")
    func updateCache_freePlan_storesNonPremiumStatus() async {
        await clearCacheForTest()

        // First set to premium
        await SecurePremiumCache.shared.updateCache(plan: .monthly)
        #expect(await SecurePremiumCache.shared.getCachedPremiumStatus() == true)

        // Then downgrade to free
        await SecurePremiumCache.shared.updateCache(plan: .free)

        let isPremium = await SecurePremiumCache.shared.getCachedPremiumStatus()
        let plan = await SecurePremiumCache.shared.getCachedSubscriptionPlan()

        #expect(isPremium == false)
        #expect(plan == .free)
    }

    @Test("Clear cache removes all cached data")
    func clearCache_removesAllData() async {
        await clearCacheForTest()

        // Set up PAID premium state (not trial - trials don't get offline grace)
        await SecurePremiumCache.shared.updateCache(
            plan: .annual,
            isOnTrial: false,
            expiryDate: Date().addingTimeInterval(86400)
        )

        // Verify it was stored
        #expect(await SecurePremiumCache.shared.getCachedPremiumStatus() == true)

        // Clear and verify
        await SecurePremiumCache.shared.clearCache()

        let isPremium = await SecurePremiumCache.shared.getCachedPremiumStatus()
        let plan = await SecurePremiumCache.shared.getCachedSubscriptionPlan()
        let cacheAge = await SecurePremiumCache.shared.getCacheAge()

        #expect(isPremium == false)
        #expect(plan == .free)
        #expect(cacheAge == nil)
    }

    // MARK: - Trial Subscription Behavior

    @Test("Trial with future expiry returns non-premium (no offline grace period for trials)")
    func trial_futureExpiry_returnsNonPremiumStatus() async {
        await clearCacheForTest()

        // Trials don't get offline grace period - must verify with StoreKit
        let futureDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days from now
        await SecurePremiumCache.shared.updateCache(
            plan: .monthly,
            isOnTrial: true,
            expiryDate: futureDate
        )

        let isPremium = await SecurePremiumCache.shared.getCachedPremiumStatus()

        // Trials never get offline grace period - even with future expiry
        #expect(isPremium == false)
    }

    @Test("Trial with past expiry returns non-premium status (no grace period)")
    func trial_pastExpiry_returnsNonPremiumStatus() async {
        await clearCacheForTest()

        let pastDate = Date().addingTimeInterval(-1) // 1 second ago (expired)
        await SecurePremiumCache.shared.updateCache(
            plan: .monthly,
            isOnTrial: true,
            expiryDate: pastDate
        )

        let isPremium = await SecurePremiumCache.shared.getCachedPremiumStatus()
        let plan = await SecurePremiumCache.shared.getCachedSubscriptionPlan()

        // Trials get NO grace period - expired means free immediately
        #expect(isPremium == false)
        #expect(plan == .free)
    }

    @Test("Trial without expiry date returns non-premium (conservative)")
    func trial_noExpiryDate_returnsNonPremium() async {
        await clearCacheForTest()

        // Trial without expiry date is invalid state - be conservative
        await SecurePremiumCache.shared.updateCache(
            plan: .monthly,
            isOnTrial: true,
            expiryDate: nil
        )

        let isPremium = await SecurePremiumCache.shared.getCachedPremiumStatus()

        // Invalid trial state should return false (conservative)
        #expect(isPremium == false)
    }

    // MARK: - Paid Subscription Behavior

    @Test("Paid subscription with future expiry returns premium status")
    func paidSubscription_futureExpiry_returnsPremiumStatus() async {
        await clearCacheForTest()

        let futureDate = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days
        await SecurePremiumCache.shared.updateCache(
            plan: .annual,
            isOnTrial: false,
            expiryDate: futureDate
        )

        let isPremium = await SecurePremiumCache.shared.getCachedPremiumStatus()
        let plan = await SecurePremiumCache.shared.getCachedSubscriptionPlan()

        #expect(isPremium == true)
        #expect(plan == .annual)
    }

    @Test("Paid subscription without expiry date uses cache age for grace period")
    func paidSubscription_noExpiryDate_usesCacheAge() async {
        await clearCacheForTest()

        // Paid subscription without expiry uses cache timestamp
        await SecurePremiumCache.shared.updateCache(
            plan: .monthly,
            isOnTrial: false,
            expiryDate: nil
        )

        // Fresh cache should be valid
        let isPremium = await SecurePremiumCache.shared.getCachedPremiumStatus()
        let isValid = await SecurePremiumCache.shared.isCacheValid()

        #expect(isPremium == true)
        #expect(isValid == true)
    }

    // MARK: - Cache Validity Checks

    @Test("Fresh cache is valid")
    func freshCache_isValid() async {
        await clearCacheForTest()

        await SecurePremiumCache.shared.updateCache(plan: .monthly)

        let isValid = await SecurePremiumCache.shared.isCacheValid()
        let isStale = await SecurePremiumCache.shared.isCacheStale()

        #expect(isValid == true)
        #expect(isStale == false)
    }

    @Test("Fresh cache allows skipping verification")
    func freshCache_canSkipVerification() async {
        await clearCacheForTest()

        await SecurePremiumCache.shared.updateCache(plan: .annual)

        let canSkip = await SecurePremiumCache.shared.canSkipVerification()

        #expect(canSkip == true)
    }

    @Test("No cache is stale")
    func noCache_isStale() async {
        await clearCacheForTest()

        let isStale = await SecurePremiumCache.shared.isCacheStale()
        let canSkip = await SecurePremiumCache.shared.canSkipVerification()

        #expect(isStale == true)
        #expect(canSkip == false)
    }

    @Test("Cache age is tracked correctly")
    func cacheAge_isTrackedCorrectly() async throws {
        await clearCacheForTest()

        await SecurePremiumCache.shared.updateCache(plan: .monthly)

        // Small delay to ensure measurable age
        try await Task.sleep(for: .milliseconds(50))

        let age = await SecurePremiumCache.shared.getCacheAge()

        #expect(age != nil)
        #expect(age! >= 0.05) // At least 50ms
        #expect(age! < 5.0)   // Less than 5 seconds (sanity check)
    }

    // MARK: - Plan Transitions

    @Test("Upgrade from free to premium updates cache")
    func upgrade_freeToPremium_updatesCache() async {
        await clearCacheForTest()

        // Start as free
        await SecurePremiumCache.shared.updateCache(plan: .free)
        #expect(await SecurePremiumCache.shared.getCachedPremiumStatus() == false)

        // Upgrade to premium
        await SecurePremiumCache.shared.updateCache(plan: .annual)

        #expect(await SecurePremiumCache.shared.getCachedPremiumStatus() == true)
        #expect(await SecurePremiumCache.shared.getCachedSubscriptionPlan() == .annual)
    }

    @Test("Downgrade from premium to free updates cache")
    func downgrade_premiumToFree_updatesCache() async {
        await clearCacheForTest()

        // Start as premium
        await SecurePremiumCache.shared.updateCache(plan: .monthly)
        #expect(await SecurePremiumCache.shared.getCachedPremiumStatus() == true)

        // Downgrade to free
        await SecurePremiumCache.shared.updateCache(plan: .free)

        #expect(await SecurePremiumCache.shared.getCachedPremiumStatus() == false)
        #expect(await SecurePremiumCache.shared.getCachedSubscriptionPlan() == .free)
    }

    @Test("Switch between monthly and yearly preserves premium status")
    func planSwitch_monthlyToYearly_preservesPremium() async {
        await clearCacheForTest()

        await SecurePremiumCache.shared.updateCache(plan: .monthly)
        #expect(await SecurePremiumCache.shared.getCachedSubscriptionPlan() == .monthly)

        await SecurePremiumCache.shared.updateCache(plan: .annual)
        #expect(await SecurePremiumCache.shared.getCachedSubscriptionPlan() == .annual)
        #expect(await SecurePremiumCache.shared.getCachedPremiumStatus() == true)
    }

    // MARK: - Constants Verification

    @Test("Grace period constant is 3 days")
    func gracePeriodConstant_is3Days() {
        let threeDaysInSeconds: TimeInterval = 3 * 24 * 60 * 60
        #expect(SecurePremiumCache.offlineGracePeriod == threeDaysInSeconds)
    }

    @Test("Staleness threshold constant is 7 days")
    func stalenessThresholdConstant_is7Days() {
        let sevenDaysInSeconds: TimeInterval = 7 * 24 * 60 * 60
        #expect(SecurePremiumCache.stalenessThreshold == sevenDaysInSeconds)
    }

    @Test("Verification skip threshold constant is 24 hours")
    func verificationSkipThresholdConstant_is24Hours() {
        let oneDayInSeconds: TimeInterval = 24 * 60 * 60
        #expect(SecurePremiumCache.verificationSkipThreshold == oneDayInSeconds)
    }
}
