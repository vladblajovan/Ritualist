import Foundation
import Observation
import FactoryKit

@MainActor @Observable
public final class TipsViewModel {
    private let getAllTips: GetAllTipsUseCase
    private let getFeaturedTips: GetFeaturedTipsUseCase
    private let getTipById: GetTipByIdUseCase
    private let getTipsByCategory: GetTipsByCategoryUseCase
    @ObservationIgnored @Injected(\.userActionTracker) var userActionTracker
    
    public private(set) var allTips: [Tip] = []
    public private(set) var featuredTips: [Tip] = []
    public private(set) var isLoading = false
    public private(set) var error: Error?
    
    // Bottom sheet state
    public private(set) var showingAllTipsSheet = false
    public private(set) var selectedTip: Tip?
    public private(set) var showingTipDetail = false
    
    // Tracking properties
    private var bottomSheetOpenedTime: Date?
    private var tipDetailOpenedTime: Date?
    
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
            
            // Track carousel view when tips are loaded
            if !featuredTips.isEmpty {
                userActionTracker.track(.tipsCarouselViewed)
            }
        } catch {
            self.error = error
            allTips = []
            featuredTips = []
        }
        
        isLoading = false
    }
    
    public func showAllTipsSheet() {
        showAllTipsSheet(source: "tips_carousel")
    }
    
    public func showAllTipsSheet(source: String) {
        bottomSheetOpenedTime = Date()
        showingAllTipsSheet = true
        
        // Track bottom sheet opening with source
        userActionTracker.track(.tipsBottomSheetOpened(source: source))
    }
    
    public func hideAllTipsSheet() {
        let timeSpent = bottomSheetOpenedTime?.timeIntervalSinceNow.magnitude ?? 0
        
        // Track bottom sheet closing with time spent
        userActionTracker.track(.tipsBottomSheetClosed(timeSpent: timeSpent))
        
        bottomSheetOpenedTime = nil
        showingAllTipsSheet = false
    }
    
    public func selectTip(_ tip: Tip) {
        selectedTip = tip
        tipDetailOpenedTime = Date()
        showingTipDetail = true
        
        // Track tip detail opening
        userActionTracker.track(.tipDetailOpened(
            tipId: tip.id.uuidString,
            tipTitle: tip.title,
            category: tip.category.rawValue,
            isFeatured: tip.isFeaturedInCarousel
        ))
    }
    
    public func hideTipDetail() {
        if let tip = selectedTip {
            let timeSpent = tipDetailOpenedTime?.timeIntervalSinceNow.magnitude ?? 0
            
            // Track tip detail closing with time spent
            userActionTracker.track(.tipDetailClosed(
                tipId: tip.id.uuidString,
                tipTitle: tip.title,
                timeSpent: timeSpent
            ))
        }
        
        tipDetailOpenedTime = nil
        showingTipDetail = false
        selectedTip = nil
    }
    
    public func retry() async {
        await load()
    }
    
    // Track individual tip viewed in carousel
    public func trackTipViewed(_ tip: Tip, source: String) {
        userActionTracker.track(.tipViewed(
            tipId: tip.id.uuidString,
            tipTitle: tip.title,
            category: tip.category.rawValue,
            source: source
        ))
    }
    
    // Track category filter applied in bottom sheet
    public func trackCategoryFilterApplied(_ category: TipCategory) {
        userActionTracker.track(.tipsCategoryFilterApplied(category: category.rawValue))
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