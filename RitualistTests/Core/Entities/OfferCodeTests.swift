//
//  OfferCodeTests.swift
//  RitualistTests
//
//  Created on 2025-11-19
//  Tests for OfferCode domain entity validation logic
//

import Testing
import Foundation
@testable import RitualistCore

@Suite("OfferCode - Domain Entity Validation")
struct OfferCodeTests {

    // MARK: - Test Dates

    private var now: Date { Date() }
    private var pastDate: Date { Date().addingTimeInterval(-30 * 24 * 60 * 60) } // 30 days ago
    private var futureDate: Date { Date().addingTimeInterval(30 * 24 * 60 * 60) } // 30 days from now

    // MARK: - isExpired Tests

    @Test("Offer code is not expired when expiration date is nil")
    func offerCode_isExpired_whenNoExpirationDate_returnsFalse() async throws {
        // Arrange: Create code with no expiration date
        let code = OfferCode(
            id: "NOEXPIRY",
            displayName: "No Expiry Code",
            productId: StoreKitProductID.annual,
            offerType: .freeTrial,
            expirationDate: nil
        )

        // Assert
        #expect(code.isExpired == false, "Code with nil expiration date should not be expired")
    }

    @Test("Offer code is not expired when expiration date is in future")
    func offerCode_isExpired_whenFutureExpirationDate_returnsFalse() async throws {
        // Arrange: Create code expiring in 30 days
        let code = OfferCode(
            id: "FUTURE",
            displayName: "Future Expiry Code",
            productId: StoreKitProductID.annual,
            offerType: .freeTrial,
            expirationDate: futureDate
        )

        // Assert
        #expect(code.isExpired == false, "Code with future expiration date should not be expired")
    }

    @Test("Offer code is expired when expiration date is in past")
    func offerCode_isExpired_whenPastExpirationDate_returnsTrue() async throws {
        // Arrange: Create code that expired 30 days ago
        let code = OfferCode(
            id: "EXPIRED",
            displayName: "Expired Code",
            productId: StoreKitProductID.annual,
            offerType: .freeTrial,
            expirationDate: pastDate
        )

        // Assert
        #expect(code.isExpired == true, "Code with past expiration date should be expired")
    }

    // MARK: - isRedemptionLimitReached Tests

    @Test("Offer code is not at redemption limit when maxRedemptions is nil")
    func offerCode_isRedemptionLimitReached_whenNoLimit_returnsFalse() async throws {
        // Arrange: Create code with no redemption limit
        let code = OfferCode(
            id: "UNLIMITED",
            displayName: "Unlimited Code",
            productId: StoreKitProductID.annual,
            offerType: .freeTrial,
            maxRedemptions: nil,
            redemptionCount: 1000 // Even with high count, no limit means not reached
        )

        // Assert
        #expect(code.isRedemptionLimitReached == false, "Code with nil maxRedemptions should not reach limit")
    }

    @Test("Offer code is not at redemption limit when count is below max")
    func offerCode_isRedemptionLimitReached_whenBelowLimit_returnsFalse() async throws {
        // Arrange: Create code with limit 100, redeemed 50 times
        let code = OfferCode(
            id: "BELOWLIMIT",
            displayName: "Below Limit Code",
            productId: StoreKitProductID.annual,
            offerType: .freeTrial,
            maxRedemptions: 100,
            redemptionCount: 50
        )

        // Assert
        #expect(code.isRedemptionLimitReached == false, "Code below redemption limit should not be at limit")
    }

    @Test("Offer code is at redemption limit when count equals max")
    func offerCode_isRedemptionLimitReached_whenEqualsLimit_returnsTrue() async throws {
        // Arrange: Create code with limit 100, redeemed exactly 100 times
        let code = OfferCode(
            id: "ATLIMIT",
            displayName: "At Limit Code",
            productId: StoreKitProductID.annual,
            offerType: .freeTrial,
            maxRedemptions: 100,
            redemptionCount: 100
        )

        // Assert
        #expect(code.isRedemptionLimitReached == true, "Code at exact redemption limit should be at limit")
    }

    @Test("Offer code is at redemption limit when count exceeds max")
    func offerCode_isRedemptionLimitReached_whenExceedsLimit_returnsTrue() async throws {
        // Arrange: Create code with limit 100, redeemed 150 times
        let code = OfferCode(
            id: "OVERLIMIT",
            displayName: "Over Limit Code",
            productId: StoreKitProductID.annual,
            offerType: .freeTrial,
            maxRedemptions: 100,
            redemptionCount: 150
        )

        // Assert
        #expect(code.isRedemptionLimitReached == true, "Code over redemption limit should be at limit")
    }

    // MARK: - isValid Tests

    @Test("Offer code is valid when active, not expired, and under limit")
    func offerCode_isValid_whenActiveNotExpiredUnderLimit_returnsTrue() async throws {
        // Arrange: Create fully valid code
        let code = OfferCode(
            id: "VALID",
            displayName: "Valid Code",
            productId: StoreKitProductID.annual,
            offerType: .freeTrial,
            expirationDate: futureDate,
            isActive: true,
            maxRedemptions: 100,
            redemptionCount: 50
        )

        // Assert
        #expect(code.isValid == true, "Active code that's not expired and under limit should be valid")
    }

    @Test("Offer code is invalid when inactive")
    func offerCode_isValid_whenInactive_returnsFalse() async throws {
        // Arrange: Create inactive code (but not expired or at limit)
        let code = OfferCode(
            id: "INACTIVE",
            displayName: "Inactive Code",
            productId: StoreKitProductID.annual,
            offerType: .freeTrial,
            expirationDate: futureDate,
            isActive: false,
            maxRedemptions: 100,
            redemptionCount: 50
        )

        // Assert
        #expect(code.isValid == false, "Inactive code should not be valid even if not expired or at limit")
    }

