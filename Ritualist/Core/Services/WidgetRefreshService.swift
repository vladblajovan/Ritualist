// Re-export WidgetRefreshService protocol from RitualistCore
// Implementation must stay in app layer due to WidgetKit dependency
import WidgetKit
import Foundation
import RitualistCore

// Re-export protocol from RitualistCore
public typealias WidgetRefreshServiceProtocol = RitualistCore.WidgetRefreshServiceProtocol

// Implementation remains in app layer due to WidgetKit dependency
/// Service responsible for refreshing widget timelines when app data changes
/// Ensures widget displays up-to-date habit completion status
public final class WidgetRefreshService: WidgetRefreshServiceProtocol {
    
    public init() {}
    
    /// Refresh all Ritualist widgets after habit completion or data changes
    /// Should be called whenever habit status changes to keep widget synchronized
    @MainActor
    public func refreshWidgets() {
        print("[WIDGET-REFRESH] Refreshing all widgets of kind: RemainingHabitsWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "RemainingHabitsWidget")
        print("[WIDGET-REFRESH] Widget refresh command sent")
    }
    
    /// Refresh widgets for specific habit changes (future enhancement)
    /// Can be used for more granular refresh control if needed
    @MainActor
    public func refreshWidgetsForHabit(_ habitId: UUID) {
        print("[WIDGET-REFRESH] Refreshing widgets for habit: \(habitId)")
        // For now, refresh all widgets
        // In the future, could implement more targeted refresh logic
        refreshWidgets()
    }
    
    /// Refresh widgets after bulk habit operations
    /// Useful when multiple habits are updated simultaneously
    @MainActor
    public func refreshWidgetsAfterBulkOperation() {
        refreshWidgets()
    }
}