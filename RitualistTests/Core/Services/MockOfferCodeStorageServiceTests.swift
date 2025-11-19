//
//  MockOfferCodeStorageServiceTests.swift
//  RitualistTests
//
//  Created on 2025-11-19
//  Tests for MockOfferCodeStorageService CRUD operations
//

import Testing
import Foundation
@testable import RitualistCore

@Suite("MockOfferCodeStorageService - CRUD Operations")
struct MockOfferCodeStorageServiceTests {

    // MARK: - Test Helpers

    /// Create a service with empty storage (deterministic, no async loading)
    private func createEmptyService() -> MockOfferCodeStorageService {
        MockOfferCodeStorageService()
    }

    /// Create a service with default test codes pre-loaded
    private func createServiceWithDefaults() async -> MockOfferCodeStorageService {
        let service = MockOfferCodeStorageService()
        await service.loadDefaultTestCodes()
        return service
    }

    /// Create a test offer code
    private func createTestCode(
        id: String = "TEST123",
        productId: String = StoreKitProductID.annual,
        isActive: Bool = true,
        expirationDate: Date? = nil
    ) -> OfferCode {
        OfferCode(
            id: id,
            displayName: "Test Code",
            productId: productId,
            offerType: .freeTrial,
            expirationDate: expirationDate,
            isActive: isActive
        )
    }

    // MARK: - Initialization Tests

    @Test("Service can load default test codes")
    func service_initialization_loadsDefaultCodes() async throws {
        // Arrange
        let service = createEmptyService()

        // Act
        await service.loadDefaultTestCodes()

        // Assert
        let codes = try await service.getAllOfferCodes()
        #expect(codes.count > 0, "Service should load default test codes")

        // Verify some expected default codes
        let codeIds = codes.map { $0.id }
        #expect(codeIds.contains("RITUALIST2025"), "Should include RITUALIST2025 code")
        #expect(codeIds.contains("WELCOME50"), "Should include WELCOME50 code")
        #expect(codeIds.contains("ANNUAL30"), "Should include ANNUAL30 code")
    }

    @Test("Service provides various test code types")
    func service_defaultCodes_includeVariousTypes() async throws {
        // Arrange
        let service = await createServiceWithDefaults()

        // Act
        let codes = try await service.getAllOfferCodes()

        // Assert - Verify different code types exist
        let hasFreeTrial = codes.contains { $0.offerType == .freeTrial }
        let hasDiscount = codes.contains { $0.offerType == .discount }
        let hasExpired = codes.contains { $0.isExpired }
        let hasLimitReached = codes.contains { $0.isRedemptionLimitReached }
        let hasInactive = codes.contains { !$0.isActive }

        #expect(hasFreeTrial, "Should include free trial codes")
        #expect(hasDiscount, "Should include discount codes")
        #expect(hasExpired, "Should include expired codes for testing")
        #expect(hasLimitReached, "Should include limit-reached codes for testing")
        #expect(hasInactive, "Should include inactive codes for testing")
    }

    // MARK: - Get All Codes Tests

    @Test("Get all codes returns empty array when no codes exist")
    func getAllOfferCodes_whenEmpty_returnsEmptyArray() async throws {
        // Arrange
        let service = createEmptyService()

        // Act
        let codes = try await service.getAllOfferCodes()

        // Assert
        #expect(codes.isEmpty, "Should return empty array when no codes exist")
    }

    @Test("Get all codes returns all saved codes")
    func getAllOfferCodes_returnsSavedCodes() async throws {
        // Arrange
        let service = createEmptyService()

        let code1 = createTestCode(id: "CODE1")
        let code2 = createTestCode(id: "CODE2")
        let code3 = createTestCode(id: "CODE3")

        try await service.saveOfferCode(code1)
        try await service.saveOfferCode(code2)
        try await service.saveOfferCode(code3)

        // Act
        let codes = try await service.getAllOfferCodes()

        // Assert
        #expect(codes.count == 3, "Should return all 3 saved codes")
        let codeIds = codes.map { $0.id }
        #expect(codeIds.contains("CODE1"), "Should include CODE1")
        #expect(codeIds.contains("CODE2"), "Should include CODE2")
        #expect(codeIds.contains("CODE3"), "Should include CODE3")
    }

    // MARK: - Get Offer Code Tests

