import Foundation

@MainActor @Observable
public final class PaywallViewModel {
    private let paywallService: PaywallService
    private let userSession: any UserSessionProtocol
    private let stateCoordinator: any StateCoordinatorProtocol
    
    public var products: [Product] = []
    public var benefits: [PaywallBenefit] = []
    public private(set) var isLoading = false
    public private(set) var error: Error?
    public private(set) var purchaseState: PurchaseState = .idle
    public private(set) var selectedProduct: Product?
    public private(set) var isUpdatingUser = false
    
    
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
        paywallService: PaywallService, 
        userSession: any UserSessionProtocol,
        stateCoordinator: any StateCoordinatorProtocol
    ) {
        self.paywallService = paywallService
        self.userSession = userSession
        self.stateCoordinator = stateCoordinator
        self.benefits = PaywallBenefit.defaultBenefits
    }
    
    private func syncPurchaseState() {
        // Manually sync purchase state from service
        purchaseState = paywallService.purchaseState
    }
    
    public func load() async {
        isLoading = true
        error = nil
        
        // Reset purchase state when paywall loads
        // This prevents previous purchase success from immediately dismissing the paywall
        await resetPurchaseState()
        
        do {
            let loadedProducts = try await paywallService.loadProducts()
            
            products = loadedProducts
            // Auto-select the popular product or first one
            selectedProduct = products.first { $0.isPopular } ?? products.first
            
            // Sync purchase state after loading
            syncPurchaseState()
            isLoading = false
        } catch {
            self.error = error
            // Sync purchase state even on error
            syncPurchaseState()
            isLoading = false
        }
    }
    
    private func resetPurchaseState() async {
        // Reset the purchase state to idle when the paywall loads
        // This prevents previous purchase success from immediately dismissing the paywall
        paywallService.resetPurchaseState()
    }
    
    public func selectProduct(_ product: Product) {
        selectedProduct = product
    }
    
    public func purchase() async {
        guard let product = selectedProduct,
              let currentUser = userSession.currentUser else { return }
        
        error = nil
        
        do {
            let success = try await paywallService.purchase(product)
            // Sync purchase state after purchase attempt
            syncPurchaseState()
            
            if success {
                // Use StateCoordinator for atomic transaction
                try await stateCoordinator.updateUserSubscription(currentUser, product)
            }
        } catch {
            self.error = error
            // Sync purchase state even on error
            syncPurchaseState()
        }
    }
    
    public func restorePurchases() async {
        guard let currentUser = userSession.currentUser else { return }
        
        error = nil
        
        do {
            let restored = try await paywallService.restorePurchases()
            // Sync purchase state after restore attempt
            syncPurchaseState()
            
            if restored {
                // Use StateCoordinator for atomic restoration
                await handleRestoredPurchases(for: currentUser)
            }
        } catch {
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
    
    private func handleRestoredPurchases(for user: User) async {
        // Check which products were restored and update user accordingly
        for product in products {
            let isPurchased = await paywallService.isProductPurchased(product.id)
            if isPurchased {
                do {
                    isUpdatingUser = true
                    try await stateCoordinator.updateUserSubscription(user, product)
                    isUpdatingUser = false
                    break // Only need to restore one subscription
                } catch {
                    isUpdatingUser = false
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
        return benefits
    }
}