import SwiftUI
import RitualistCore

// MARK: - Navigation Service Implementation

@MainActor
@Observable
public final class NavigationService {
    public var selectedTab: Pages = .overview
    public var shouldRefreshOverview = false
    public var trackingService: UserActionTrackerService?
    
    public init() {}
    
    public func navigateToOverview(shouldRefresh: Bool = false) {
        let previousTab = tabName(selectedTab)
        selectedTab = .overview
        if shouldRefresh {
            shouldRefreshOverview = true
        }
        
        if previousTab != tabName(selectedTab) {
            trackingService?.track(.tabSwitched(from: previousTab, to: tabName(selectedTab)))
        }
    }
    
    public func navigateToHabits() {
        let previousTab = tabName(selectedTab)
        selectedTab = .habits
        
        if previousTab != tabName(selectedTab) {
            trackingService?.track(.tabSwitched(from: previousTab, to: tabName(selectedTab)))
        }
    }
    
    public func navigateToStats() {
        let previousTab = tabName(selectedTab)
        selectedTab = .stats

        if previousTab != tabName(selectedTab) {
            trackingService?.track(.tabSwitched(from: previousTab, to: tabName(selectedTab)))
        }
    }
    
    public func navigateToSettings() {
        let previousTab = tabName(selectedTab)
        selectedTab = .settings
        
        if previousTab != tabName(selectedTab) {
            trackingService?.track(.tabSwitched(from: previousTab, to: tabName(selectedTab)))
        }
    }
    
    private func tabName(_ tab: Pages) -> String {
        switch tab {
        case .overview: return "overview"
        case .habits: return "habits"
        case .stats: return "stats"
        case .settings: return "settings"
        }
    }
    
    public func didRefreshOverview() {
        shouldRefreshOverview = false
    }
}