    @Test("Get offer code returns nil when code doesn't exist")
    func getOfferCode_whenNotExists_returnsNil() async throws {
        // Arrange
        let service = createEmptyService()

        // Act
        let code = try await service.getOfferCode("DOESNOTEXIST")

        // Assert
        #expect(code == nil, "Should return nil for non-existent code")
    }

    @Test("Get offer code returns code when exists")
    func getOfferCode_whenExists_returnsCode() async throws {
        // Arrange
        let service = createEmptyService()

        let testCode = createTestCode(id: "FINDME")
        try await service.saveOfferCode(testCode)

        // Act
        let retrievedCode = try await service.getOfferCode("FINDME")

        // Assert
        #expect(retrievedCode != nil, "Should return the code")
        #expect(retrievedCode?.id == "FINDME", "Should return correct code")
        #expect(retrievedCode?.displayName == testCode.displayName, "Should match saved code")
    }

    @Test("Get offer code is case-insensitive")
    func getOfferCode_caseInsensitive_findsCode() async throws {
        // Arrange
        let service = createEmptyService()

        let testCode = createTestCode(id: "UPPERCASE")
        try await service.saveOfferCode(testCode)

        // Act - Try lowercase, mixed case
        let lowercase = try await service.getOfferCode("uppercase")
        let mixedCase = try await service.getOfferCode("UpPeRcAsE")

        // Assert
        #expect(lowercase != nil, "Should find code with lowercase")
        #expect(lowercase?.id == "UPPERCASE", "Should return correct code")
        #expect(mixedCase != nil, "Should find code with mixed case")
        #expect(mixedCase?.id == "UPPERCASE", "Should return correct code")
    }

    // MARK: - Save Offer Code Tests

    @Test("Save offer code creates new code")
    func saveOfferCode_createsNewCode() async throws {
        // Arrange
        let service = createEmptyService()

        let newCode = createTestCode(id: "NEWCODE")

        // Act
        try await service.saveOfferCode(newCode)

        // Assert
        let codes = try await service.getAllOfferCodes()
        #expect(codes.count == 1, "Should have one code")
        #expect(codes.first?.id == "NEWCODE", "Should be the saved code")
    }

    @Test("Save offer code updates existing code")
    func saveOfferCode_updatesExistingCode() async throws {
        // Arrange
        let service = createEmptyService()

        // Save initial code
        let originalCode = createTestCode(id: "UPDATE", productId: StoreKitProductID.monthly)
        try await service.saveOfferCode(originalCode)

        // Act - Save updated version with different product ID
        let updatedCode = OfferCode(
            id: "UPDATE",
            displayName: "Updated Display Name",
            productId: StoreKitProductID.annual, // Changed
            offerType: .discount, // Changed
            isActive: false // Changed
        )
        try await service.saveOfferCode(updatedCode)

        // Assert
        let codes = try await service.getAllOfferCodes()
        #expect(codes.count == 1, "Should still have only one code")
        guard let retrievedCode = codes.first else {
            Issue.record("Should have retrieved the updated code")
            return
        }
        #expect(retrievedCode.id == "UPDATE", "Should be same code ID")
        #expect(retrievedCode.displayName == "Updated Display Name", "Should have updated name")
        #expect(retrievedCode.productId == StoreKitProductID.annual, "Should have updated product ID")
        #expect(retrievedCode.offerType == .discount, "Should have updated type")
        #expect(retrievedCode.isActive == false, "Should have updated active status")
    }

    @Test("Save multiple codes persists all codes")
    func saveOfferCode_multipleCodes_persistsAll() async throws {
        // Arrange
        let service = createEmptyService()

        // Act - Save multiple codes
        for i in 1...10 {
            let code = createTestCode(id: "CODE\(i)")
            try await service.saveOfferCode(code)
        }

        // Assert
        let codes = try await service.getAllOfferCodes()
        #expect(codes.count == 10, "Should have all 10 codes")
    }

    // MARK: - Delete Offer Code Tests

    @Test("Delete offer code removes code from storage")
    func deleteOfferCode_removesCode() async throws {
        // Arrange
        let service = createEmptyService()

        let code = createTestCode(id: "DELETE_ME")
        try await service.saveOfferCode(code)

        // Verify it exists
        var codes = try await service.getAllOfferCodes()
        #expect(codes.count == 1, "Code should exist")

        // Act
        try await service.deleteOfferCode("DELETE_ME")

        // Assert
        codes = try await service.getAllOfferCodes()
        #expect(codes.isEmpty, "Code should be deleted")
    }

