//
//  FeatureGatingServiceTests.swift
//  RitualistTests
//
//  Tests for FeatureGatingService implementations - controls premium feature access
//  based on subscription status and build configuration.
//
//  Key Testing Focus:
//  - Free tier habit limits (5 habits max)
//  - Premium user unlimited access
//  - Build configuration overrides
//  - Feature availability per subscription tier
//

import Testing
import Foundation
@testable import RitualistCore

// MARK: - Test Doubles
//
// Note on @unchecked Sendable: These test doubles use mutable state (var properties)
// but are safe because:
// - Each @Test function creates its own isolated instance (not shared across tests)
// - All test suites are @MainActor isolated, ensuring single-threaded access
// - No concurrent mutations occur within a single test execution
// - The test framework creates fresh instances per test, not shared state

/// Configurable mock subscription service for testing feature gating logic
final class TestFeatureGatingSubscriptionService: SecureSubscriptionService, @unchecked Sendable {
    var isPremium: Bool = false
    var validPurchases: [String] = []
    var currentPlan: SubscriptionPlan = .free
    var expiryDate: Date? = nil
    var isTrialing: Bool = false

    func validatePurchase(_ productId: String) async -> Bool {
        validPurchases.contains(productId)
    }

    func restorePurchases() async -> [String] {
        validPurchases
    }

    func isPremiumUser() async -> Bool {
        isPremium
    }

    func getValidPurchases() async -> [String] {
        validPurchases
    }

    func registerPurchase(_ productId: String) async throws {
        validPurchases.append(productId)
    }

    func clearPurchases() async throws {
        validPurchases.removeAll()
    }

    func getCurrentSubscriptionPlan() async -> SubscriptionPlan {
        currentPlan
    }

    func getSubscriptionExpiryDate() async -> Date? {
        expiryDate
    }

    func isOnTrial() async -> Bool {
        isTrialing
    }
}

/// Configurable mock build configuration service
final class TestFeatureGatingBuildConfigService: BuildConfigurationService, @unchecked Sendable {
    var allFeaturesEnabledOverride: Bool = false

    var buildConfiguration: BuildConfiguration {
        allFeaturesEnabledOverride ? .allFeaturesEnabled : .subscriptionBased
    }

    var allFeaturesEnabled: Bool {
        allFeaturesEnabledOverride
    }

    var subscriptionGatingEnabled: Bool {
        !allFeaturesEnabledOverride
    }

    var shouldShowPaywalls: Bool {
        subscriptionGatingEnabled
    }
}

// MARK: - DefaultFeatureGatingService Tests - Free User

@Suite("DefaultFeatureGatingService - Free User", .tags(.businessLogic, .settings))
struct DefaultFeatureGatingServiceFreeUserTests {

    let subscriptionService: TestFeatureGatingSubscriptionService
    let service: DefaultFeatureGatingService

    init() {
        subscriptionService = TestFeatureGatingSubscriptionService()
        subscriptionService.isPremium = false
        service = DefaultFeatureGatingService(subscriptionService: subscriptionService)
    }

    @Test("Free user has max 5 habits limit")
    func freeUser_hasMaxFiveHabitsLimit() async {
        let maxHabits = await service.maxHabitsAllowed()

        #expect(maxHabits == BusinessConstants.freeMaxHabits)
        #expect(maxHabits == 5)
    }

    @Test("Free user can create habits up to limit")
    func freeUser_canCreateHabitsUpToLimit() async {
        // Can create when under limit
        #expect(await service.canCreateMoreHabits(currentCount: 0) == true)
        #expect(await service.canCreateMoreHabits(currentCount: 1) == true)
        #expect(await service.canCreateMoreHabits(currentCount: 4) == true)

        // Cannot create when at or over limit
        #expect(await service.canCreateMoreHabits(currentCount: 5) == false)
        #expect(await service.canCreateMoreHabits(currentCount: 10) == false)
    }

