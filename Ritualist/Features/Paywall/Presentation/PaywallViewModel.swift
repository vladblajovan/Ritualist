import Foundation
import FactoryKit
import RitualistCore

@MainActor @Observable
public final class PaywallViewModel {
    private let loadPaywallProducts: LoadPaywallProductsUseCase
    private let purchaseProduct: PurchaseProductUseCase
    private let restorePurchases: RestorePurchasesUseCase
    private let checkProductPurchased: CheckProductPurchasedUseCase
    private let errorHandler: ErrorHandler?
    @ObservationIgnored @Injected(\.userActionTracker) var userActionTracker
    @ObservationIgnored @Injected(\.paywallService) var paywallService
    
    // UI State - now managed directly in ViewModel
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

    // MARK: - Offer Code Properties

    /// Current state of offer code redemption from the paywall service
    public var offerCodeRedemptionState: OfferCodeRedemptionState {
        paywallService.offerCodeRedemptionState
    }

    /// Check if offer code redemption is available (iOS 14+)
    public var isOfferCodeRedemptionAvailable: Bool {
        paywallService.isOfferCodeRedemptionAvailable()
    }

    // MARK: - Discount Properties

    /// Active discounts for products (keyed by product ID)
    public private(set) var activeDiscounts: [String: ActiveDiscount] = [:]

    /// Check if there's an active discount for the selected product
    public var hasActiveDiscountForSelectedProduct: Bool {
        guard let productId = selectedProduct?.id else { return false }
        return activeDiscounts[productId] != nil
    }

    /// Get active discount for the selected product
    public var activeDiscountForSelectedProduct: ActiveDiscount? {
        guard let productId = selectedProduct?.id else { return nil }
        return activeDiscounts[productId]
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
        self.restorePurchases = restorePurchases
        self.checkProductPurchased = checkProductPurchased
        self.errorHandler = errorHandler
        self.benefits = PaywallBenefit.defaultBenefits
    }
    
    // MARK: - Private Methods

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

        // Load active discounts for all products
        await loadActiveDiscounts()

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
        do {
            purchaseState = .purchasing(product.id)
            let success = try await purchaseProduct.execute(product)
            
            if success {
                purchaseState = .success(product)
            } else {
                purchaseState = .failed("Purchase failed")
                error = PaywallError.purchaseFailed("Purchase failed")
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
        }
        
        // Check if purchase was successful
        if case .success(let purchasedProduct) = purchaseState {
            // Track successful purchase
            userActionTracker.track(.purchaseCompleted(
                productId: purchasedProduct.id,
                productName: purchasedProduct.name,
                price: purchasedProduct.localizedPrice,
                duration: purchasedProduct.duration.rawValue
            ))
        } else if let error = error {
            // Track purchase failure
            userActionTracker.track(.purchaseFailed(
                productId: product.id,
                error: error.localizedDescription
            ))
        }
    }
    
    public func restorePurchases() async {
        // Track restore attempt
        userActionTracker.track(.purchaseRestoreAttempted)
        
        // Perform restore through business service
        do {
            purchaseState = .purchasing("restore")
            let success = try await restorePurchases.execute()
            
            if success {
                purchaseState = .idle
            } else {
                purchaseState = .failed("No purchases to restore")
                error = PaywallError.purchaseFailed("No purchases to restore")
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
        }
        
        // Check results and handle accordingly
        if case .idle = purchaseState, error == nil {
            // Success - handle restored purchases
            await handleRestoredPurchases()
        } else if let error = error {
            // Track restore failure
            userActionTracker.track(.purchaseRestoreFailed(error: error.localizedDescription))
        } else {
            // Track that restore was attempted but nothing was restored
            userActionTracker.track(.purchaseRestoreCompleted(productId: nil, productName: nil))
        }
    }
    
    public func dismissError() {
        error = nil
        purchaseState = .idle
    }

    // MARK: - Offer Code Methods

    /// Present the system offer code redemption sheet
    ///
    /// This triggers the native iOS offer code entry UI. The actual sheet
    /// is presented using SwiftUI's `.offerCodeRedemption()` modifier in the view layer.
    ///
    public func presentOfferCodeSheet() {
        // Track user action
        userActionTracker.track(.custom(
            event: "offer_code_sheet_presented",
            parameters: [
                "source": paywallSource,
                "trigger": "promo_button"
            ]
        ))

        // The actual sheet presentation is handled by the view layer
        // using the `.offerCodeRedemption()` modifier
        paywallService.presentOfferCodeRedemptionSheet()
    }

    // MARK: - Discount Methods

    /// Load active discounts for all products
    public func loadActiveDiscounts() async {
        // Clear existing discounts
        activeDiscounts.removeAll()

        // Load discounts for each product
        for product in products {
            if let discount = await paywallService.getActiveDiscount(for: product.id) {
                activeDiscounts[product.id] = discount
            }
        }
    }

    /// Check if a specific product has an active discount
    public func hasActiveDiscount(for product: Product) -> Bool {
        activeDiscounts[product.id] != nil
    }

    /// Get active discount for a specific product
    public func getActiveDiscount(for product: Product) -> ActiveDiscount? {
        activeDiscounts[product.id]
    }

    /// Calculate discounted price for a product
    /// - Parameter product: The product to calculate price for
    /// - Returns: Discounted price if discount exists, nil otherwise
    public func getDiscountedPrice(for product: Product) -> Double? {
        guard let discount = activeDiscounts[product.id] else { return nil }
        guard let price = product.numericPrice else { return nil }

        return discount.calculateDiscountedPrice(price)
    }

    /// Clear active discount (typically after purchase)
    public func clearActiveDiscount() async {
        await paywallService.clearActiveDiscount()
        activeDiscounts.removeAll()
    }

    // MARK: - Private Methods
    
    private func handleRestoredPurchases() async {
        // Check which products were restored
        for product in products {
            let isPurchased = await checkProductPurchased.execute(product.id)
            if isPurchased {
                // Track successful restore
                userActionTracker.track(.purchaseRestoreCompleted(
                    productId: product.id,
                    productName: product.name
                ))

                break // Only need to track one restored subscription
            }
        }
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
