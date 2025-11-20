//
//  MockPaywallServiceTests.swift
//  RitualistTests
//
//  Created on 2025-11-19
//  Tests for MockPaywallService offer code redemption flow
//

import Testing
import Foundation
@testable import RitualistCore

@Suite("MockPaywallService - Offer Code Redemption Flow", .serialized)
struct MockPaywallServiceTests {

    // MARK: - Test Helpers

    /// Create a fresh MockPaywallService with storage pre-loaded with default codes using isolated UserDefaults
    private func createService() async -> (MockPaywallService, MockOfferCodeStorageService, MockSecureSubscriptionService) {
        // Create unique UserDefaults suite for this test class
        let testDefaults = UserDefaults(suiteName: "MockPaywallServiceTests")!

        // Clear the entire suite domain to ensure clean state
        testDefaults.removePersistentDomain(forName: "MockPaywallServiceTests")

        // Create services with isolated UserDefaults
        let storage = MockOfferCodeStorageService(userDefaults: testDefaults)
        await storage.loadDefaultTestCodes()

        let subscriptionService = MockSecureSubscriptionService(userDefaults: testDefaults)
        let service = MockPaywallService(
            subscriptionService: subscriptionService,
            offerCodeStorage: storage
        )
        return (service, storage, subscriptionService)
    }

    /// Helper to get a valid test code from storage
    private func getValidTestCode(from storage: MockOfferCodeStorageService) async throws -> OfferCode {
        let codes = try await storage.getAllOfferCodes()
        // Get RITUALIST2025 - a valid new subscriber code
        guard let code = codes.first(where: { $0.id == "RITUALIST2025" }) else {
            throw PaywallError.offerCodeInvalid
        }
        return code
    }

    // MARK: - Successful Redemption Tests

    @Test("Redeem valid free trial offer code grants subscription and updates state")
    func redeemOfferCode_withValidCode_grantsSubscription() async throws {
        // Arrange
        let (service, storage, subscriptionService) = await createService()

        // Get a valid FREE TRIAL code (user is new, so new-subscriber-only codes are OK)
        // Note: NOT discount codes - those don't grant immediate subscriptions
        let codes = try await storage.getAllOfferCodes()
        guard let validCode = codes.first(where: { $0.isValid && $0.offerType == .freeTrial }) else {
            // If no free trial code exists, test with upgrade type
            guard let upgradeCode = codes.first(where: { $0.isValid && $0.offerType == .upgrade }) else {
                Issue.record("No valid free trial or upgrade code found in default codes")
                return
            }
            // Use upgrade code for testing
            let result = try await service.redeemOfferCode(upgradeCode.id)
            #expect(result == true, "Redemption should succeed")
            #expect(subscriptionService.isPremiumUser() == true, "User should be premium after redemption")
            return
        }

        // Act
        let result = try await service.redeemOfferCode(validCode.id)

        // Assert
        #expect(result == true, "Redemption should succeed")
        #expect(subscriptionService.isPremiumUser() == true, "User should be premium after redemption")

        // Verify state changed to success
        if case .success(let code, let productId) = service.offerCodeRedemptionState {
            #expect(code == validCode.id, "Success state should contain correct code")
            #expect(productId == validCode.productId, "Success state should contain correct product ID")
        } else {
            Issue.record("State should be .success after successful redemption")
        }
    }

    @Test("Redeem offer code records redemption in history")
    func redeemOfferCode_recordsRedemptionHistory() async throws {
        // Arrange
        let (service, storage, _) = await createService()
        let codes = try await storage.getAllOfferCodes()
        guard let validCode = codes.first(where: { $0.isValid && !$0.isNewSubscribersOnly }) else {
        Issue.record("No valid non-new-subscriber code found in default codes")
            return
        }

        // Ensure history is empty before test
        let initialHistory = try await storage.getRedemptionHistory()
        #expect(initialHistory.isEmpty, "History should be empty initially")

        // Act
        _ = try await service.redeemOfferCode(validCode.id)

        // Assert
        let history = try await storage.getRedemptionHistory()
        #expect(history.count == 1, "History should contain one redemption")
        #expect(history.first?.codeId == validCode.id, "History should record correct code ID")
        #expect(history.first?.productId == validCode.productId, "History should record correct product ID")
    }

