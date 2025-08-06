import Foundation
import FactoryKit

// MARK: - Paywall Use Cases Container Extensions

extension Container {
    
    // MARK: - Paywall Operations
    
    @MainActor
    var loadPaywallProducts: Factory<LoadPaywallProducts> {
        self { @MainActor in LoadPaywallProducts(paywallService: self.paywallService()) }
    }
    
    @MainActor
    var purchaseProduct: Factory<PurchaseProduct> {
        self { @MainActor in PurchaseProduct(paywallService: self.paywallService()) }
    }
    
    @MainActor
    var restorePurchases: Factory<RestorePurchases> {
        self { @MainActor in RestorePurchases(paywallService: self.paywallService()) }
    }
    
    @MainActor
    var checkProductPurchased: Factory<CheckProductPurchased> {
        self { @MainActor in CheckProductPurchased(paywallService: self.paywallService()) }
    }
    
    @MainActor
    var resetPurchaseState: Factory<ResetPurchaseState> {
        self { @MainActor in ResetPurchaseState(paywallService: self.paywallService()) }
    }
    
    @MainActor
    var getPurchaseState: Factory<GetPurchaseState> {
        self { @MainActor in GetPurchaseState(paywallService: self.paywallService()) }
    }
    
    @MainActor
    var updateProfileSubscription: Factory<UpdateProfileSubscription> {
        self { @MainActor in
            UpdateProfileSubscription(
                userService: self.userService(),
                paywallService: self.paywallService()
            )
        }
    }
}