    @Test("Free user does not have advanced analytics")
    func freeUser_noAdvancedAnalytics() async {
        let hasAnalytics = await service.hasAdvancedAnalytics()

        #expect(hasAnalytics == false)
    }

    @Test("Free user does not have custom reminders")
    func freeUser_noCustomReminders() async {
        let hasReminders = await service.hasCustomReminders()

        #expect(hasReminders == false)
    }

    @Test("Free user does not have data export")
    func freeUser_noDataExport() async {
        let hasExport = await service.hasDataExport()

        #expect(hasExport == false)
    }

    @Test("Free user isFeatureAvailable returns false for all premium features")
    func freeUser_noFeaturesAvailable() async {
        for feature in FeatureType.allCases {
            let available = await service.isFeatureAvailable(feature)
            #expect(available == false, "\(feature) should not be available for free user")
        }
    }

    @Test("Free user is over habit limit when exceeding 5 habits")
    func freeUser_isOverLimitWhenExceedingFive() async {
        // Not over limit at or under 5
        #expect(await service.isOverActiveHabitLimit(activeCount: 0) == false)
        #expect(await service.isOverActiveHabitLimit(activeCount: 5) == false)

        // Over limit when exceeding 5
        #expect(await service.isOverActiveHabitLimit(activeCount: 6) == true)
        #expect(await service.isOverActiveHabitLimit(activeCount: 10) == true)
    }
}

// MARK: - DefaultFeatureGatingService Tests - Premium User

@Suite("DefaultFeatureGatingService - Premium User", .tags(.businessLogic, .settings))
struct DefaultFeatureGatingServicePremiumUserTests {

    let subscriptionService: TestFeatureGatingSubscriptionService
    let service: DefaultFeatureGatingService

    init() {
        subscriptionService = TestFeatureGatingSubscriptionService()
        subscriptionService.isPremium = true
        subscriptionService.currentPlan = .monthly
        service = DefaultFeatureGatingService(subscriptionService: subscriptionService)
    }

    @Test("Premium user has unlimited habits")
    func premiumUser_hasUnlimitedHabits() async {
        let maxHabits = await service.maxHabitsAllowed()

        #expect(maxHabits == Int.max)
    }

    @Test("Premium user can always create more habits")
    func premiumUser_canAlwaysCreateHabits() async {
        // Can create at any count
        #expect(await service.canCreateMoreHabits(currentCount: 0) == true)
        #expect(await service.canCreateMoreHabits(currentCount: 5) == true)
        #expect(await service.canCreateMoreHabits(currentCount: 100) == true)
        #expect(await service.canCreateMoreHabits(currentCount: 1000) == true)
    }

    @Test("Premium user has advanced analytics")
    func premiumUser_hasAdvancedAnalytics() async {
        let hasAnalytics = await service.hasAdvancedAnalytics()

        #expect(hasAnalytics == true)
    }

    @Test("Premium user has custom reminders")
    func premiumUser_hasCustomReminders() async {
        let hasReminders = await service.hasCustomReminders()

        #expect(hasReminders == true)
    }

    @Test("Premium user has data export")
    func premiumUser_hasDataExport() async {
        let hasExport = await service.hasDataExport()

        #expect(hasExport == true)
    }

    @Test("Premium user isFeatureAvailable returns true for all features")
    func premiumUser_allFeaturesAvailable() async {
        for feature in FeatureType.allCases {
            let available = await service.isFeatureAvailable(feature)
            #expect(available == true, "\(feature) should be available for premium user")
        }
    }

    @Test("Premium user is never over habit limit")
    func premiumUser_neverOverLimit() async {
        // Never over limit regardless of count
        #expect(await service.isOverActiveHabitLimit(activeCount: 0) == false)
        #expect(await service.isOverActiveHabitLimit(activeCount: 10) == false)
        #expect(await service.isOverActiveHabitLimit(activeCount: 100) == false)
        #expect(await service.isOverActiveHabitLimit(activeCount: 1000) == false)
    }
}

