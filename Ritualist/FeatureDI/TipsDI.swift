import Foundation

public struct TipsFactory {
    private let container: AppContainer
    public init(container: AppContainer) { self.container = container }
    
    @MainActor public func makeViewModel() -> TipsViewModel {
        let getAllTips = GetAllTips(repo: container.tipRepository)
        let getFeaturedTips = GetFeaturedTips(repo: container.tipRepository)
        let getTipById = GetTipById(repo: container.tipRepository)
        let getTipsByCategory = GetTipsByCategory(repo: container.tipRepository)
        
        return TipsViewModel(
            getAllTips: getAllTips,
            getFeaturedTips: getFeaturedTips,
            getTipById: getTipById,
            getTipsByCategory: getTipsByCategory
        )
    }
}