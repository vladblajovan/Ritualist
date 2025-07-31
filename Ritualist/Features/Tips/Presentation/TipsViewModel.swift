import Foundation
import Observation

@MainActor @Observable
public final class TipsViewModel {
    private let getAllTips: GetAllTipsUseCase
    private let getFeaturedTips: GetFeaturedTipsUseCase
    private let getTipById: GetTipByIdUseCase
    private let getTipsByCategory: GetTipsByCategoryUseCase
    
    public private(set) var allTips: [Tip] = []
    public private(set) var featuredTips: [Tip] = []
    public private(set) var isLoading = false
    public private(set) var error: Error?
    
    // Bottom sheet state
    public private(set) var showingAllTipsSheet = false
    public private(set) var selectedTip: Tip?
    public private(set) var showingTipDetail = false
    
    // Tips organized by category for bottom sheet
    public var tipsByCategory: [(category: TipCategory, tips: [Tip])] {
        let categories = TipCategory.allCases
        return categories.compactMap { category in
            let categoryTips = allTips.filter { $0.category == category }
            return categoryTips.isEmpty ? nil : (category, categoryTips)
        }
    }
    
    // Featured tips first, then remaining tips for bottom sheet display
    public var tipsForBottomSheet: [Tip] {
        let featured = featuredTips.sorted { $0.order < $1.order }
        let nonFeatured = allTips.filter { !$0.isFeaturedInCarousel }.sorted { tip1, tip2 in
            if tip1.category != tip2.category {
                return tip1.category.rawValue < tip2.category.rawValue
            }
            return tip1.title < tip2.title
        }
        return featured + nonFeatured
    }
    
    public init(getAllTips: GetAllTipsUseCase,
                getFeaturedTips: GetFeaturedTipsUseCase,
                getTipById: GetTipByIdUseCase,
                getTipsByCategory: GetTipsByCategoryUseCase) {
        self.getAllTips = getAllTips
        self.getFeaturedTips = getFeaturedTips
        self.getTipById = getTipById
        self.getTipsByCategory = getTipsByCategory
    }
    
    public func load() async {
        isLoading = true
        error = nil
        
        do {
            // Load all tips and featured tips in parallel
            async let allTipsTask = getAllTips.execute()
            async let featuredTipsTask = getFeaturedTips.execute()
            
            allTips = try await allTipsTask
            featuredTips = try await featuredTipsTask
        } catch {
            self.error = error
            allTips = []
            featuredTips = []
        }
        
        isLoading = false
    }
    
    public func showAllTipsSheet() {
        showingAllTipsSheet = true
    }
    
    public func hideAllTipsSheet() {
        showingAllTipsSheet = false
    }
    
    public func selectTip(_ tip: Tip) {
        selectedTip = tip
        showingTipDetail = true
    }
    
    public func hideTipDetail() {
        showingTipDetail = false
        selectedTip = nil
    }
    
    public func retry() async {
        await load()
    }
    
    // Helper method to get tip by ID (for navigation from other parts of the app)
    public func getTip(by id: UUID) async -> Tip? {
        do {
            return try await getTipById.execute(id: id)
        } catch {
            self.error = error
            return nil
        }
    }
}