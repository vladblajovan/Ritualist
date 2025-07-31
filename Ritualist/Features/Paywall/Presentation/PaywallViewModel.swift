import Foundation
import Observation

@Observable
public final class PaywallViewModel {
    private let paywallService: PaywallService
    private let userSession: any UserSessionProtocol
    
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
    
    public init(paywallService: PaywallService, userSession: any UserSessionProtocol) {
        self.paywallService = paywallService
        self.userSession = userSession
        self.benefits = PaywallBenefit.defaultBenefits
        
        // Observe purchase state changes
        Task {
            for await newState in paywallService.purchaseStatePublisher.values {
                await MainActor.run {
                    self.purchaseState = newState
                }
            }
        }
    }
    
    public func load() async {
        isLoading = true
        error = nil
        
        // Reset purchase state when paywall loads
        // This prevents previous purchase success from immediately dismissing the paywall
        await resetPurchaseState()
        
        do {
            products = try await paywallService.loadProducts()
            
            // Auto-select the popular product or first one
            selectedProduct = products.first { $0.isPopular } ?? products.first
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    private func resetPurchaseState() async {
        // Reset the purchase state to idle when the paywall loads
        // This prevents previous purchase success from immediately dismissing the paywall
        await MainActor.run {
            paywallService.resetPurchaseState()
        }
    }
    
    public func selectProduct(_ product: Product) {
        selectedProduct = product
    }
    
    public func purchase() async {
        guard let product = selectedProduct else { return }
        
        error = nil
        
        do {
            let success = try await paywallService.purchase(product)
            if success {
                // Update user subscription BEFORE setting success state
                // This ensures the user state is updated before the PaywallView dismisses
                await updateUserSubscription(for: product)
                
                // Now set success state - this will trigger PaywallView to dismiss
                // but the user subscription will already be updated
            }
        } catch {
            self.error = error
        }
    }
    
    public func restorePurchases() async {
        error = nil
        
        do {
            let restored = try await paywallService.restorePurchases()
            if restored {
                // Restore successful - update user subscription if needed
                await handleRestoredPurchases()
            }
        } catch {
            self.error = error
        }
    }
    
    public func dismissError() {
        error = nil
        if case .failed = purchaseState {
            purchaseState = .idle
        }
    }
    
    // MARK: - Private Methods
    
    private func updateUserSubscription(for product: Product) async {
        guard let currentUser = userSession.currentUser else { return }
        
        isUpdatingUser = true
        
        // Update user's subscription plan
        var updatedUser = currentUser
        updatedUser.subscriptionPlan = product.subscriptionPlan
        
        // Calculate expiry date based on the product duration
        let calendar = Calendar.current
        switch product.duration {
        case .monthly:
            updatedUser.subscriptionExpiryDate = calendar.date(byAdding: .month, value: 1, to: Date())
        case .annual:
            updatedUser.subscriptionExpiryDate = calendar.date(byAdding: .year, value: 1, to: Date())
        }
        
        // Update through user session (if it supports user updates)
        do {
            _ = try await userSession.updateUser(updatedUser)
        } catch {
            // If updating user fails, we'll still proceed as the purchase was successful
            print("Failed to update user subscription: \(error)")
        }
        
        isUpdatingUser = false
    }
    
    private func handleRestoredPurchases() async {
        // Check which products were restored and update user accordingly
        for product in products {
            let isPurchased = await paywallService.isProductPurchased(product.id)
            if isPurchased {
                await updateUserSubscription(for: product)
                break // Only need to restore one subscription
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