import Foundation

public struct PaywallItem: Identifiable, Equatable {
    public let id = UUID()
    public let viewModel: PaywallViewModel
    
    public init(viewModel: PaywallViewModel) {
        self.viewModel = viewModel
    }
    
    public static func == (lhs: PaywallItem, rhs: PaywallItem) -> Bool {
        lhs.id == rhs.id
    }
}

public struct PaywallFactory {
    private let container: AppContainer
    
    public init(container: AppContainer) {
        self.container = container
    }
    
    @MainActor
    public func makeViewModel() -> PaywallViewModel {
        let loadPaywallProducts = LoadPaywallProducts(paywallService: container.paywallService)
        let purchaseProduct = PurchaseProduct(paywallService: container.paywallService)
        let restorePurchases = RestorePurchases(paywallService: container.paywallService)
        let checkProductPurchased = CheckProductPurchased(paywallService: container.paywallService)
        let resetPurchaseState = ResetPurchaseState(paywallService: container.paywallService)
        let getPurchaseState = GetPurchaseState(paywallService: container.paywallService)
        let updateProfileSubscription = UpdateProfileSubscription(
            userService: container.userService,
            paywallService: container.paywallService
        )
        
        return PaywallViewModel(
            loadPaywallProducts: loadPaywallProducts,
            purchaseProduct: purchaseProduct,
            restorePurchases: restorePurchases,
            checkProductPurchased: checkProductPurchased,
            resetPurchaseState: resetPurchaseState,
            getPurchaseState: getPurchaseState,
            updateProfileSubscription: updateProfileSubscription,
            userService: container.userService
        )
    }
}
