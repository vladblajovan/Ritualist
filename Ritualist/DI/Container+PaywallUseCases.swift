import Foundation
import FactoryKit
import RitualistCore

// MARK: - Paywall Use Cases Container Extensions

extension Container {
    
    // MARK: - Paywall Operations
    
    var loadPaywallProducts: Factory<LoadPaywallProductsUseCase> {
        self { LoadPaywallProducts(paywallService: self.paywallService()) }
    }
    
    var purchaseProduct: Factory<PurchaseProductUseCase> {
        self { PurchaseProduct(paywallService: self.paywallService()) }
    }
    
    var restorePurchases: Factory<RestorePurchasesUseCase> {
        self { RestorePurchases(paywallService: self.paywallService()) }
    }
    
    var checkProductPurchased: Factory<CheckProductPurchasedUseCase> {
        self { CheckProductPurchased(paywallService: self.paywallService()) }
    }
    
    var resetPurchaseState: Factory<ResetPurchaseStateUseCase> {
        self { ResetPurchaseState(paywallService: self.paywallService()) }
    }
    
    var getPurchaseState: Factory<GetPurchaseStateUseCase> {
        self { GetPurchaseState(paywallService: self.paywallService()) }
    }
    
    var updateProfileSubscription: Factory<UpdateProfileSubscriptionUseCase> {
        self { UpdateProfileSubscription() }
    }
}