// MARK: - DefaultFeatureGatingService Tests - Blocked Messages

@Suite("DefaultFeatureGatingService - Blocked Messages", .tags(.businessLogic, .settings))
struct DefaultFeatureGatingServiceBlockedMessagesTests {

    let service: DefaultFeatureGatingService

    init() {
        let subscriptionService = TestFeatureGatingSubscriptionService()
        service = DefaultFeatureGatingService(subscriptionService: subscriptionService)
    }

    @Test("Unlimited habits blocked message mentions habit limit")
    func unlimitedHabitsMessage_mentionsLimit() {
        let message = service.getFeatureBlockedMessage(for: .unlimitedHabits)

        #expect(message.contains("5"))
        #expect(message.contains("habits"))
        #expect(message.contains("Pro") || message.contains("Upgrade"))
    }

    @Test("Advanced analytics blocked message mentions Pro")
    func advancedAnalyticsMessage_mentionsPro() {
        let message = service.getFeatureBlockedMessage(for: .advancedAnalytics)

        #expect(message.contains("analytics") || message.contains("Analytics"))
        #expect(message.contains("Pro"))
    }

    @Test("Custom reminders blocked message mentions Pro")
    func customRemindersMessage_mentionsPro() {
        let message = service.getFeatureBlockedMessage(for: .customReminders)

        #expect(message.contains("reminder") || message.contains("Reminder"))
        #expect(message.contains("Pro"))
    }

    @Test("Data export blocked message mentions Pro")
    func dataExportMessage_mentionsPro() {
        let message = service.getFeatureBlockedMessage(for: .dataExport)

        #expect(message.contains("Export") || message.contains("export"))
        #expect(message.contains("Pro"))
    }

    @Test("All blocked messages are non-empty")
    func allBlockedMessages_nonEmpty() {
        for feature in FeatureType.allCases {
            let message = service.getFeatureBlockedMessage(for: feature)
            #expect(!message.isEmpty, "\(feature) should have a non-empty blocked message")
            #expect(message.count > 20, "\(feature) should have a meaningful blocked message")
        }
    }
}

// MARK: - BuildConfigFeatureGatingService Tests - All Features Enabled

@Suite("BuildConfigFeatureGatingService - All Features Enabled", .tags(.businessLogic, .settings))
struct BuildConfigFeatureGatingServiceAllFeaturesEnabledTests {

    let buildConfigService: TestFeatureGatingBuildConfigService
    let service: BuildConfigFeatureGatingService

    init() {
        let subscriptionService = TestFeatureGatingSubscriptionService()
        subscriptionService.isPremium = false // Free user, but build config overrides

        buildConfigService = TestFeatureGatingBuildConfigService()
        buildConfigService.allFeaturesEnabledOverride = true

        let standardGating = DefaultFeatureGatingService(subscriptionService: subscriptionService)
        service = BuildConfigFeatureGatingService(
            buildConfigService: buildConfigService,
            standardFeatureGating: standardGating
        )
    }

    @Test("All features enabled grants unlimited habits to free user")
    func allFeaturesEnabled_grantsUnlimitedHabits() async {
        let maxHabits = await service.maxHabitsAllowed()

        #expect(maxHabits == Int.max)
    }

    @Test("All features enabled allows habit creation regardless of count")
    func allFeaturesEnabled_alwaysAllowsHabitCreation() async {
        #expect(await service.canCreateMoreHabits(currentCount: 0) == true)
        #expect(await service.canCreateMoreHabits(currentCount: 100) == true)
        #expect(await service.canCreateMoreHabits(currentCount: 1000) == true)
    }

    @Test("All features enabled grants advanced analytics to free user")
    func allFeaturesEnabled_grantsAdvancedAnalytics() async {
        let hasAnalytics = await service.hasAdvancedAnalytics()

        #expect(hasAnalytics == true)
    }

