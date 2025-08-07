import SwiftUI
import Combine

// MARK: - Navigation Service Implementation

@MainActor
public final class NavigationService: ObservableObject {
    @Published public var selectedTab: RootTab = .overview
    @Published public var shouldRefreshOverview = false
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
    
    public func navigateToDashboard() {
        let previousTab = tabName(selectedTab)
        selectedTab = .dashboard
        
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
    
    private func tabName(_ tab: RootTab) -> String {
        switch tab {
        case .overview: return "overview"
        case .habits: return "habits"
        case .dashboard: return "dashboard"
        case .settings: return "settings"
        }
    }
    
    public func didRefreshOverview() {
        shouldRefreshOverview = false
    }
}