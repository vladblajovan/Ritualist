//
//  PersonalityDeepLinkCoordinator.swift
//  RitualistCore
//
//  Created by Claude on 06.08.2025.
//

import Foundation
import SwiftUI
import UserNotifications

/// Coordinates deep linking for personality analysis notifications
@Observable
public final class PersonalityDeepLinkCoordinator {

    // MARK: - Dependencies

    private let logger: DebugLogger

    // MARK: - Observable Properties

    public var shouldShowPersonalityAnalysis = false
    public var pendingNotificationAction: PersonalityNotificationAction?
    public var shouldSwitchTab = true // Controls whether to switch to a specific tab before showing sheet

    // MARK: - Types

    public enum PersonalityNotificationAction {
        case openAnalysis(dominantTrait: PersonalityTrait?, confidence: ConfidenceLevel?)
        case openRequirements
        case checkAnalysis
        case directNavigation // For direct navigation without notification context
    }

    // MARK: - Initialization

    public init(logger: DebugLogger = DebugLogger(subsystem: "com.ritualist.app", category: "general")) {
        self.logger = logger
    }
    
    // MARK: - Public Methods
    
    /// Handles notification response when user taps personality notification
    @MainActor
    public func handleNotificationResponse(_ response: UNNotificationResponse) {
        logger.logNotification(event: "Received personality notification response", type: "personality_analysis")

        guard let userInfo = response.notification.request.content.userInfo as? [String: Any],
              let type = userInfo["type"] as? String,
              type == "personality_analysis" else {
            logger.logNotification(event: "Not a personality_analysis notification", type: "unknown")
            return
        }

        guard let action = userInfo["action"] as? String else {
            logger.logNotification(event: "No action in userInfo", type: "personality_analysis")
            return
        }

        logger.logNotification(event: "Processing action", type: "personality_analysis", metadata: ["action": action])

        // Clear the tapped notification from notification center to prevent badge buildup
        let notificationId = response.notification.request.identifier
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notificationId])

        // Set up navigation state - the view (RootTabView) handles dismiss-then-reshow
        // via its pendingPersonalitySheetReshow pattern if the sheet is already showing
        shouldSwitchTab = true // Notifications should switch to Overview tab

        switch action {
        case "open_analysis":
            let dominantTrait = (userInfo["dominant_trait"] as? String).flatMap(PersonalityTrait.init(fromString:))
            let confidence = (userInfo["confidence"] as? String).flatMap(ConfidenceLevel.init(fromString:))

            logger.logDeepLink(event: "Setting pendingNotificationAction", action: "openAnalysis")

            pendingNotificationAction = .openAnalysis(
                dominantTrait: dominantTrait,
                confidence: confidence
            )

            logger.logPersonality(event: "Triggering personality analysis sheet")

            shouldShowPersonalityAnalysis = true

        case "open_requirements":
            logger.logDeepLink(event: "Setting pendingNotificationAction", action: "openRequirements")

            pendingNotificationAction = .openRequirements
            shouldShowPersonalityAnalysis = true

        case "check_analysis":
            logger.logDeepLink(event: "Setting pendingNotificationAction", action: "checkAnalysis")

            pendingNotificationAction = .checkAnalysis
            shouldShowPersonalityAnalysis = true

        default:
            #if DEBUG
            logger.log("Unknown personality notification action: \(action)", level: .warning, category: .personality)
            #endif
        }
    }
    
    /// Manually triggers navigation to personality analysis (for programmatic use)
    @MainActor
    public func navigateToPersonalityAnalysis() {
        pendingNotificationAction = .openAnalysis(dominantTrait: nil, confidence: nil)
        shouldSwitchTab = true
        shouldShowPersonalityAnalysis = true
    }

    /// Directly shows personality analysis sheet without switching tabs
    @MainActor
    public func showPersonalityAnalysisDirectly() {
        pendingNotificationAction = .directNavigation
        shouldSwitchTab = false
        shouldShowPersonalityAnalysis = true
    }
    
    /// Clears pending navigation state
    @MainActor
    public func clearPendingNavigation() {
        pendingNotificationAction = nil
        shouldShowPersonalityAnalysis = false
        shouldSwitchTab = true // Reset to default
    }
    
    /// Resets only the analysis trigger state, keeping other properties intact
    @MainActor
    public func resetAnalysisState() {
        shouldShowPersonalityAnalysis = false
        // Keep pendingNotificationAction and shouldNavigateToSettings as they are
    }
    
    /// Checks if there's a pending navigation that should trigger
    public func processPendingNavigation() -> Bool {
        if shouldShowPersonalityAnalysis {
            return true
        }
        return false
    }
    
    /// Clears all personality analysis notifications from the notification center
    @MainActor
    public func clearAllPersonalityNotifications() {
        Task {
            let center = UNUserNotificationCenter.current()
            
            // Get all delivered notifications
            let deliveredNotifications = await center.deliveredNotifications()
            
            // Filter for personality analysis notifications
            let personalityNotificationIds = deliveredNotifications.compactMap { (notification: UNNotification) -> String? in
                guard let userInfo = notification.request.content.userInfo as? [String: Any],
                      let type = userInfo["type"] as? String,
                      type == "personality_analysis" else {
                    return nil
                }
                return notification.request.identifier
            }
            
            // Remove them
            center.removeDeliveredNotifications(withIdentifiers: personalityNotificationIds)
            
            // Also remove any pending ones
            center.removePendingNotificationRequests(withIdentifiers: personalityNotificationIds)
        }
    }
}

// MARK: - Helper Extensions

private extension PersonalityTrait {
    init?(fromString string: String) {
        switch string.lowercased() {
        case "openness": self = .openness
        case "conscientiousness": self = .conscientiousness
        case "extraversion": self = .extraversion
        case "agreeableness": self = .agreeableness
        case "neuroticism": self = .neuroticism
        default: return nil
        }
    }
}

private extension ConfidenceLevel {
    init?(fromString string: String) {
        switch string.lowercased() {
        case "high": self = .high
        case "medium": self = .medium
        case "low": self = .low
        case "insufficient": self = .insufficient
        default: return nil
        }
    }
}
