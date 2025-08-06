import SwiftUI
import Combine

// MARK: - Navigation Service Implementation

@MainActor
public final class NavigationService: ObservableObject {
    @Published public var selectedTab: RootTab = .overview
    @Published public var shouldRefreshOverview = false
    
    public init() {}
    
    public func navigateToOverview(shouldRefresh: Bool = false) {
        selectedTab = .overview
        if shouldRefresh {
            shouldRefreshOverview = true
        }
    }
    
    public func navigateToHabits() {
        selectedTab = .habits
    }
    
    public func navigateToSettings() {
        selectedTab = .settings
    }
    
    public func didRefreshOverview() {
        shouldRefreshOverview = false
    }
}