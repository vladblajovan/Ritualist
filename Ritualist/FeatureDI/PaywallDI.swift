import Foundation

public struct PaywallItem: Identifiable {
    public let id = UUID()
    public let viewModel: PaywallViewModel
    
    public init(viewModel: PaywallViewModel) {
        self.viewModel = viewModel
    }
}

public struct PaywallFactory {
    private let container: AppContainer
    
    public init(container: AppContainer) {
        self.container = container
    }
    
    public func makeViewModel() -> PaywallViewModel {
        PaywallViewModel(
            paywallService: container.paywallService,
            userSession: container.userSession
        )
    }
}