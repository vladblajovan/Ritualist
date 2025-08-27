import Foundation
import FactoryKit
import RitualistCore

@MainActor @Observable
public final class PaywallViewModel {
    private let paywallBusinessService: PaywallBusinessService
    private let updateProfileSubscription: UpdateProfileSubscriptionUseCase
    private let errorHandler: ErrorHandlingActor?
    @ObservationIgnored @Injected(\.userActionTracker) var userActionTracker
    
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
    
    public init(
        paywallBusinessService: PaywallBusinessService,
        updateProfileSubscription: UpdateProfileSubscriptionUseCase,
        errorHandler: ErrorHandlingActor? = nil
    ) {
        self.paywallBusinessService = paywallBusinessService
        self.updateProfileSubscription = updateProfileSubscription
        self.errorHandler = errorHandler
        self.benefits = PaywallBenefit.defaultBenefits
    }
    
    // MARK: - Private Methods
    
    /// Update user subscription after successful purchase using UseCase
    private func handleUserSubscriptionUpdate(_ product: Product) async throws {
        try await updateProfileSubscription.execute(product: product)
    }
    
    public func load() async {
        let startTime = Date()
        
        // Reset purchase state when paywall loads
        purchaseState = .idle
        error = nil
        
        // Load products directly from business service
        isLoading = true
        
        do {
            products = try await paywallBusinessService.loadProducts()
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
        do {
            purchaseState = .purchasing(product.id)
            let success = try await paywallBusinessService.purchase(product)
            
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
            
            // Update user subscription after successful purchase
            do {
                try await handleUserSubscriptionUpdate(purchasedProduct)
            } catch {
                // Log the error but don't change purchase state
                userActionTracker.trackError(error, context: "subscription_update_after_purchase")
            }
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
            let success = try await paywallBusinessService.restorePurchases()
            
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
    
    // MARK: - Private Methods
    
    private func handleRestoredPurchases() async {
        // Check which products were restored and update user accordingly
        for product in products {
            let isPurchased = await paywallBusinessService.isProductPurchased(product.id)
            if isPurchased {
                do {
                    isUpdatingUser = true
                    try await handleUserSubscriptionUpdate(product)
                    isUpdatingUser = false
                    
                    // Track successful restore
                    userActionTracker.track(.purchaseRestoreCompleted(
                        productId: product.id,
                        productName: product.name
                    ))
                    
                    break // Only need to restore one subscription
                } catch {
                    isUpdatingUser = false
                    userActionTracker.trackError(error, context: "subscription_update_after_restore", additionalProperties: ["product_id": product.id])
                    print("Failed to restore subscription: \(error)")
                }
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