    @Test("All features enabled grants custom reminders to free user")
    func allFeaturesEnabled_grantsCustomReminders() async {
        let hasReminders = await service.hasCustomReminders()

        #expect(hasReminders == true)
    }

    @Test("All features enabled grants data export to free user")
    func allFeaturesEnabled_grantsDataExport() async {
        let hasExport = await service.hasDataExport()

        #expect(hasExport == true)
    }

    @Test("All features enabled grants all features to free user")
    func allFeaturesEnabled_grantsAllFeatures() async {
        for feature in FeatureType.allCases {
            let available = await service.isFeatureAvailable(feature)
            #expect(available == true, "\(feature) should be available when all features enabled")
        }
    }

    @Test("All features enabled never reports user as over limit")
    func allFeaturesEnabled_neverOverLimit() async {
        #expect(await service.isOverActiveHabitLimit(activeCount: 10) == false)
        #expect(await service.isOverActiveHabitLimit(activeCount: 100) == false)
    }

    @Test("All features enabled returns special blocked message")
    func allFeaturesEnabled_returnsSpecialMessage() {
        let message = service.getFeatureBlockedMessage(for: .unlimitedHabits)

        #expect(message.contains("enabled"))
    }
}

// MARK: - BuildConfigFeatureGatingService Tests - Subscription Based

@Suite("BuildConfigFeatureGatingService - Subscription Based", .tags(.businessLogic, .settings))
struct BuildConfigFeatureGatingServiceSubscriptionBasedTests {

    let buildConfigService: TestFeatureGatingBuildConfigService
    let subscriptionService: TestFeatureGatingSubscriptionService
    let service: BuildConfigFeatureGatingService

    init() {
        subscriptionService = TestFeatureGatingSubscriptionService()
        subscriptionService.isPremium = false // Free user

        buildConfigService = TestFeatureGatingBuildConfigService()
        buildConfigService.allFeaturesEnabledOverride = false // Subscription gating active

        let standardGating = DefaultFeatureGatingService(subscriptionService: subscriptionService)
        service = BuildConfigFeatureGatingService(
            buildConfigService: buildConfigService,
            standardFeatureGating: standardGating
        )
    }

    @Test("Subscription based delegates habit limit to standard service")
    func subscriptionBased_delegatesHabitLimit() async {
        let maxHabits = await service.maxHabitsAllowed()

        #expect(maxHabits == BusinessConstants.freeMaxHabits)
    }

    @Test("Subscription based delegates canCreateMoreHabits to standard service")
    func subscriptionBased_delegatesCanCreateHabits() async {
        #expect(await service.canCreateMoreHabits(currentCount: 4) == true)
        #expect(await service.canCreateMoreHabits(currentCount: 5) == false)
    }

    @Test("Subscription based delegates feature availability to standard service")
    func subscriptionBased_delegatesFeatureAvailability() async {
        for feature in FeatureType.allCases {
            let available = await service.isFeatureAvailable(feature)
            #expect(available == false, "\(feature) should not be available for free user with subscription gating")
        }
    }

    @Test("Subscription based delegates isOverActiveHabitLimit to standard service")
    func subscriptionBased_delegatesOverLimit() async {
        #expect(await service.isOverActiveHabitLimit(activeCount: 5) == false)
        #expect(await service.isOverActiveHabitLimit(activeCount: 6) == true)
    }

    @Test("Subscription based delegates blocked message to standard service")
    func subscriptionBased_delegatesBlockedMessage() {
        let message = service.getFeatureBlockedMessage(for: .unlimitedHabits)

        #expect(message.contains("5"))
        #expect(message.contains("Pro"))
    }
}

// MARK: - Feature Gating Edge Cases

@Suite("FeatureGatingService - Edge Cases", .tags(.businessLogic, .edgeCases))
struct FeatureGatingServiceEdgeCasesTests {

