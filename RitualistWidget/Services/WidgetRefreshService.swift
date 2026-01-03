//
//  WidgetRefreshService.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 19.08.2025.
//

import WidgetKit
import Foundation
import RitualistCore

// Re-export protocol from RitualistCore to avoid duplication
public typealias WidgetRefreshServiceProtocol = RitualistCore.WidgetRefreshServiceProtocol

/// Widget-specific implementation of widget refresh service
/// Ensures widget displays up-to-date habit completion status
@MainActor
public final class WidgetRefreshService: WidgetRefreshServiceProtocol {

    public init() {}

    /// Refresh all Ritualist widgets after habit completion or data changes
    /// Should be called whenever habit status changes to keep widget synchronized
    public func refreshWidgets() {
        print("[WIDGET-REFRESH] Refreshing all widgets of kind: RemainingHabitsWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "RemainingHabitsWidget")
        print("[WIDGET-REFRESH] Widget refresh command sent")
    }

    /// Refresh widgets for specific habit changes (future enhancement)
    /// Can be used for more granular refresh control if needed
    public func refreshWidgetsForHabit(_ habitId: UUID) {
        print("[WIDGET-REFRESH] Refreshing widgets for habit: \(habitId)")
        refreshWidgets()
    }

    /// Refresh widgets after bulk habit operations
    /// Useful when multiple habits are updated simultaneously
    public func refreshWidgetsAfterBulkOperation() {
        refreshWidgets()
    }
}
