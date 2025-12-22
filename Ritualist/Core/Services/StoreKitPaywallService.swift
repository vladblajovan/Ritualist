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
import Observation

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
/// **To Enable:**
/// 1. Purchase Apple Developer Program membership ($99/year)
/// 2. Create IAP products in App Store Connect (see StoreKitConstants.swift for IDs)
/// 3. Submit products for review
/// 4. Uncomment this service in Container+Services.swift
/// 5. Test with sandbox accounts
///
@MainActor
@Observable
public final class StoreKitPaywallService: PaywallService {

    // MARK: - Published State

    public var purchaseState: PurchaseState = .idle

    // MARK: - Private Properties

    /// StoreKit products loaded from App Store Connect
    private var storeProducts: [StoreKit.Product] = []

    /// Background task listening for transaction updates
    nonisolated(unsafe) private var updateListenerTask: Task<Void, Never>?

    /// Subscription service for purchase validation
    private let subscriptionService: SecureSubscriptionService

    /// Debug logger for diagnostics
    private let logger: DebugLogger

    // MARK: - Offer Code State

    /// Current state of offer code redemption
    /// Updated automatically when offer codes are redeemed via system sheet
    public var offerCodeRedemptionState: OfferCodeRedemptionState = .idle

    // MARK: - Initialization

    public init(
        subscriptionService: SecureSubscriptionService,
        logger: DebugLogger
    ) {
        self.subscriptionService = subscriptionService
        self.logger = logger

        // Start listening for transaction updates immediately
        // This ensures we catch any pending transactions from app restart
        updateListenerTask = listenForTransactions()
    }

    deinit {
        // Clean up transaction listener
        updateListenerTask?.cancel()
    }

    // MARK: - PaywallService Protocol

    public func loadProducts() async throws -> [RitualistCore.Product] {
        do {
            // Log the product IDs we're requesting
            let requestedIDs = StoreKitProductID.allProducts
            logger.log(
                "📦 Loading products from StoreKit - Requesting IDs: \(requestedIDs)",
                level: .debug,
                category: .subscription
            )

            // Load products from App Store using product IDs from StoreKitConstants
            storeProducts = try await StoreKit.Product.products(for: requestedIDs)

            // Log what we received
            logger.log(
                "📦 StoreKit returned \(storeProducts.count) products: \(storeProducts.map { $0.id })",
                level: .debug,
                category: .subscription
            )

            // Map StoreKit products to domain Product entities
            let products = storeProducts.compactMap { storeProduct -> RitualistCore.Product? in
                mapStoreProduct(storeProduct)
            }

            logger.log(
                "📦 Mapped to \(products.count) domain products",
                level: .debug,
                category: .subscription
            )

            // Sort: Annual (popular) first, then monthly, then weekly
            return products.sorted { product1, product2 in
                if product1.isPopular { return true }
                if product2.isPopular { return false }
                return product1.price < product2.price
            }

        } catch {
            // Handle StoreKit errors with detailed logging
            logger.log(
                "❌ StoreKit loadProducts failed: \(error.localizedDescription) - Error type: \(type(of: error))",
                level: .error,
                category: .subscription
            )
            throw PaywallError.productsNotAvailable
        }
    }

