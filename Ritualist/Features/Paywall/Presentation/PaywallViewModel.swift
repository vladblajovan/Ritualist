import Foundation
import FactoryKit
import RitualistCore

@MainActor @Observable
public final class PaywallViewModel {
    private let loadPaywallProducts: LoadPaywallProductsUseCase
    private let purchaseProduct: PurchaseProductUseCase
    private let restorePurchases: RestorePurchasesUseCase
    private let checkProductPurchased: CheckProductPurchasedUseCase
    private let resetPurchaseState: ResetPurchaseStateUseCase
    private let getPurchaseState: GetPurchaseStateUseCase
    private let updateProfileSubscription: UpdateProfileSubscriptionUseCase
    private let userService: UserService
    @ObservationIgnored @Injected(\.userActionTracker) var userActionTracker
    
    public var products: [Product] = []
    public var benefits: [PaywallBenefit] = []
    public private(set) var isLoading = false
    public private(set) var error: Error?
    public private(set) var purchaseState: PurchaseState = .idle
    public private(set) var selectedProduct: Product?
    public private(set) var isUpdatingUser = false
    
    // Tracking properties
    private var paywallShownTime: Date?
    private var paywallSource: String = "unknown"
    private var paywallTrigger: String = "unknown"
    
    // Convenience computed properties
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
        loadPaywallProducts: LoadPaywallProductsUseCase,
        purchaseProduct: PurchaseProductUseCase,
        restorePurchases: RestorePurchasesUseCase,
        checkProductPurchased: CheckProductPurchasedUseCase,
        resetPurchaseState: ResetPurchaseStateUseCase,
        getPurchaseState: GetPurchaseStateUseCase,
        updateProfileSubscription: UpdateProfileSubscriptionUseCase,
        userService: UserService
    ) {
        self.loadPaywallProducts = loadPaywallProducts
        self.purchaseProduct = purchaseProduct
        self.restorePurchases = restorePurchases
        self.checkProductPurchased = checkProductPurchased
        self.resetPurchaseState = resetPurchaseState
        self.getPurchaseState = getPurchaseState
        self.updateProfileSubscription = updateProfileSubscription
        self.userService = userService
        self.benefits = PaywallBenefit.defaultBenefits
    }
    
    // MARK: - Private Methods
    
    /// Update user subscription after successful purchase using UseCase
    private func handleUserSubscriptionUpdate(_ product: Product) async throws {
        try await updateProfileSubscription.execute(product: product)
    }
    
    private func syncPurchaseState() {
        // Manually sync purchase state from service
        purchaseState = getPurchaseState.execute()
    }
    
    public func load() async {
        let startTime = Date()
        isLoading = true
        error = nil
        
        // Reset purchase state when paywall loads
        // This prevents previous purchase success from immediately dismissing the paywall
        await resetPurchaseState()
        
        do {
            let loadedProducts = try await loadPaywallProducts.execute()
            
            products = loadedProducts
            // Auto-select the popular product or first one
            selectedProduct = products.first { $0.isPopular } ?? products.first
            
            // Sync purchase state after loading
            syncPurchaseState()
            isLoading = false
            
            // Track performance metrics
            let loadTime = Date().timeIntervalSince(startTime)
            userActionTracker.trackPerformance(
                metric: "paywall_load_time",
                value: loadTime * 1000, // Convert to milliseconds
                unit: "ms",
                additionalProperties: ["products_count": products.count]
            )
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "paywall_load")
            // Sync purchase state even on error
            syncPurchaseState()
            isLoading = false
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
    
    private func resetPurchaseState() async {
        // Reset the purchase state to idle when the paywall loads
        // This prevents previous purchase success from immediately dismissing the paywall
        resetPurchaseState.execute()
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
        
        error = nil
        
        // Track purchase attempt
        userActionTracker.track(.purchaseAttempted(
            productId: product.id,
            productName: product.name,
            price: product.localizedPrice
        ))
        
        do {
            let success = try await purchaseProduct.execute(product)
            // Sync purchase state after purchase attempt
            syncPurchaseState()
            
            if success {
                // Track successful purchase
                userActionTracker.track(.purchaseCompleted(
                    productId: product.id,
                    productName: product.name,
                    price: product.localizedPrice,
                    duration: product.duration.rawValue
                ))
                
                // Update user subscription after successful purchase
                try await handleUserSubscriptionUpdate(product)
            }
        } catch {
            // Track purchase failure
            userActionTracker.track(.purchaseFailed(
                productId: product.id,
                error: error.localizedDescription
            ))
            
            self.error = error
            // Sync purchase state even on error
            syncPurchaseState()
        }
    }
    
    public func restorePurchases() async {
        error = nil
        
        // Track restore attempt
        userActionTracker.track(.purchaseRestoreAttempted)
        
        do {
            let restored = try await restorePurchases.execute()
            // Sync purchase state after restore attempt
            syncPurchaseState()
            
            if restored {
                // Handle restored purchases
                await handleRestoredPurchases()
            } else {
                // Track that restore was attempted but nothing was restored
                userActionTracker.track(.purchaseRestoreCompleted(productId: nil, productName: nil))
            }
        } catch {
            // Track restore failure
            userActionTracker.track(.purchaseRestoreFailed(error: error.localizedDescription))
            
            self.error = error
            // Sync purchase state even on error
            syncPurchaseState()
        }
    }
    
    public func dismissError() {
        error = nil
        if case .failed = purchaseState {
            purchaseState = .idle
        }
    }
    
    // MARK: - Private Methods
    
    private func handleRestoredPurchases() async {
        // Check which products were restored and update user accordingly
        for product in products {
            let isPurchased = await checkProductPurchased.execute(product.id)
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
