import Foundation

// MARK: - Paywall Use Case Implementations

public final class LoadPaywallProducts: LoadPaywallProductsUseCase {
    private let paywallService: PaywallService
    
    public init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }
    
    public func execute() async throws -> [Product] {
        try await paywallService.loadProducts()
    }
}

public final class PurchaseProduct: PurchaseProductUseCase {
    private let paywallService: PaywallService
    
    public init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }
    
    public func execute(_ product: Product) async throws -> Bool {
        try await paywallService.purchase(product)
    }
}

public final class RestorePurchases: RestorePurchasesUseCase {
    private let paywallService: PaywallService
    
    public init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }
    
    public func execute() async throws -> Bool {
        try await paywallService.restorePurchases()
    }
}

public final class CheckProductPurchased: CheckProductPurchasedUseCase {
    private let paywallService: PaywallService
    
    public init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }
    
    public func execute(_ productId: String) async -> Bool {
        await paywallService.isProductPurchased(productId)
    }
}

public final class ResetPurchaseState: ResetPurchaseStateUseCase {
    private let paywallService: PaywallService
    
    public init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }
    
    public func execute() {
        paywallService.resetPurchaseState()
    }
}

public final class GetPurchaseState: GetPurchaseStateUseCase {
    private let paywallService: PaywallService
    
    public init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }
    
    public func execute() -> PurchaseState {
        paywallService.purchaseState
    }
}