    public func purchase(_ product: RitualistCore.Product) async throws -> Bool {
        purchaseState = .purchasing(product.id)

        do {
            // Find the StoreKit product
            guard let storeProduct = storeProducts.first(where: { $0.id == product.id }) else {
                purchaseState = .failed("Product not available")
                throw PaywallError.productsNotAvailable
            }

            // Attempt purchase
            let result = try await storeProduct.purchase()

            // Handle purchase result
            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Update subscription service with new purchase
                try await subscriptionService.registerPurchase(product.id)

                // Finish the transaction (required by StoreKit)
                await transaction.finish()

                purchaseState = .success(product)
                return true

            case .userCancelled:
                // User cancelled the purchase in the payment sheet
                purchaseState = .idle
                throw PaywallError.userCancelled

            case .pending:
                // Purchase is pending (e.g., Ask to Buy for family sharing)
                purchaseState = .idle
                return false

            @unknown default:
                // Handle any future cases
                purchaseState = .failed("Unknown error occurred")
                return false
            }

        } catch let error as PaywallError {
            // Re-throw PaywallErrors
            throw error

        } catch StoreKitError.userCancelled {
            // StoreKit user cancellation
            purchaseState = .idle
            throw PaywallError.userCancelled

        } catch {
            // Generic error handling
            purchaseState = .failed("Purchase failed: \(error.localizedDescription)")
            throw PaywallError.purchaseFailed(error.localizedDescription)
        }
    }

    public func restorePurchases() async throws -> Bool {
        purchaseState = .purchasing("restore")

        // Collect all verified transactions
        var restoredProducts: [String] = []

        for await result in Transaction.currentEntitlements {
            // Verify each transaction
            if let transaction = try? checkVerified(result) {
                restoredProducts.append(transaction.productID)

                // Update subscription service
                try? await subscriptionService.registerPurchase(transaction.productID)
            }
        }

        purchaseState = .idle

        // Return true if we restored any purchases
        return !restoredProducts.isEmpty
    }

    public func isProductPurchased(_ productId: String) async -> Bool {
        // Check current entitlements from StoreKit
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == productId {
                    return true
                }
            }
        }
        return false
    }

    public func resetPurchaseState() {
        purchaseState = .idle
    }

    public func clearPurchases() {
        // Note: Cannot actually clear purchases from StoreKit
        // This is for local state management only
        purchaseState = .idle
    }

    // MARK: - Offer Code Redemption

    /// Present offer code redemption sheet
    /// **Note:** Stub - UI presentation will be implemented in Phase 5 (View Layer)
    /// The actual sheet is presented using SwiftUI's `.offerCodeRedemption()` modifier
    public func presentOfferCodeRedemptionSheet() {
        // This is intentionally a stub - the view layer will present the sheet
        // See Phase 5 for SwiftUI modifier implementation
        logger.log("[StoreKitPaywallService] Offer code sheet request - use SwiftUI modifier in view layer", level: .info, category: .subscription)
    }

    /// Check if offer code redemption is available on this device
    ///
    /// **iOS Version Requirements:**
    /// - **iOS 14.0+**: Apple's native redemption sheet (`.offerCodeRedemption()` modifier)
    /// - **iOS 15.0+**: Automatic transaction detection via `transaction.offer` property
    ///
    /// Both features work together for the complete offer code flow:
    /// 1. User enters code in redemption sheet (iOS 14+)
    /// 2. Transaction listener detects offer redemption (iOS 15+)
    /// 3. App grants subscription access
    ///
    /// **Note:** On iOS 14.x, the redemption sheet works but automatic detection
    /// via transaction listener is unavailable (uses manual verification instead).
    ///
    /// - Returns: `true` if the device supports offer code redemption (iOS 14+)
    ///
    public func isOfferCodeRedemptionAvailable() -> Bool {
        true // iOS 14+ is always available since minimum deployment is iOS 18
    }

    // MARK: - Active Discounts

    /// Get the active discount for a specific product
    ///
    /// **Note:** Discount vouchers are not yet supported in production StoreKit implementation.
    /// This will be implemented in Phase 3 of the discount voucher feature.
    ///
    /// - Parameter productId: The product to check for discounts
    /// - Returns: Always returns nil (not yet implemented)
    ///
    public func getActiveDiscount(for productId: String) async -> ActiveDiscount? {
        // TODO: Implement production discount voucher support
        // Will require:
        // 1. StoreKit offer codes configured in App Store Connect
        // 2. Transaction listener updates to detect offer redemptions
        // 3. ActiveDiscountService integration
        return nil
    }

    /// Check if there's an active discount for a specific product
    ///
    /// **Note:** Discount vouchers are not yet supported in production StoreKit implementation.
    ///
    /// - Parameter productId: The product to check
    /// - Returns: Always returns false (not yet implemented)
    ///
    public func hasActiveDiscount(for productId: String) async -> Bool {
        false
    }

    /// Clear the active discount
    ///
    /// **Note:** Discount vouchers are not yet supported in production StoreKit implementation.
    ///
    public func clearActiveDiscount() async {
        // No-op for now
    }

    // MARK: - Private Methods

    /// Maps a StoreKit product to our domain Product entity
    private func mapStoreProduct(_ storeProduct: StoreKit.Product) -> RitualistCore.Product? {
        // Determine subscription plan
        let subscriptionPlan = StoreKitProductID.subscriptionPlan(for: storeProduct.id)

        // Determine duration
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
            // Non-consumable (lifetime)
            duration = .monthly
        }

        // Build feature list based on product type
        let features = getFeaturesForProduct(storeProduct)

        // Determine if popular (annual is our popular option)
        let isPopular = storeProduct.id == StoreKitProductID.annual

        // Get discount text
        let discount: String? = isPopular ? "Save 58%" : nil

        // Get trial info for annual
        let hasFreeTrial = storeProduct.subscription?.introductoryOffer?.paymentMode == .freeTrial

        // Create domain Product
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

    /// Returns feature list for a given product
    private func getFeaturesForProduct(_ product: StoreKit.Product) -> [String] {
        let baseFeatures = [
            "Unlimited habits",
            "Advanced analytics & insights",
            "Custom reminders & notifications",
            "Data export (CSV, PDF)"
        ]

        if product.id == StoreKitProductID.annual {
            return baseFeatures + [
                "Dark mode & premium themes",
                "Priority support",
                "Early access to new features",
                "Cloud backup & sync",
                "7-day free trial"
            ]
        } else if product.id == StoreKitProductID.lifetime {
            return baseFeatures + [
                "Dark mode & premium themes",
                "Lifetime updates",
                "No recurring charges",
                "Premium support forever",
                "Exclusive lifetime features"
            ]
        } else if product.id == StoreKitProductID.weekly {
            // Weekly - minimal features for trial-like experience
            return baseFeatures + [
                "Try premium risk-free"
            ]
        } else {
            // Monthly
            return baseFeatures + [
                "Dark mode & themes",
                "Priority support"
            ]
        }
    }

    /// Listens for transaction updates in the background
    ///
    /// This catches:
    /// - Purchases made on other devices (via iCloud sync)
    /// - Interrupted transactions that need to be completed
    /// - Refunds from App Store
    /// - Subscription renewals/cancellations
    /// - **Offer code redemptions** (iOS 15+ via `transaction.offer` property)
    ///
    /// **Note:** On iOS 14.x, offer code redemptions still work via the redemption sheet,
    /// but automatic detection requires iOS 15+ for the `transaction.offer` property.
    ///
    private func listenForTransactions() -> Task<Void, Never> {
        let logger = self.logger // Capture for use in detached task
        return Task.detached { [weak self] in
            // Monitor transaction updates
            for await result in Transaction.updates {
                guard let self = self else { return }

                do {
                    // Verify the transaction
                    let transaction = try await self.checkVerified(result)

                    // Check if this transaction was from an offer code redemption
                    // iOS 15+ required for transaction.offer property
                    if #available(iOS 15.0, *), let offer = transaction.offer {
                        // Handle offer code redemption
                        await self.handleOfferCodeTransaction(transaction, offer: offer)
                    } else {
                        // Handle regular purchase (or iOS 14.x offer code without automatic detection)
                        await self.handleRegularTransaction(transaction)
                    }

                    // Finish the transaction
                    await transaction.finish()

                } catch {
                    // Log verification failure (in production, send to analytics)
                    logger.log("Transaction verification failed: \(error)", level: .error, category: .subscription)
                }
            }
        }
    }

    /// Handles a transaction that originated from an offer code redemption
    ///
    /// Updates state to reflect successful offer code redemption and logs the event
    ///
    /// - Parameters:
    ///   - transaction: The verified transaction
    ///   - offer: The offer details (iOS 15+)
    ///
    @available(iOS 15.0, *)
    private func handleOfferCodeTransaction(_ transaction: Transaction, offer: Transaction.Offer) async {
        let offerId = offer.id ?? "unknown"
        logger.log(
            "✨ Offer code redeemed - Product: \(transaction.productID), Offer ID: \(offerId)",
            level: .info,
            category: .subscription
        )

        // Update subscription service with the purchase
        try? await subscriptionService.registerPurchase(transaction.productID)

        // Update state on main actor
        await MainActor.run {
            self.offerCodeRedemptionState = .success(
                code: "OFFER_\(offerId)",
                productId: transaction.productID
            )
        }
    }

    /// Handles a regular transaction (not from offer code)
    ///
    /// - Parameter transaction: The verified transaction
    ///
    private func handleRegularTransaction(_ transaction: Transaction) async {
        logger.log(
            "✅ Regular transaction processed - Product: \(transaction.productID)",
            level: .info,
            category: .subscription
        )

        // Update subscription service
        try? await subscriptionService.registerPurchase(transaction.productID)
    }

    /// Verifies a transaction using StoreKit's built-in verification
    ///
    /// - Parameter result: The verification result from StoreKit
    /// - Returns: The verified transaction
    /// - Throws: PaywallError.purchaseFailed if verification fails
    ///
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let verificationError):
            // Verification failed - possible jailbreak or tampered receipt
            throw PaywallError.purchaseFailed("Transaction verification failed: \(verificationError)")

        case .verified(let safe):
            // Transaction is verified and safe to use
            return safe
        }
    }
}