    @Test("Boundary condition: exactly at free limit")
    func boundaryCondition_exactlyAtFreeLimit() async {
        let subscriptionService = TestFeatureGatingSubscriptionService()
        subscriptionService.isPremium = false

        let service = DefaultFeatureGatingService(subscriptionService: subscriptionService)

        // At exactly 5 habits (the limit)
        let canCreate = await service.canCreateMoreHabits(currentCount: 5)
        let isOverLimit = await service.isOverActiveHabitLimit(activeCount: 5)

        // Cannot create more but not considered "over" the limit
        #expect(canCreate == false)
        #expect(isOverLimit == false)
    }

    @Test("Boundary condition: one under free limit")
    func boundaryCondition_oneUnderFreeLimit() async {
        let subscriptionService = TestFeatureGatingSubscriptionService()
        subscriptionService.isPremium = false

        let service = DefaultFeatureGatingService(subscriptionService: subscriptionService)

        // At 4 habits (one under limit)
        let canCreate = await service.canCreateMoreHabits(currentCount: 4)
        let isOverLimit = await service.isOverActiveHabitLimit(activeCount: 4)

        #expect(canCreate == true)
        #expect(isOverLimit == false)
    }

    @Test("Boundary condition: one over free limit")
    func boundaryCondition_oneOverFreeLimit() async {
        let subscriptionService = TestFeatureGatingSubscriptionService()
        subscriptionService.isPremium = false

        let service = DefaultFeatureGatingService(subscriptionService: subscriptionService)

        // At 6 habits (one over limit)
        let canCreate = await service.canCreateMoreHabits(currentCount: 6)
        let isOverLimit = await service.isOverActiveHabitLimit(activeCount: 6)

        #expect(canCreate == false)
        #expect(isOverLimit == true)
    }

    @Test("Premium status change affects feature availability")
    func premiumStatusChange_affectsFeatureAvailability() async {
        let subscriptionService = TestFeatureGatingSubscriptionService()
        let service = DefaultFeatureGatingService(subscriptionService: subscriptionService)

        // Start as free user
        subscriptionService.isPremium = false
        #expect(await service.hasAdvancedAnalytics() == false)
        #expect(await service.canCreateMoreHabits(currentCount: 10) == false)

        // Upgrade to premium
        subscriptionService.isPremium = true
        #expect(await service.hasAdvancedAnalytics() == true)
        #expect(await service.canCreateMoreHabits(currentCount: 10) == true)

        // Downgrade back to free
        subscriptionService.isPremium = false
        #expect(await service.hasAdvancedAnalytics() == false)
        #expect(await service.canCreateMoreHabits(currentCount: 10) == false)
    }

    @Test("Zero habit count always allows creation for free user")
    func zeroHabitCount_alwaysAllowsCreation() async {
        let subscriptionService = TestFeatureGatingSubscriptionService()
        subscriptionService.isPremium = false

        let service = DefaultFeatureGatingService(subscriptionService: subscriptionService)

        #expect(await service.canCreateMoreHabits(currentCount: 0) == true)
        #expect(await service.isOverActiveHabitLimit(activeCount: 0) == false)
    }
}

// MARK: - FeatureType Tests

@Suite("FeatureType - Display Names", .tags(.businessLogic))
struct FeatureTypeTests {

    @Test("All feature types have meaningful display names")
    func allFeatureTypes_haveMeaningfulDisplayNames() {
        for feature in FeatureType.allCases {
            let displayName = feature.displayName

            #expect(!displayName.isEmpty, "\(feature) should have a non-empty display name")
            #expect(displayName.count >= 5, "\(feature) should have a meaningful display name")
        }
    }

    @Test("FeatureType has expected cases")
    func featureType_hasExpectedCases() {
        let cases = FeatureType.allCases

        #expect(cases.contains(.unlimitedHabits))
        #expect(cases.contains(.advancedAnalytics))
        #expect(cases.contains(.customReminders))
        #expect(cases.contains(.dataExport))
        #expect(cases.count == 4)
    }
}
