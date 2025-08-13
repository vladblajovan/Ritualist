//
//  PersonalityDeepLinkCoordinator.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation
import SwiftUI
import UserNotifications

/// Coordinates deep linking for personality analysis notifications
public final class PersonalityDeepLinkCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var shouldShowPersonalityAnalysis = false
    @Published public var pendingNotificationAction: PersonalityNotificationAction?
    @Published public var shouldNavigateToSettings = true // Controls whether to switch to Settings tab
    
    // MARK: - Types
    
    public enum PersonalityNotificationAction {
        case openAnalysis(dominantTrait: PersonalityTrait?, confidence: ConfidenceLevel?)
        case openRequirements
        case checkAnalysis
        case directNavigation // For direct navigation without notification context
    }
    
    // MARK: - Singleton
    
    public static let shared = PersonalityDeepLinkCoordinator()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Handles notification response when user taps personality notification
    @MainActor
    public func handleNotificationResponse(_ response: UNNotificationResponse) {
        guard let userInfo = response.notification.request.content.userInfo as? [String: Any],
              let type = userInfo["type"] as? String,
              type == "personality_analysis" else {
            return
        }
        
        guard let action = userInfo["action"] as? String else {
            return
        }
        
        // Clear the tapped notification from notification center to prevent badge buildup
        let notificationId = response.notification.request.identifier
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notificationId])
        
        // Force reset state to ensure SwiftUI detects changes
        shouldShowPersonalityAnalysis = false
        pendingNotificationAction = nil
        shouldNavigateToSettings = true // Notifications should navigate to Settings
        
        // Use async dispatch with small delay to make the dismiss/reopen visually apparent
        Task { @MainActor in
            // Small delay to make the sheet dismiss visible
            try? await Task.sleep(for: .milliseconds(200))
            switch action {
            case "open_analysis":
                let dominantTrait = (userInfo["dominant_trait"] as? String).flatMap(PersonalityTrait.init(fromString:))
                let confidence = (userInfo["confidence"] as? String).flatMap(ConfidenceLevel.init(fromString:))
                
                pendingNotificationAction = .openAnalysis(
                    dominantTrait: dominantTrait, 
                    confidence: confidence
                )
                shouldShowPersonalityAnalysis = true
                
            case "open_requirements":
                pendingNotificationAction = .openRequirements
                shouldShowPersonalityAnalysis = true
                
            case "check_analysis":
                pendingNotificationAction = .checkAnalysis
                shouldShowPersonalityAnalysis = true
                
            default:
                print("⚠️ Unknown personality notification action: \(action)")
            }
        }
    }
    
    /// Manually triggers navigation to personality analysis (for programmatic use)
    @MainActor
    public func navigateToPersonalityAnalysis() {
        pendingNotificationAction = .openAnalysis(dominantTrait: nil, confidence: nil)
        shouldNavigateToSettings = true
        shouldShowPersonalityAnalysis = true
    }
    
    /// Directly shows personality analysis sheet without navigating to Settings
    @MainActor
    public func showPersonalityAnalysisDirectly() {
        pendingNotificationAction = .directNavigation
        shouldNavigateToSettings = false
        shouldShowPersonalityAnalysis = true
    }
    
    /// Clears pending navigation state
    @MainActor
    public func clearPendingNavigation() {
        pendingNotificationAction = nil
        shouldShowPersonalityAnalysis = false
        shouldNavigateToSettings = true // Reset to default
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