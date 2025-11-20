//
//  DiscountVoucherFlowTests.swift
//  RitualistTests
//
//  Created on 2025-11-19
//  Tests for discount voucher redemption and purchase flow
//

import Testing
import Foundation
@testable import RitualistCore

@Suite("Discount Voucher Flow - End-to-End", .serialized)
struct DiscountVoucherFlowTests {

    // MARK: - Test Helpers

    /// Create a fresh service setup with clean state using isolated UserDefaults
    private func createService() async -> (MockPaywallService, MockOfferCodeStorageService, MockActiveDiscountService, MockSecureSubscriptionService) {
        // Create unique UserDefaults suite for this test class
        let testDefaults = UserDefaults(suiteName: "DiscountVoucherFlowTests")!

        // Clear the entire suite domain to ensure clean state
        testDefaults.removePersistentDomain(forName: "DiscountVoucherFlowTests")

        // Create services with isolated UserDefaults
        let storage = MockOfferCodeStorageService(userDefaults: testDefaults)
        await storage.loadDefaultTestCodes()

        let discountService = MockActiveDiscountService(userDefaults: testDefaults)
        let subscriptionService = MockSecureSubscriptionService(userDefaults: testDefaults)
        let paywallService = MockPaywallService(
            subscriptionService: subscriptionService,
            offerCodeStorage: storage,
            activeDiscountService: discountService,
            testingScenario: .alwaysSucceed  // Ensure purchases succeed
        )
        return (paywallService, storage, discountService, subscriptionService)
    }

    // MARK: - Discount Code Redemption Tests

    @Test("Redeem discount code stores ActiveDiscount (does not grant subscription)")
    func redeemDiscountCode_storesActiveDiscount_doesNotGrantSubscription() async throws {
        // Arrange
        let (paywallService, storage, discountService, subscriptionService) = await createService()

        // Get a discount code
        let codes = try await storage.getAllOfferCodes()
        let discountCode = try #require(
            codes.first(where: { $0.offerType == .discount && $0.isValid }),
            "No valid discount code found in default codes"
        )

        // Act
        let result = try await paywallService.redeemOfferCode(discountCode.id)

        // Assert
        #expect(result == true, "Redemption should succeed")
        #expect(subscriptionService.isPremiumUser() == false, "Discount codes should NOT grant subscription")