    @Test("Delete non-existent code doesn't throw error")
    func deleteOfferCode_nonExistent_doesNotThrow() async throws {
        // Arrange
        let service = createEmptyService()

        // Act & Assert - Should not throw
        try await service.deleteOfferCode("DOESNOTEXIST")

        // Verify storage is still empty
        let codes = try await service.getAllOfferCodes()
        #expect(codes.isEmpty, "Storage should remain empty")
    }

    @Test("Delete code doesn't affect other codes")
    func deleteOfferCode_doesNotAffectOtherCodes() async throws {
        // Arrange
        let service = createEmptyService()

        try await service.saveOfferCode(createTestCode(id: "KEEP1"))
        try await service.saveOfferCode(createTestCode(id: "DELETE"))
        try await service.saveOfferCode(createTestCode(id: "KEEP2"))

        // Act
        try await service.deleteOfferCode("DELETE")

        // Assert
        let codes = try await service.getAllOfferCodes()
        #expect(codes.count == 2, "Should have 2 remaining codes")
        let codeIds = codes.map { $0.id }
        #expect(codeIds.contains("KEEP1"), "KEEP1 should remain")
        #expect(codeIds.contains("KEEP2"), "KEEP2 should remain")
        #expect(!codeIds.contains("DELETE"), "DELETE should be removed")
    }

    // MARK: - Increment Redemption Count Tests

    @Test("Increment redemption count increases count by 1")
    func incrementRedemptionCount_increasesCountByOne() async throws {
        // Arrange
        let service = createEmptyService()

        let code = createTestCode(id: "INCREMENT")
        try await service.saveOfferCode(code)

        let initialCode = try await service.getOfferCode("INCREMENT")
        let initialCount = initialCode?.redemptionCount ?? 0

        // Act
        try await service.incrementRedemptionCount("INCREMENT")

        // Assert
        let updatedCode = try await service.getOfferCode("INCREMENT")
        #expect(updatedCode?.redemptionCount == initialCount + 1, "Count should increase by 1")
    }

    @Test("Increment redemption count multiple times accumulates")
    func incrementRedemptionCount_multipleTimes_accumulates() async throws {
        // Arrange
        let service = createEmptyService()

        let code = createTestCode(id: "MULTI_INCREMENT")
        try await service.saveOfferCode(code)

        let initialCount = 0

        // Act - Increment 5 times
        for _ in 1...5 {
            try await service.incrementRedemptionCount("MULTI_INCREMENT")
        }

        // Assert
        let updatedCode = try await service.getOfferCode("MULTI_INCREMENT")
        #expect(updatedCode?.redemptionCount == initialCount + 5, "Count should increase by 5")
    }

