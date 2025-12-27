import Foundation
import FactoryKit
import RitualistCore

@MainActor @Observable
public final class PaywallViewModel {
    private let loadPaywallProducts: LoadPaywallProductsUseCase
    private let purchaseProduct: PurchaseProductUseCase
    private let restorePurchasesUseCase: RestorePurchasesUseCase
    private let checkProductPurchased: CheckProductPurchasedUseCase
    private let errorHandler: ErrorHandler?
    @ObservationIgnored @Injected(\.userActionTracker) var userActionTracker

    // UI State - managed directly in ViewModel
    public private(set) var products: [Product] = []
    public private(set) var purchaseState: PurchaseState = .idle
    public private(set) var isLoading = false
    public private(set) var error: PaywallError?

    public var benefits: [PaywallBenefit] = []
    public private(set) var selectedProduct: Product?
    public private(set) var isUpdatingUser = false

    // Tracking properties
    private var paywallShownTime: Date?
    private var paywallSource: String = "unknown"
    private var paywallTrigger: String = "unknown"

    // Computed properties
    public var isPurchasing: Bool {
        purchaseState.isPurchasing
    }

    public var hasError: Bool {
        error != nil || purchaseState.errorMessage != nil
    }

    public var errorMessage: String? {
        error?.localizedDescription ?? purchaseState.errorMessage
    }

    /// Whether products are available for purchase
    public var hasProducts: Bool {
        !products.isEmpty
    }

    /// Whether the purchase button should be enabled
    /// Requires: not currently purchasing, products loaded, and a product selected
    public var canPurchase: Bool {
        !isPurchasing && hasProducts && selectedProduct != nil
    }

    public init(
        loadPaywallProducts: LoadPaywallProductsUseCase,
        purchaseProduct: PurchaseProductUseCase,
        restorePurchases: RestorePurchasesUseCase,
        checkProductPurchased: CheckProductPurchasedUseCase,
        errorHandler: ErrorHandler? = nil
    ) {
        self.loadPaywallProducts = loadPaywallProducts
        self.purchaseProduct = purchaseProduct
        self.restorePurchasesUseCase = restorePurchases
        self.checkProductPurchased = checkProductPurchased
        self.errorHandler = errorHandler
        self.benefits = PaywallBenefit.defaultBenefits
    }

    // MARK: - Public Methods

    public func load() async {
        let startTime = Date()

        // Reset purchase state when paywall loads
        purchaseState = .idle
        error = nil

        // Load products directly from business service
        isLoading = true

        do {
            products = try await loadPaywallProducts.execute()
        } catch {
            let paywallError = error as? PaywallError ?? PaywallError.productsNotAvailable
            self.error = paywallError

            // Log error to centralized handler
            await errorHandler?.logError(
                error,
                context: ErrorContext.paywall,
                additionalProperties: ["products_count": products.count]
            )
        }

        isLoading = false

        // Auto-select the popular product or first one
        selectedProduct = products.first { $0.isPopular } ?? products.first

        // Track performance metrics
        let loadTime = Date().timeIntervalSince(startTime)
        userActionTracker.trackPerformance(
            metric: "paywall_load_time",
            value: loadTime * 1000, // Convert to milliseconds
            unit: "ms",
            additionalProperties: ["products_count": products.count]
        )

        // Track error if loading failed
        if let error = error {
            userActionTracker.trackError(error, context: "paywall_load")
        }
    }

    public func trackPaywallShown(source: String, trigger: String) {
        paywallShownTime = Date()
        paywallSource = source
        paywallTrigger = trigger

        userActionTracker.track(.paywallShown(source: source, trigger: trigger))
    }

    public func trackPaywallDismissed() {
        let duration = paywallShownTime?.timeIntervalSinceNow.magnitude ?? 0
        userActionTracker.track(.paywallDismissed(source: paywallSource, duration: duration))
    }

    public func selectProduct(_ product: Product) {
        selectedProduct = product

        // Track product selection
        userActionTracker.track(.productSelected(
            productId: product.id,
            productName: product.name,
            price: product.localizedPrice
        ))
    }

