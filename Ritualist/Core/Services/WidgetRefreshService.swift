// WidgetRefreshService implementation
// Must stay in app layer due to WidgetKit dependency
// Protocol re-exported in Services.swift
import WidgetKit
import Foundation
import RitualistCore

/// Service responsible for refreshing widget timelines when app data changes
/// Ensures widget displays up-to-date habit completion status
/// Protocol (WidgetRefreshServiceProtocol) is re-exported in Services.swift
public final class WidgetRefreshService: WidgetRefreshServiceProtocol {
    private let logger: DebugLogger

    public init(logger: DebugLogger) {
        self.logger = logger
    }
    
    /// Refresh all Ritualist widgets after habit completion or data changes
    /// Should be called whenever habit status changes to keep widget synchronized
    @MainActor
    public func refreshWidgets() {
        logger.log("Refreshing all widgets: RemainingHabitsWidget", level: .debug, category: .system)
        WidgetCenter.shared.reloadTimelines(ofKind: "RemainingHabitsWidget")
        logger.log("Widget refresh command sent", level: .debug, category: .system)
    }

    /// Refresh widgets for specific habit changes (future enhancement)
    /// Can be used for more granular refresh control if needed
    @MainActor
    public func refreshWidgetsForHabit(_ habitId: UUID) {
        logger.log("Refreshing widgets for habit: \(habitId)", level: .debug, category: .system)
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