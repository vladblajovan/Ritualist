import Foundation
import FactoryKit

// MARK: - Paywall Use Cases Container Extensions

extension Container {
    
    // MARK: - Paywall Operations
    
    @MainActor
    var loadPaywallProducts: Factory<LoadPaywallProductsUseCase> {
        self { @MainActor in LoadPaywallProducts(paywallService: self.paywallService()) }
    }
    
    @MainActor
    var purchaseProduct: Factory<PurchaseProductUseCase> {
        self { @MainActor in PurchaseProduct(paywallService: self.paywallService()) }
    }
    
    @MainActor
    var restorePurchases: Factory<RestorePurchasesUseCase> {
        self { @MainActor in RestorePurchases(paywallService: self.paywallService()) }
    }
    
    @MainActor
    var checkProductPurchased: Factory<CheckProductPurchasedUseCase> {
        self { @MainActor in CheckProductPurchased(paywallService: self.paywallService()) }
    }
    
    @MainActor
    var resetPurchaseState: Factory<ResetPurchaseStateUseCase> {
        self { @MainActor in ResetPurchaseState(paywallService: self.paywallService()) }
    }
    
    @MainActor
    var getPurchaseState: Factory<GetPurchaseStateUseCase> {
        self { @MainActor in GetPurchaseState(paywallService: self.paywallService()) }
    }
    
    @MainActor
    var updateProfileSubscription: Factory<UpdateProfileSubscriptionUseCase> {
        self { @MainActor in
            UpdateProfileSubscription(
                userService: self.userService(),
                paywallService: self.paywallService()
            )
        }
    }
}