    public func purchase() async {
        guard let product = selectedProduct else { return }

        // Track purchase attempt
        userActionTracker.track(.purchaseAttempted(
            productId: product.id,
            productName: product.name,
            price: product.localizedPrice
        ))

        // Perform purchase through business service
        purchaseState = .purchasing(product.id)

        do {
            let result = try await purchaseProduct.execute(product)

            switch result {
            case .success(let purchasedProduct):
                purchaseState = .success(purchasedProduct)

                // Track successful purchase
                userActionTracker.track(.purchaseCompleted(
                    productId: purchasedProduct.id,
                    productName: purchasedProduct.name,
                    price: purchasedProduct.localizedPrice,
                    duration: purchasedProduct.duration.rawValue
                ))

            case .failed(let message):
                purchaseState = .failed(message)
                error = PaywallError.purchaseFailed(message)

                // Track purchase failure
                userActionTracker.track(.purchaseFailed(
                    productId: product.id,
                    error: message
                ))

            case .cancelled:
                purchaseState = .idle
                // User cancelled - no error, just reset state
            }
        } catch {
            let paywallError = error as? PaywallError ?? PaywallError.purchaseFailed(error.localizedDescription)
            self.error = paywallError
            purchaseState = .failed(paywallError.localizedDescription)

            // Log error to centralized handler
            await errorHandler?.logError(
                error,
                context: ErrorContext.paywall,
                additionalProperties: ["product_id": product.id]
            )

            // Track purchase failure
            userActionTracker.track(.purchaseFailed(
                productId: product.id,
                error: paywallError.localizedDescription
            ))
        }
    }

    public func restorePurchases() async {
        // Track restore attempt
        userActionTracker.track(.purchaseRestoreAttempted)

        // Perform restore through business service
        purchaseState = .purchasing("restore")

        do {
            let result = try await restorePurchasesUseCase.execute()

            switch result {
            case .success(let restoredProductIds):
                purchaseState = .idle

                // Track successful restore
                if let firstProductId = restoredProductIds.first {
                    let productName = products.first { $0.id == firstProductId }?.name
                    userActionTracker.track(.purchaseRestoreCompleted(
                        productId: firstProductId,
                        productName: productName
                    ))
                }

            case .noProductsToRestore:
                purchaseState = .idle
                error = PaywallError.purchaseFailed("No purchases to restore")

                // Track that restore was attempted but nothing was restored
                userActionTracker.track(.purchaseRestoreCompleted(productId: nil, productName: nil))

            case .failed(let message):
                purchaseState = .failed(message)
                error = PaywallError.purchaseFailed(message)

                // Track restore failure
                userActionTracker.track(.purchaseRestoreFailed(error: message))
            }
        } catch {
            let paywallError = error as? PaywallError ?? PaywallError.purchaseFailed(error.localizedDescription)
            self.error = paywallError
            purchaseState = .failed(paywallError.localizedDescription)

            // Log error to centralized handler
            await errorHandler?.logError(
                error,
                context: ErrorContext.paywall,
                additionalProperties: [:]
            )

            // Track restore failure
            userActionTracker.track(.purchaseRestoreFailed(error: paywallError.localizedDescription))
        }
    }

    public func dismissError() {
        error = nil
        purchaseState = .idle
    }
}

// MARK: - Presentation Helpers

extension PaywallViewModel {
    /// Format price for display with savings calculation
    public func formattedPrice(for product: Product) -> String {
        product.localizedPrice
    }

    /// Get savings text for annual plans
    public func savingsText(for product: Product) -> String? {
        guard product.duration == .annual else { return nil }
        return product.discount
    }

    /// Get the most attractive product for default selection
    public var recommendedProduct: Product? {
        products.first { $0.isPopular } ?? products.first { $0.duration == .annual } ?? products.first
    }

    /// Check if product is currently selected
    public func isSelected(_ product: Product) -> Bool {
        selectedProduct?.id == product.id
    }

    /// Get benefits specific to a product tier
    public func benefits(for product: Product) -> [PaywallBenefit] {
        // All products get all benefits in this simple implementation
        benefits
    }
}
