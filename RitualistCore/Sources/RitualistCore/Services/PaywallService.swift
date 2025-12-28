//
//  PaywallService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//

import Foundation

/// Protocol for paywall business operations
/// This is a pure business service - no observable state, no @MainActor
/// UI state should be managed by the consuming ViewModel
public protocol PaywallService: Sendable {
    /// Load available products from the App Store
    func loadProducts() async throws -> [Product]

    /// Purchase a product
    /// - Returns: PurchaseResult indicating success, failure, or cancellation
    func purchase(_ product: Product) async throws -> PurchaseResult

    /// Restore previous purchases
    /// - Returns: RestoreResult with restored product IDs or failure
    func restorePurchases() async throws -> RestoreResult

    /// Check if a specific product is purchased
    func isProductPurchased(_ productId: String) async -> Bool
}

// MARK: - Mock Implementation

public actor MockPaywallService: PaywallService {
    // MARK: - Dependencies
    private let subscriptionService: SecureSubscriptionService

    // Mock products
    private let mockProducts: [Product] = [
        Product(
            id: "ritualist_weekly",
            name: "Ritualist Pro",
            description: "Weekly trial - Perfect to get started",
            price: "$2.99",
            localizedPrice: "$2.99/week",
            subscriptionPlan: .weekly,
            duration: .monthly,
            features: ["Unlimited habits", "Basic analytics", "Custom reminders"],
            isPopular: false
        ),
        Product(
            id: StoreKitProductID.monthly,
            name: "Ritualist Pro",
            description: "Most flexible option",
            price: "$9.99",
            localizedPrice: "$9.99/month",
            subscriptionPlan: .monthly,
            duration: .monthly,
            features: [
                "Unlimited habits",
                "Advanced analytics & insights",
                "Custom reminders & notifications",
                "Data import & export",
                "Dark mode & themes",
                "Priority support"
            ],
            isPopular: false
        ),
        Product(
            id: StoreKitProductID.annual,
            name: "Ritualist Pro",
            description: "Best value - Save 58%! Includes 7-day free trial",
            price: "$49.99",
            localizedPrice: "$49.99/year",
            subscriptionPlan: .annual,
            duration: .annual,
            features: [
                "Unlimited habits",
                "Advanced analytics & insights",
                "Custom reminders & notifications",
                "Data import & export",
                "Dark mode & premium themes",
                "Priority support",
                "Early access to new features",
                "Cloud backup & sync",
                "7-day free trial"
            ],
            isPopular: true,
            discount: "Save 58%"
        )
    ]

    // Testing configuration
    public var simulatePurchaseDelay: TimeInterval = 2.0
    public var simulateFailureRate: Double = 0.2

    public enum TestingScenario: Sendable {
        case alwaysSucceed
        case alwaysFail
        case randomResults
        case networkError
        case userCancellation
    }

    public var currentTestingScenario: TestingScenario = .randomResults

    private let logger = DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "paywall")

    public init(
        subscriptionService: SecureSubscriptionService,
        testingScenario: TestingScenario = .randomResults
    ) {
        self.subscriptionService = subscriptionService
        self.currentTestingScenario = testingScenario
    }

    public func loadProducts() async throws -> [Product] {
        #if ALL_FEATURES_ENABLED
        return []
        #else
        return mockProducts
        #endif
    }

    public func purchase(_ product: Product) async throws -> PurchaseResult {
        // Simulate delay
        try await Task.sleep(nanoseconds: UInt64(simulatePurchaseDelay * 1_000_000_000))

        // Determine outcome
        let shouldSucceed: Bool
        switch currentTestingScenario {
        case .alwaysSucceed:
            shouldSucceed = true
        case .alwaysFail:
            shouldSucceed = false
        case .randomResults:
            shouldSucceed = Double.random(in: 0...1) > simulateFailureRate
        case .networkError:
            throw PaywallError.networkError
        case .userCancellation:
            return .cancelled
        }

        if shouldSucceed {
            try await subscriptionService.registerPurchase(product.id)
            return .success(product)
        } else {
            let errorMessages = [
                "Purchase failed. Please try again.",
                "Payment processing failed.",
                "App Store connection timeout.",
                "Insufficient funds."
            ]
            return .failed(errorMessages.randomElement() ?? "Purchase failed")
        }
    }

    public func restorePurchases() async throws -> RestoreResult {
        try await Task.sleep(nanoseconds: UInt64(simulatePurchaseDelay * 0.75 * 1_000_000_000))

        switch currentTestingScenario {
        case .networkError:
            throw PaywallError.networkError
        case .alwaysFail:
            return .failed("Unable to restore purchases")
        default:
            let restoredPurchases = await subscriptionService.restorePurchases()
            if restoredPurchases.isEmpty {
                return .noProductsToRestore
            }
            return .success(restoredProductIds: restoredPurchases)
        }
    }

    public func isProductPurchased(_ productId: String) async -> Bool {
        await subscriptionService.validatePurchase(productId)
    }

    // MARK: - Testing Methods

    public func configure(scenario: TestingScenario, delay: TimeInterval = 2.0, failureRate: Double = 0.2) {
        currentTestingScenario = scenario
        simulatePurchaseDelay = delay
        simulateFailureRate = failureRate
    }
}

// MARK: - NoOp Implementation

public actor NoOpPaywallService: PaywallService {
    public init() {}

    public func loadProducts() async throws -> [Product] { [] }

    public func purchase(_ product: Product) async throws -> PurchaseResult { .cancelled }

    public func restorePurchases() async throws -> RestoreResult { .noProductsToRestore }

    public func isProductPurchased(_ productId: String) async -> Bool { false }
}
