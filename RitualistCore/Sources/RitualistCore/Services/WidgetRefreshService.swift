//
//  WidgetRefreshService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import Foundation

/// Protocol for widget refresh service to enable proper dependency injection and testing
public protocol WidgetRefreshServiceProtocol {
    /// Refresh all Ritualist widgets after habit completion or data changes
    func refreshWidgets()
    
    /// Refresh widgets for specific habit changes (future enhancement)
    func refreshWidgetsForHabit(_ habitId: UUID)
    
    /// Refresh widgets after bulk habit operations
    func refreshWidgetsAfterBulkOperation()
}