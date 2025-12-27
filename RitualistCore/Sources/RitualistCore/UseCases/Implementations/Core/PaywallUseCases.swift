import Foundation

// MARK: - Paywall Use Case Implementations

public final class LoadPaywallProducts: LoadPaywallProductsUseCase, Sendable {
    private let paywallService: PaywallService

    public init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }

    public func execute() async throws -> [Product] {
        try await paywallService.loadProducts()
    }
}

public final class PurchaseProduct: PurchaseProductUseCase, Sendable {
    private let paywallService: PaywallService

    public init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }

    public func execute(_ product: Product) async throws -> PurchaseResult {
        try await paywallService.purchase(product)
    }
}

public final class RestorePurchases: RestorePurchasesUseCase, Sendable {
    private let paywallService: PaywallService

    public init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }

    public func execute() async throws -> RestoreResult {
        try await paywallService.restorePurchases()
    }
}

public final class CheckProductPurchased: CheckProductPurchasedUseCase, Sendable {
    private let paywallService: PaywallService

    public init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }

    public func execute(_ productId: String) async -> Bool {
        await paywallService.isProductPurchased(productId)
    }
}