        // Verify ActiveDiscount was stored
        let activeDiscount = await discountService.getActiveDiscount(for: discountCode.productId)
        #expect(activeDiscount != nil, "ActiveDiscount should be stored")
        #expect(activeDiscount?.codeId == discountCode.id, "Stored discount should match redeemed code")
        #expect(activeDiscount?.productId == discountCode.productId, "Stored discount should match product")
    }

    @Test("Redeem discount code stores correct discount details")
    func redeemDiscountCode_storesCorrectDiscountDetails() async throws {
        // Arrange
        let (paywallService, storage, discountService, _) = await createService()

        // Get WELCOME50 - a 50% discount code
        let codes = try await storage.getAllOfferCodes()
        let discountCode = try #require(
            codes.first(where: { $0.id == "WELCOME50" }),
            "WELCOME50 code not found"
        )

        let expectedDiscount = try #require(
            discountCode.discount,
            "WELCOME50 should have discount configuration"
        )

        // Act
        _ = try await paywallService.redeemOfferCode(discountCode.id)

        // Assert
        let activeDiscount = await discountService.getActiveDiscount(for: discountCode.productId)
        #expect(activeDiscount?.discountType == expectedDiscount.type, "Discount type should match")
        #expect(activeDiscount?.discountValue == expectedDiscount.value, "Discount value should match")
        #expect(activeDiscount?.duration == expectedDiscount.duration, "Discount duration should match")
    }

    // MARK: - Purchase with Discount Tests

    @Test("Purchase with active discount clears the discount")
    func purchaseWithActiveDiscount_clearsDiscount() async throws {
        // Arrange
        let (paywallService, storage, discountService, _) = await createService()

        // Redeem a discount code
        let codes = try await storage.getAllOfferCodes()
        let discountCode = try #require(
            codes.first(where: { $0.offerType == .discount && $0.isValid }),
            "No valid discount code found"
        )

        _ = try await paywallService.redeemOfferCode(discountCode.id)

        // Verify discount is active
        let discountBefore = await discountService.getActiveDiscount(for: discountCode.productId)
        #expect(discountBefore != nil, "Discount should be active before purchase")

        // Create a product matching the discount
        let product = Product(
            id: discountCode.productId,
            name: "Test Product",
            description: "Test",
            price: "$9.99",
            localizedPrice: "$9.99/month",
            subscriptionPlan: .monthly,
            duration: .monthly,
            features: []
        )

        // Act - Purchase the product
        let result = try await paywallService.purchase(product)

        // Assert
        #expect(result == true, "Purchase should succeed")

        let discountAfter = await discountService.getActiveDiscount(for: discountCode.productId)
        #expect(discountAfter == nil, "Discount should be cleared after purchase")
    }

    @Test("Purchase without active discount succeeds normally")
    func purchaseWithoutDiscount_succeeds() async throws {
        // Arrange
        let (paywallService, _, discountService, subscriptionService) = await createService()

        // Verify no discount is active
        let product = Product(
            id: StoreKitProductID.monthly,
            name: "Monthly Plan",
            description: "Test",
            price: "$9.99",
            localizedPrice: "$9.99/month",
            subscriptionPlan: .monthly,
            duration: .monthly,
            features: []
        )

        let discountBefore = await discountService.getActiveDiscount(for: product.id)
        #expect(discountBefore == nil, "No discount should be active")

        // Act
        let result = try await paywallService.purchase(product)

        // Assert
        #expect(result == true, "Purchase should succeed without discount")
        #expect(subscriptionService.isPremiumUser() == true, "User should be premium after purchase")
    }

    // MARK: - Complete Flow Tests

    @Test("Complete discount voucher flow: redeem → purchase → verify")
    func completeDiscountFlow_worksEndToEnd() async throws {
        // Arrange
        let (paywallService, storage, discountService, subscriptionService) = await createService()

        // Get a discount code
        let codes = try await storage.getAllOfferCodes()
        let discountCode = try #require(
            codes.first(where: { $0.offerType == .discount && $0.isValid }),
            "No valid discount code found"
        )

        // Step 1: User is not premium initially
        #expect(subscriptionService.isPremiumUser() == false, "User should start as non-premium")

        // Step 2: Redeem discount code
        _ = try await paywallService.redeemOfferCode(discountCode.id)
        #expect(subscriptionService.isPremiumUser() == false, "Discount code should not grant subscription")

        let activeDiscount = await discountService.getActiveDiscount(for: discountCode.productId)
        #expect(activeDiscount != nil, "Discount should be active after redemption")

        // Step 3: Purchase the product
        let product = Product(
            id: discountCode.productId,
            name: "Test Product",
            description: "Test",
            price: "$9.99",
            localizedPrice: "$9.99/month",
            subscriptionPlan: .monthly,
            duration: .monthly,
            features: []
        )

        _ = try await paywallService.purchase(product)

        // Step 4: Verify final state
        #expect(subscriptionService.isPremiumUser() == true, "User should be premium after purchase")

        let discountAfter = await discountService.getActiveDiscount(for: discountCode.productId)
        #expect(discountAfter == nil, "Discount should be cleared after purchase")
    }

    @Test("Discount for wrong product does not affect purchase")
    func discountForWrongProduct_doesNotAffectPurchase() async throws {
        // Arrange
        let (paywallService, storage, discountService, _) = await createService()

        // Redeem a discount for monthly product
        let codes = try await storage.getAllOfferCodes()
        let monthlyDiscount = try #require(
            codes.first(where: {
                $0.offerType == .discount &&
                $0.isValid &&
                $0.productId == StoreKitProductID.monthly
            }),
            "No valid monthly discount code found"
        )

        _ = try await paywallService.redeemOfferCode(monthlyDiscount.id)

        // Verify discount is active for monthly
        let discount = await discountService.getActiveDiscount(for: StoreKitProductID.monthly)
        #expect(discount != nil, "Discount should be active for monthly product")

        // Act - Purchase annual product (different product)
        let annualProduct = Product(
            id: StoreKitProductID.annual,
            name: "Annual Plan",
            description: "Test",
            price: "$49.99",
            localizedPrice: "$49.99/year",
            subscriptionPlan: .annual,
            duration: .annual,
            features: []
        )

        let result = try await paywallService.purchase(annualProduct)

        // Assert
        #expect(result == true, "Purchase should succeed")

        // Discount should still be active for monthly (not cleared)
        let discountAfter = await discountService.getActiveDiscount(for: StoreKitProductID.monthly)
        #expect(discountAfter != nil, "Discount should remain for monthly product")
    }

    // MARK: - Price Calculation Tests

    @Test("ActiveDiscount calculates percentage discount correctly")
    func activeDiscount_calculatesPercentageCorrectly() async throws {
        // Arrange - 50% discount
        let discount = ActiveDiscount(
            codeId: "TEST50",
            productId: StoreKitProductID.monthly,
            discountType: .percentage,
            discountValue: 50,
            duration: 3
        )

        // Act
        let originalPrice = 9.99
        let discountedPrice = discount.calculateDiscountedPrice(originalPrice)

        // Assert - Use tolerance for floating-point comparison
        let expectedPrice = 4.995
        let tolerance = 0.001
        #expect(abs(discountedPrice - expectedPrice) < tolerance, "50% off $9.99 should be approximately $4.995")
    }

    @Test("ActiveDiscount calculates fixed discount correctly")
    func activeDiscount_calculatesFixedCorrectly() async throws {
        // Arrange - $20 off
        let discount = ActiveDiscount(
            codeId: "TWENTY",
            productId: StoreKitProductID.lifetime,
            discountType: .fixed,
            discountValue: 20.00,
            duration: nil
        )

        // Act
        let originalPrice = 100.00
        let discountedPrice = discount.calculateDiscountedPrice(originalPrice)

        // Assert - Use tolerance for floating-point comparison
        let expectedPrice = 80.00
        let tolerance = 0.001
        #expect(abs(discountedPrice - expectedPrice) < tolerance, "$20 off $100 should be approximately $80")
    }

    @Test("ActiveDiscount never produces negative price")
    func activeDiscount_neverProducesNegativePrice() async throws {
        // Arrange - $50 off a $10 product
        let discount = ActiveDiscount(
            codeId: "HUGE",
            productId: StoreKitProductID.monthly,
            discountType: .fixed,
            discountValue: 50.00,
            duration: 1
        )

        // Act
        let originalPrice = 10.00
        let discountedPrice = discount.calculateDiscountedPrice(originalPrice)

        // Assert - Use tolerance for floating-point comparison
        let expectedPrice = 0.0
        let tolerance = 0.001
        #expect(abs(discountedPrice - expectedPrice) < tolerance, "Discount should floor at approximately $0, not go negative")
    }
}