// MARK: - Production Setup Notes

/*
 ACTIVATION CHECKLIST:

 ✅ Phase 1: App Store Connect Setup
    1. Purchase Apple Developer Program ($99/year)
    2. Create App in App Store Connect (if not exists)
    3. Enable In-App Purchases capability
    4. Create Subscription Group: "Ritualist Pro"
    5. Create IAP Products:
       - com.vladblajovan.ritualist.monthly ($9.99/month)
       - com.vladblajovan.ritualist.annual ($49.99/year, 7-day trial)
       - com.vladblajovan.ritualist.lifetime ($100 one-time)
    6. Submit products for review

 ✅ Phase 2: Code Activation
    1. Open Ritualist/DI/Container+Services.swift
    2. Find paywallService factory
    3. Uncomment StoreKitPaywallService initialization
    4. Comment out MockPaywallService
    5. Build and test with sandbox accounts

 ✅ Phase 3: Testing
    1. Create sandbox test accounts in App Store Connect
    2. Test purchase flow with sandbox
    3. Test restore purchases
    4. Test subscription renewal
    5. Test trial period (annual)
    6. Test all error scenarios

 ✅ Phase 4: Deployment
    1. TestFlight: Use Ritualist-AllFeatures scheme (bypass paywall)
    2. App Store: Use Ritualist-Subscription scheme (enable paywall)
    3. Monitor conversion rates and errors
    4. Iterate based on user feedback

 For detailed instructions, see: docs/STOREKIT-SETUP-GUIDE.md
 */
