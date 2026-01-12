//
//  StoreKitPaywallService.swift
//  Ritualist
//
//  Production StoreKit 2 implementation
//  Status: READY TO ENABLE - See docs/STOREKIT-SETUP-GUIDE.md
//

import Foundation
import StoreKit
import RitualistCore

/// Production StoreKit 2 paywall service
///
/// **STATUS:** Production-ready, fully implemented
/// **ACTIVATION:** See docs/STOREKIT-SETUP-GUIDE.md
///
/// This service provides complete StoreKit 2 integration for:
/// - Loading products from App Store Connect
/// - Purchasing subscriptions and non-consumables
/// - Restoring previous purchases
/// - Transaction verification and validation
/// - Subscription status monitoring
///
public actor StoreKitPaywallService: PaywallService {

    // MARK: - Private Properties

    /// StoreKit products loaded from App Store Connect
    private var storeProducts: [StoreKit.Product] = []

    /// Background task listening for transaction updates
    private var updateListenerTask: Task<Void, Never>?

    /// Subscription service for purchase validation
    private let subscriptionService: SecureSubscriptionService

    /// Debug logger for diagnostics
    private let logger: DebugLogger

    // MARK: - Initialization

    public init(
        subscriptionService: SecureSubscriptionService,
        logger: DebugLogger
    ) {
        self.subscriptionService = subscriptionService
        self.logger = logger

        // Start listening for transaction updates
        // Use Task to defer the assignment to after init completes
        Task { await self.startTransactionListener() }
    }

    private func startTransactionListener() {
        updateListenerTask = listenForTransactions()
    }

    // MARK: - PaywallService Protocol

    public func loadProducts() async throws -> [RitualistCore.Product] {
        do {
            let requestedIDs = StoreKitProductID.allProducts
            logger.log(
                "📦 Loading products from StoreKit - Requesting IDs: \(requestedIDs)",
                level: .debug,
                category: .subscription
            )

            storeProducts = try await StoreKit.Product.products(for: requestedIDs)

            logger.log(
                "📦 StoreKit returned \(storeProducts.count) products: \(storeProducts.map { $0.id })",
                level: .debug,
                category: .subscription
            )

            var products: [RitualistCore.Product] = []
            for storeProduct in storeProducts {
                if let product = await mapStoreProduct(storeProduct) {
                    products.append(product)
                }
            }

            return products.sorted { product1, product2 in
                if product1.isPopular { return true }
                if product2.isPopular { return false }
                return product1.price < product2.price
            }
        } catch {
            logger.log(
                "❌ StoreKit loadProducts failed: \(error.localizedDescription)",
                level: .error,
                category: .subscription
            )
            throw PaywallError.productsNotAvailable
        }
    }

    public func purchase(_ product: RitualistCore.Product) async throws -> PurchaseResult {
        do {
            guard let storeProduct = storeProducts.first(where: { $0.id == product.id }) else {
                throw PaywallError.productsNotAvailable
            }

            let result = try await storeProduct.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                try await subscriptionService.registerPurchase(product.id)
                await transaction.finish()
                return .success(product)

            case .userCancelled:
                return .cancelled

            case .pending:
                return .cancelled // Treat pending as not purchased for now

            @unknown default:
                return .failed("Unknown error occurred")
            }
        } catch let error as PaywallError {
            throw error
        } catch StoreKitError.userCancelled {
            return .cancelled
        } catch {
            throw PaywallError.purchaseFailed(error.localizedDescription)
        }
    }

    public func restorePurchases() async throws -> RestoreResult {
        var restoredProducts: [String] = []

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                restoredProducts.append(transaction.productID)
                try? await subscriptionService.registerPurchase(transaction.productID)
            }
        }

        if restoredProducts.isEmpty {
            return .noProductsToRestore
        }
        return .success(restoredProductIds: restoredProducts)
    }

    public func isProductPurchased(_ productId: String) async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == productId {
                    return true
                }
            }
        }
        return false
    }

    // MARK: - Private Methods

    private func mapStoreProduct(_ storeProduct: StoreKit.Product) async -> RitualistCore.Product? {
        let subscriptionPlan = StoreKitProductID.subscriptionPlan(for: storeProduct.id)

        let duration: ProductDuration
        if let subscription = storeProduct.subscription {
            switch subscription.subscriptionPeriod.unit {
            case .week:
                duration = .weekly
            case .month:
                duration = .monthly
            case .year:
                duration = .annual
            default:
                duration = .monthly
            }
        } else {
            duration = .monthly
        }

        let features = getFeaturesForProduct(storeProduct)
        let isPopular = storeProduct.id == StoreKitProductID.annual
        let discount: String? = isPopular ? await calculateAnnualDiscount(annualProduct: storeProduct) : nil
        let hasFreeTrial = storeProduct.subscription?.introductoryOffer?.paymentMode == .freeTrial

        return RitualistCore.Product(
            id: storeProduct.id,
            name: storeProduct.displayName,
            description: hasFreeTrial ?
                "\(storeProduct.description) • 7-day free trial" :
                storeProduct.description,
            price: storeProduct.price.description,
            localizedPrice: storeProduct.displayPrice,
            subscriptionPlan: subscriptionPlan,
            duration: duration,
            features: features,
            isPopular: isPopular,
            discount: discount
        )
    }

    /// Calculates the discount percentage for annual subscription compared to monthly
    /// Note: async because Strings.Paywall is MainActor-isolated and this actor
    /// has its own isolation domain (not MainActor).
    private func calculateAnnualDiscount(annualProduct: StoreKit.Product) async -> String {
        // Find the monthly product to compare prices
        guard let monthlyProduct = storeProducts.first(where: { $0.id == StoreKitProductID.monthly }) else {
            // Fallback marketing text when monthly product unavailable for comparison
            logger.log(
                "Monthly product unavailable for discount calculation - using fallback text",
                level: .warning,
                category: .subscription
            )
            return await MainActor.run { Strings.Paywall.discountFallback }
        }

        let annualPrice = annualProduct.price as Decimal
        let monthlyPrice = monthlyProduct.price as Decimal
        let yearlyMonthlyTotal = monthlyPrice * 12

        // Calculate savings percentage: (monthlyTotal - annual) / monthlyTotal * 100
        guard yearlyMonthlyTotal > 0 else {
            return await MainActor.run { Strings.Paywall.discountFallback }
        }
        let savings = (yearlyMonthlyTotal - annualPrice) / yearlyMonthlyTotal * 100
        let savingsPercent = Int(NSDecimalNumber(decimal: savings).doubleValue.rounded())

        guard savingsPercent > 0 else {
            return await MainActor.run { Strings.Paywall.discountFallback }
        }
        return await MainActor.run { Strings.Paywall.discountSavePercent(savingsPercent) }
    }

    private func getFeaturesForProduct(_ product: StoreKit.Product) -> [String] {
        let baseFeatures = [
            "Unlimited habits",
            "Advanced analytics & insights",
            "Custom reminders & notifications",
            "Data import & export"
        ]

        if product.id == StoreKitProductID.annual {
            return baseFeatures + [
                "Dark mode & premium themes",
                "Priority support",
                "Early access to new features",
                "Cloud backup & sync",
                "7-day free trial"
            ]
        } else if product.id == StoreKitProductID.weekly {
            return baseFeatures + ["Try premium risk-free"]
        } else {
            return baseFeatures + ["Dark mode & themes", "Priority support"]
        }
    }

    private nonisolated func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }

                do {
                    let transaction = try await self.checkVerified(result)

                    if #available(iOS 15.0, *), let offer = transaction.offer {
                        await self.handleOfferCodeTransaction(transaction, offer: offer)
                    } else {
                        await self.handleRegularTransaction(transaction)
                    }

                    await transaction.finish()
                } catch {
                    logger.log("Transaction verification failed: \(error)", level: .error, category: .subscription)
                }
            }
        }
    }

    @available(iOS 15.0, *)
    private func handleOfferCodeTransaction(_ transaction: Transaction, offer: Transaction.Offer) async {
        let offerId = offer.id ?? "unknown"
        logger.log(
            "✨ Offer code redeemed - Product: \(transaction.productID), Offer ID: \(offerId)",
            level: .info,
            category: .subscription
        )

        try? await subscriptionService.registerPurchase(transaction.productID)
    }

    private func handleRegularTransaction(_ transaction: Transaction) async {
        logger.log(
            "✅ Regular transaction processed - Product: \(transaction.productID)",
            level: .info,
            category: .subscription
        )

        try? await subscriptionService.registerPurchase(transaction.productID)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let verificationError):
            throw PaywallError.purchaseFailed("Transaction verification failed: \(verificationError)")
        case .verified(let safe):
            return safe
        }
    }
}
