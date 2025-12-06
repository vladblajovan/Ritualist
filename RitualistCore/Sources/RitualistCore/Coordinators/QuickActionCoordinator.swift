//
//  QuickActionCoordinator.swift
//  RitualistCore
//
//  Created by Claude on 27.11.2025.
//
//  Coordinates iOS Quick Actions (Home Screen Shortcuts) handling.
//  When user long-presses the app icon and selects an action,
//  this coordinator processes the action and triggers appropriate navigation.
//

import Foundation
import UIKit

/// Available Quick Actions for the app home screen shortcut menu
public enum QuickActionType: String {
    case addHabit = "com.ritualist.quickaction.addHabit"
    case habitsAssistant = "com.ritualist.quickaction.habitsAssistant"
    case stats = "com.ritualist.quickaction.stats"

    /// SF Symbol icon name for this action
    public var iconName: String {
        switch self {
        case .addHabit: return "plus.circle.fill"
        case .habitsAssistant: return "sparkles"
        case .stats: return "chart.bar.fill"
        }
    }

    /// Localized title for this action
    public var title: String {
        switch self {
        case .addHabit: return String(localized: "quickActionAddHabit")
        case .habitsAssistant: return String(localized: "quickActionHabitsAssistant")
        case .stats: return String(localized: "quickActionStats")
        }
    }
}

/// Coordinates Quick Action handling between AppDelegate and SwiftUI views
@MainActor
@Observable
public final class QuickActionCoordinator {

    // MARK: - Dependencies

    private let logger: DebugLogger

    // MARK: - Observable Properties

    /// The pending action to be handled by the UI
    public var pendingAction: QuickActionType?

    /// Triggers for specific actions - views observe these
    public var shouldShowAddHabit = false
    public var shouldShowHabitsAssistant = false
    public var shouldNavigateToStats = false

    // MARK: - Initialization

    public init(logger: DebugLogger = DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "quickActions")) {
        self.logger = logger
    }

    // MARK: - Public Methods

    /// Register the app's Quick Actions with iOS
    /// Call this from AppDelegate didFinishLaunchingWithOptions
    public func registerQuickActions() {
        logger.log(
            "Registering Quick Actions",
            level: .info,
            category: .system
        )

        let addHabitAction = UIApplicationShortcutItem(
            type: QuickActionType.addHabit.rawValue,
            localizedTitle: QuickActionType.addHabit.title,
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(systemImageName: QuickActionType.addHabit.iconName),
            userInfo: nil
        )

        let habitsAssistantAction = UIApplicationShortcutItem(
            type: QuickActionType.habitsAssistant.rawValue,
            localizedTitle: QuickActionType.habitsAssistant.title,
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(systemImageName: QuickActionType.habitsAssistant.iconName),
            userInfo: nil
        )

        let statsAction = UIApplicationShortcutItem(
            type: QuickActionType.stats.rawValue,
            localizedTitle: QuickActionType.stats.title,
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(systemImageName: QuickActionType.stats.iconName),
            userInfo: nil
        )

        UIApplication.shared.shortcutItems = [addHabitAction, habitsAssistantAction, statsAction]

        // Validate registration succeeded
        let registeredItems = UIApplication.shared.shortcutItems ?? []
        let expectedCount = 3

        if registeredItems.count == expectedCount {
            logger.log(
                "Quick Actions registered successfully",
                level: .info,
                category: .system,
                metadata: ["count": registeredItems.count]
            )
        } else {
            logger.log(
                "Quick Actions registration may have failed",
                level: .warning,
                category: .system,
                metadata: [
                    "expected": expectedCount,
                    "actual": registeredItems.count,
                    "items": registeredItems.map { $0.type }
                ]
            )
        }
    }

    /// Handle a Quick Action shortcut item
    /// Call this from AppDelegate performActionFor shortcutItem
    /// - Parameter shortcutItem: The shortcut item that was triggered
    /// - Returns: true if the action was handled successfully
    @discardableResult
    public func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        logger.log(
            "Handling shortcut item",
            level: .info,
            category: .system,
            metadata: ["type": shortcutItem.type]
        )

        guard let actionType = QuickActionType(rawValue: shortcutItem.type) else {
            logger.log(
                "Unknown shortcut item type",
                level: .warning,
                category: .system,
                metadata: ["type": shortcutItem.type]
            )
            return false
        }

        pendingAction = actionType
        logger.log(
            "Shortcut item handled, pending action set",
            level: .info,
            category: .system,
            metadata: ["action": actionType.rawValue, "pendingAction": String(describing: pendingAction)]
        )
        return true
    }

    /// Process the pending action and trigger appropriate navigation
    /// Call this after the app UI is ready (e.g., in RootTabView.onAppear)
    public func processPendingAction() {
        logger.log(
            "Processing pending action",
            level: .info,
            category: .system,
            metadata: ["pendingAction": String(describing: pendingAction)]
        )

        guard let action = pendingAction else {
            logger.log(
                "No pending action to process",
                level: .debug,
                category: .system
            )
            return
        }

        // Clear pending action immediately to prevent re-processing
        pendingAction = nil

        logger.log(
            "Triggering action",
            level: .info,
            category: .system,
            metadata: ["action": action.rawValue]
        )

        switch action {
        case .addHabit:
            shouldShowAddHabit = true
            logger.log("Set shouldShowAddHabit = true", level: .debug, category: .system)
        case .habitsAssistant:
            shouldShowHabitsAssistant = true
            logger.log("Set shouldShowHabitsAssistant = true", level: .debug, category: .system)
        case .stats:
            shouldNavigateToStats = true
            logger.log("Set shouldNavigateToStats = true", level: .debug, category: .system)
        }
    }

    /// Reset all triggers after they've been handled
    public func resetTriggers() {
        logger.log(
            "Resetting triggers",
            level: .debug,
            category: .system,
            metadata: [
                "shouldShowAddHabit": shouldShowAddHabit,
                "shouldShowHabitsAssistant": shouldShowHabitsAssistant,
                "shouldNavigateToStats": shouldNavigateToStats
            ]
        )
        shouldShowAddHabit = false
        shouldShowHabitsAssistant = false
        shouldNavigateToStats = false
    }
}