    @Test("Offer code is invalid when expired")
    func offerCode_isValid_whenExpired_returnsFalse() async throws {
        // Arrange: Create expired code (but active and under limit)
        let code = OfferCode(
            id: "EXPIRED",
            displayName: "Expired Code",
            productId: StoreKitProductID.annual,
            offerType: .freeTrial,
            expirationDate: pastDate,
            isActive: true,
            maxRedemptions: 100,
            redemptionCount: 50
        )

        // Assert
        #expect(code.isValid == false, "Expired code should not be valid even if active and under limit")
    }

    @Test("Offer code is invalid when redemption limit reached")
    func offerCode_isValid_whenRedemptionLimitReached_returnsFalse() async throws {
        // Arrange: Create code at redemption limit (but active and not expired)
        let code = OfferCode(
            id: "LIMITREACHED",
            displayName: "Limit Reached Code",
            productId: StoreKitProductID.annual,
            offerType: .freeTrial,
            expirationDate: futureDate,
            isActive: true,
            maxRedemptions: 100,
            redemptionCount: 100
        )

        // Assert
        #expect(code.isValid == false, "Code at redemption limit should not be valid even if active and not expired")
    }

    @Test("Offer code is invalid when multiple conditions fail")
    func offerCode_isValid_whenMultipleFailures_returnsFalse() async throws {
        // Arrange: Create code that's inactive, expired, AND at limit
        let code = OfferCode(
            id: "MULTIPLEFAIL",
            displayName: "Multiple Failures Code",
            productId: StoreKitProductID.annual,
            offerType: .freeTrial,
            expirationDate: pastDate,
            isActive: false,
            maxRedemptions: 100,
            redemptionCount: 100
        )

        // Assert
        #expect(code.isValid == false, "Code with multiple failures should not be valid")
    }

    // MARK: - Edge Cases

    @Test("Offer code is valid with no expiration date and no redemption limit")
    func offerCode_isValid_whenNoExpirationAndNoLimit_returnsTrue() async throws {
        // Arrange: Create code with unlimited everything
        let code = OfferCode(
            id: "UNLIMITED",
            displayName: "Unlimited Code",
            productId: StoreKitProductID.annual,
            offerType: .freeTrial,
            expirationDate: nil,
            isActive: true,
            maxRedemptions: nil,
            redemptionCount: 9999 // High count shouldn't matter with no limit
        )

        // Assert
        #expect(code.isValid == true, "Active code with no expiration and no limit should be valid")
    }

    @Test("Offer code with zero max redemptions is invalid immediately")
    func offerCode_isValid_whenMaxRedemptionsZero_returnsFalse() async throws {
        // Arrange: Create code with max redemptions = 0
        let code = OfferCode(
            id: "ZEROMAX",
            displayName: "Zero Max Code",
            productId: StoreKitProductID.annual,
            offerType: .freeTrial,
            isActive: true,
            maxRedemptions: 0,
            redemptionCount: 0
        )

        // Assert
        #expect(code.isValid == false, "Code with maxRedemptions = 0 should be invalid (0 >= 0)")
    }

    // MARK: - statusDescription Tests

    @Test("Status description shows 'Inactive' for inactive code")
    func offerCode_statusDescription_whenInactive_showsInactive() async throws {
        // Arrange
        let code = OfferCode(
            id: "TEST",
            displayName: "Test",
            productId: StoreKitProductID.annual,
            offerType: .freeTrial,
            isActive: false
        )

        // Assert
        #expect(code.statusDescription == "Inactive", "Inactive code should show 'Inactive' status")
    }

    @Test("Status description shows 'Expired' for expired code")
    func offerCode_statusDescription_whenExpired_showsExpired() async throws {
        // Arrange
        let code = OfferCode(
            id: "TEST",
            displayName: "Test",
            productId: StoreKitProductID.annual,
            offerType: .freeTrial,
            expirationDate: pastDate,
            isActive: true
        )

        // Assert
        #expect(code.statusDescription == "Expired", "Expired code should show 'Expired' status")
    }

    @Test("Status description shows 'Limit Reached' when at limit")
    func offerCode_statusDescription_whenLimitReached_showsLimitReached() async throws {
        // Arrange
        let code = OfferCode(
            id: "TEST",
            displayName: "Test",
            productId: StoreKitProductID.annual,
            offerType: .freeTrial,
            isActive: true,
            maxRedemptions: 100,
            redemptionCount: 100
        )

        // Assert
        #expect(code.statusDescription == "Limit Reached", "Code at limit should show 'Limit Reached' status")
    }

    // MARK: - Discount Tests

    @Test("Percentage discount description shows correct format")
    func offerDiscount_description_percentage_showsCorrectFormat() async throws {
        // Arrange
        let discount = OfferCode.OfferDiscount(type: .percentage, value: 50, duration: 3)

        // Assert
        #expect(discount.description == "50% off for 3 billing cycle(s)", "Percentage discount should format correctly")
    }

    @Test("Fixed discount description shows correct format")
    func offerDiscount_description_fixed_showsCorrectFormat() async throws {
        // Arrange
        let discount = OfferCode.OfferDiscount(type: .fixed, value: 20.00, duration: 1)

        // Assert
        #expect(discount.description == "$20.00 off for 1 billing cycle(s)", "Fixed discount should format correctly")
    }

    @Test("Discount without duration shows no duration text")
    func offerDiscount_description_noDuration_omitsDurationText() async throws {
        // Arrange
        let discount = OfferCode.OfferDiscount(type: .percentage, value: 30, duration: nil)

        // Assert
        #expect(discount.description == "30% off", "Discount without duration should omit duration text")
    }
}