    @Test("Increment non-existent code throws error")
    func incrementRedemptionCount_nonExistent_throwsError() async throws {
        // Arrange
        let service = createEmptyService()

        // Act & Assert
        await #expect(throws: PaywallError.offerCodeInvalid) {
            try await service.incrementRedemptionCount("DOESNOTEXIST")
        }
    }

    // MARK: - Redemption History Tests

    @Test("Get redemption history returns empty when no redemptions")
    func getRedemptionHistory_whenEmpty_returnsEmpty() async throws {
        // Arrange
        let service = createService()
        await service.clearRedemptionHistory()

        // Act
        let history = try await service.getRedemptionHistory()

        // Assert
        #expect(history.isEmpty, "History should be empty initially")
    }

    @Test("Record redemption adds to history")
    func recordRedemption_addsToHistory() async throws {
        // Arrange
        let service = createService()
        await service.clearRedemptionHistory()

        let redemption = OfferCodeRedemption(
            codeId: "TEST123",
            productId: StoreKitProductID.annual
        )

        // Act
        try await service.recordRedemption(redemption)

        // Assert
        let history = try await service.getRedemptionHistory()
        #expect(history.count == 1, "History should have one entry")
        #expect(history.first?.codeId == "TEST123", "Should record correct code ID")
        #expect(history.first?.productId == StoreKitProductID.annual, "Should record correct product ID")
    }

    @Test("Record multiple redemptions preserves all entries")
    func recordRedemption_multiple_preservesAll() async throws {
        // Arrange
        let service = createService()
        await service.clearRedemptionHistory()

        // Act - Record 3 redemptions
        for i in 1...3 {
            let redemption = OfferCodeRedemption(
                codeId: "CODE\(i)",
                productId: StoreKitProductID.annual
            )
            try await service.recordRedemption(redemption)
        }

        // Assert
        let history = try await service.getRedemptionHistory()
        #expect(history.count == 3, "History should have 3 entries")

        let codeIds = history.map { $0.codeId }
        #expect(codeIds.contains("CODE1"), "Should include CODE1")
        #expect(codeIds.contains("CODE2"), "Should include CODE2")
        #expect(codeIds.contains("CODE3"), "Should include CODE3")
    }

    // MARK: - Statistics Tests

    @Test("Statistics shows correct counts")
    func getStatistics_showsCorrectCounts() async throws {
        // Arrange
        let service = createEmptyService()

        // Add various codes
        let activeValid = createTestCode(id: "ACTIVE", isActive: true)
        let inactiveCode = createTestCode(id: "INACTIVE", isActive: false)
        let expiredCode = createTestCode(
            id: "EXPIRED",
            expirationDate: Date().addingTimeInterval(-30 * 24 * 60 * 60)
        )

        try await service.saveOfferCode(activeValid)
        try await service.saveOfferCode(inactiveCode)
        try await service.saveOfferCode(expiredCode)

        // Act
        let stats = await service.getStatistics()

        // Assert
        #expect(stats.totalCodes == 3, "Should count all codes")
        #expect(stats.activeCodes == 2, "Should count active codes (2 out of 3)")
        #expect(stats.expiredCodes == 1, "Should count expired codes")
        #expect(stats.validCodes >= 1, "Should have at least one valid code")
    }

    // MARK: - Helper Methods Tests

    @Test("Load default test codes populates storage")
    func loadDefaultTestCodes_populatesStorage() async throws {
        // Arrange
        let service = createEmptyService()

        // Verify empty
        var codes = try await service.getAllOfferCodes()
        #expect(codes.isEmpty, "Should be empty initially")

        // Act
        await service.loadDefaultTestCodes()

        // Assert
        codes = try await service.getAllOfferCodes()
        #expect(codes.count > 0, "Should have default codes")
        #expect(codes.count == MockOfferCodeStorageService.defaultTestCodes.count,
                "Should load all default codes")
    }

    @Test("Clear all codes removes all codes")
    func clearAllCodes_removesAllCodes() async throws {
        // Arrange
        let service = createService()
        await service.loadDefaultTestCodes()

        // Verify codes exist
        var codes = try await service.getAllOfferCodes()
        #expect(codes.count > 0, "Should have codes")

        // Act
        await service.clearAllCodes()

        // Assert
        codes = try await service.getAllOfferCodes()
        #expect(codes.isEmpty, "Should be empty after clear")
    }

    @Test("Clear redemption history removes all history")
    func clearRedemptionHistory_removesAllHistory() async throws {
        // Arrange
        let service = createService()

        // Add some history
        for i in 1...3 {
            let redemption = OfferCodeRedemption(codeId: "CODE\(i)", productId: StoreKitProductID.annual)
            try await service.recordRedemption(redemption)
        }

        var history = try await service.getRedemptionHistory()
        #expect(history.count == 3, "Should have history")

        // Act
        await service.clearRedemptionHistory()

        // Assert
        history = try await service.getRedemptionHistory()
        #expect(history.isEmpty, "History should be empty")
    }

    @Test("Reset to defaults clears everything and loads defaults")
    func resetToDefaults_clearsAndLoadsDefaults() async throws {
        // Arrange
        let service = createService()

        // Add custom code and history
        try await service.saveOfferCode(createTestCode(id: "CUSTOM"))
        try await service.recordRedemption(
            OfferCodeRedemption(codeId: "TEST", productId: StoreKitProductID.annual)
        )

        // Act
        await service.resetToDefaults()

        // Assert
        let codes = try await service.getAllOfferCodes()
        let history = try await service.getRedemptionHistory()

        #expect(codes.count == MockOfferCodeStorageService.defaultTestCodes.count,
                "Should have default codes")
        #expect(history.isEmpty, "History should be cleared")
        #expect(!codes.contains { $0.id == "CUSTOM" }, "Custom code should be removed")
    }
}