    @Test("Redeem offer code increments redemption count")
    func redeemOfferCode_incrementsRedemptionCount() async throws {
        // Arrange
        let (service, storage, _) = await createService()
        let codes = try await storage.getAllOfferCodes()
        guard let validCode = codes.first(where: { $0.isValid && !$0.isNewSubscribersOnly }) else {
            Issue.record("No valid non-new-subscriber code found in default codes")
            return
        }
        let initialCount = validCode.redemptionCount

        // Act
        _ = try await service.redeemOfferCode(validCode.id)

        // Assert
        let updatedCode = try await storage.getOfferCode(validCode.id)
        #expect(updatedCode?.redemptionCount == initialCount + 1, "Redemption count should increment by 1")
    }

    // MARK: - Invalid Code Tests

    @Test("Redeem non-existent code throws error and updates state")
    func redeemOfferCode_withNonExistentCode_throwsError() async throws {
        // Arrange
        let (service, _, _) = await createService()
        let invalidCode = "DOESNOTEXIST123"

        // Act & Assert
        await #expect(throws: PaywallError.offerCodeInvalid) {
            try await service.redeemOfferCode(invalidCode)
        }

        // Verify state changed to failed with helpful message
        if case .failed(let message) = service.offerCodeRedemptionState {
            #expect(message.contains(invalidCode), "Error message should include the invalid code")
            #expect(message.contains("not found"), "Error message should indicate code not found")
        } else {
            Issue.record("State should be .failed after invalid code")
        }
    }

    @Test("Redeem invalid code does not grant subscription")
    func redeemOfferCode_withInvalidCode_doesNotGrantSubscription() async throws {
        // Arrange
        let (service, _, subscriptionService) = await createService()

        // Act
        _ = try? await service.redeemOfferCode("INVALID")

        // Assert
        #expect(subscriptionService.isPremiumUser() == false, "Invalid code should not grant premium access")
    }

    // MARK: - Expired Code Tests

    @Test("Redeem expired code throws error")
    func redeemOfferCode_withExpiredCode_throwsError() async throws {
        // Arrange
        let (service, storage, _) = await createService()

        // Get the expired test code
        let codes = try await storage.getAllOfferCodes()
        guard let expiredCode = codes.first(where: { $0.id == "EXPIRED2024" }) else {
            throw PaywallError.offerCodeInvalid
        }

        // Act & Assert
        await #expect(throws: PaywallError.offerCodeExpired) {
            try await service.redeemOfferCode(expiredCode.id)
        }

        // Verify state
        if case .failed(let message) = service.offerCodeRedemptionState {
            #expect(message.contains("expired"), "Error message should mention expiration")
        } else {
            Issue.record("State should be .failed for expired code")
        }
    }

    // MARK: - Redemption Limit Tests

    @Test("Redeem code at redemption limit throws error")
    func redeemOfferCode_atRedemptionLimit_throwsError() async throws {
        // Arrange
        let (service, storage, _) = await createService()

        // Get the limit reached test code
        let codes = try await storage.getAllOfferCodes()
        guard let limitCode = codes.first(where: { $0.id == "LIMITREACHED" }) else {
            throw PaywallError.offerCodeInvalid
        }

        // Verify it's actually at limit
        #expect(limitCode.isRedemptionLimitReached == true, "Test code should be at limit")

        // Act & Assert
        await #expect(throws: PaywallError.offerCodeRedemptionLimitReached) {
            try await service.redeemOfferCode(limitCode.id)
        }

        // Verify state
        if case .failed(let message) = service.offerCodeRedemptionState {
            #expect(message.contains("limit"), "Error message should mention limit")
        } else {
            Issue.record("State should be .failed for limit reached")
        }
    }

    // MARK: - Inactive Code Tests

    @Test("Redeem inactive code throws error")
    func redeemOfferCode_withInactiveCode_throwsError() async throws {
        // Arrange
        let (service, storage, _) = await createService()

        // Get the inactive test code
        let codes = try await storage.getAllOfferCodes()
        guard let inactiveCode = codes.first(where: { $0.id == "INACTIVE2025" }) else {
            throw PaywallError.offerCodeInvalid
        }

        // Verify it's actually inactive
        #expect(inactiveCode.isActive == false, "Test code should be inactive")

        // Act & Assert
        await #expect(throws: PaywallError.offerCodeInvalid) {
            try await service.redeemOfferCode(inactiveCode.id)
        }

        // Verify state
        if case .failed(let message) = service.offerCodeRedemptionState {
            #expect(message.contains("not active"), "Error message should mention inactive status")
        } else {
            Issue.record("State should be .failed for inactive code")
        }
    }

    // MARK: - New Subscribers Only Tests

    @Test("Redeem new-subscribers-only code when existing user throws error")
    func redeemOfferCode_newSubscribersOnly_whenExistingUser_throwsError() async throws {
        // Arrange
        let (service, storage, subscriptionService) = await createService()

        // Make user a premium user (existing subscriber)
        try await subscriptionService.mockPurchase(StoreKitProductID.monthly)
        #expect(subscriptionService.isPremiumUser() == true, "User should be premium")

        // Get a new-subscribers-only code
        let codes = try await storage.getAllOfferCodes()
        guard let newUserCode = codes.first(where: { $0.isNewSubscribersOnly && $0.isValid }) else {
            throw PaywallError.offerCodeInvalid
        }

        // Act & Assert
        await #expect(throws: PaywallError.offerCodeNotEligible) {
            try await service.redeemOfferCode(newUserCode.id)
        }

        // Verify state
        if case .failed(let message) = service.offerCodeRedemptionState {
            #expect(message.contains("new subscribers"), "Error message should mention eligibility")
        } else {
            Issue.record("State should be .failed for ineligible user")
        }
    }

    @Test("Redeem new-subscribers-only code when new user succeeds")
    func redeemOfferCode_newSubscribersOnly_whenNewUser_succeeds() async throws {
        // Arrange
        let (service, storage, subscriptionService) = await createService()

        // Ensure user is not premium
        #expect(subscriptionService.isPremiumUser() == false, "User should not be premium initially")

        // Get a new-subscribers-only code
        let codes = try await storage.getAllOfferCodes()
        guard let newUserCode = codes.first(where: { $0.isNewSubscribersOnly && $0.isValid }) else {
            throw PaywallError.offerCodeInvalid
        }

        // Act
        let result = try await service.redeemOfferCode(newUserCode.id)

        // Assert
        #expect(result == true, "Redemption should succeed for new user")
        #expect(subscriptionService.isPremiumUser() == true, "User should be premium after redemption")
    }

    // MARK: - Already Redeemed Tests

    @Test("Redeem code twice throws already redeemed error")
    func redeemOfferCode_alreadyRedeemed_throwsError() async throws {
        // Arrange
        let (service, storage, _) = await createService()
        let codes = try await storage.getAllOfferCodes()
        guard let validCode = codes.first(where: { $0.isValid && !$0.isNewSubscribersOnly }) else {
            Issue.record("No valid non-new-subscriber code found in default codes")
            return
        }

        // First redemption (should succeed)
        _ = try await service.redeemOfferCode(validCode.id)

        // Reset state for second attempt
        service.offerCodeRedemptionState = .idle

        // Act & Assert - Second redemption should fail
        await #expect(throws: PaywallError.offerCodeAlreadyRedeemed) {
            try await service.redeemOfferCode(validCode.id)
        }

        // Verify state
        if case .failed(let message) = service.offerCodeRedemptionState {
            #expect(message.contains("Already redeemed"), "Error message should indicate already redeemed")
        } else {
            Issue.record("State should be .failed for already redeemed code")
        }
    }

    // MARK: - State Management Tests

    @Test("Redemption state transitions correctly during flow")
    func redeemOfferCode_stateTransitions_areCorrect() async throws {
        // Arrange
        let (service, storage, _) = await createService()
        let codes = try await storage.getAllOfferCodes()
        guard let validCode = codes.first(where: { $0.isValid && !$0.isNewSubscribersOnly }) else {
            Issue.record("No valid non-new-subscriber code found in default codes")
            return
        }

        // Initial state
        #expect(service.offerCodeRedemptionState == .idle, "State should start as idle")

        // Act - Start redemption (don't await completion yet)
        Task {
            // State should transition through validating → redeeming → success
            try await service.redeemOfferCode(validCode.id)
        }

        // Give it a moment to start validating
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Assert - Should be in validating or redeeming state
        switch service.offerCodeRedemptionState {
        case .validating, .redeeming:
            break // Expected during redemption
        case .success:
            break // Also acceptable if it completed quickly
        default:
            Issue.record("State should be validating, redeeming, or success during redemption")
        }

        // Wait for completion
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds (enough for full flow)

        // Final state should be success
        if case .success = service.offerCodeRedemptionState {
            // Success
        } else {
            Issue.record("Final state should be .success after successful redemption")
        }
    }

    @Test("Case-insensitive code matching works")
    func redeemOfferCode_caseInsensitive_succeeds() async throws {
        // Arrange
        let (service, storage, _) = await createService()
        let codes = try await storage.getAllOfferCodes()
        guard let validCode = codes.first(where: { $0.isValid && !$0.isNewSubscribersOnly }) else {
            Issue.record("No valid non-new-subscriber code found in default codes")
            return
        }

        // Act - Try redeeming with lowercase version
        let lowercaseCode = validCode.id.lowercased()
        let result = try await service.redeemOfferCode(lowercaseCode)

        // Assert
        #expect(result == true, "Redemption should succeed with lowercase code")
    }

    // MARK: - Integration Tests

    @Test("Complete free trial redemption flow updates all related state")
    func redeemOfferCode_completeFlow_updatesAllState() async throws {
        // Arrange
        let (service, storage, subscriptionService) = await createService()
        let codes = try await storage.getAllOfferCodes()

        // Get a FREE TRIAL code (user is new, so new-subscriber-only codes are OK)
        // Note: NOT discount codes - those don't grant subscriptions
        guard let validCode = codes.first(where: { $0.isValid && $0.offerType == .freeTrial }) else {
            // Try upgrade type as fallback
            guard let upgradeCode = codes.first(where: { $0.isValid && $0.offerType == .upgrade }) else {
                Issue.record("No valid free trial or upgrade code found in default codes")
                return
            }
            // Use upgrade code for this test
            let initialHistory = try await storage.getRedemptionHistory()
            let initialCount = upgradeCode.redemptionCount
            _ = try await service.redeemOfferCode(upgradeCode.id)
            #expect(subscriptionService.isPremiumUser() == true, "User should be premium")
            let finalHistory = try await storage.getRedemptionHistory()
            #expect(finalHistory.count == initialHistory.count + 1, "History should have one more entry")
            return
        }

        // Capture initial state
        let initialHistory = try await storage.getRedemptionHistory()
        let initialCount = validCode.redemptionCount
        let initialPremiumStatus = subscriptionService.isPremiumUser()

        // Act
        _ = try await service.redeemOfferCode(validCode.id)

        // Assert - Verify all state changes
        // 1. User is now premium (for free trial codes)
        #expect(subscriptionService.isPremiumUser() == true, "User should be premium")
        #expect(subscriptionService.isPremiumUser() != initialPremiumStatus, "Premium status should change")

        // 2. History recorded
        let finalHistory = try await storage.getRedemptionHistory()
        #expect(finalHistory.count == initialHistory.count + 1, "History should have one more entry")

        // 3. Redemption count incremented
        let updatedCode = try await storage.getOfferCode(validCode.id)
        #expect(updatedCode?.redemptionCount == initialCount + 1, "Count should increment")

        // 4. Service state is success
        if case .success = service.offerCodeRedemptionState {
            // Success
        } else {
            Issue.record("Service state should be success")
        }
    }
}
