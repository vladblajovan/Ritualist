//
//  UserActionTrackerService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//

import Foundation

public protocol UserActionTrackerService {
    /// Track a user action event
    func track(_ event: UserActionEvent)
    
    /// Track a user action event with additional context
    func track(_ event: UserActionEvent, context: [String: Any])
    
    /// Set user properties (for analytics segmentation)
    func setUserProperty(key: String, value: Any)
    
    /// Identify the user (when user creates account or logs in)
    func identifyUser(userId: String, properties: [String: Any]?)
    
    /// Reset user identity (on logout)
    func resetUser()
    
    /// Enable/disable tracking (for privacy compliance)
    func setTrackingEnabled(_ enabled: Bool)
    
    /// Flush any pending events (useful before app backgrounding)
    func flush()
}
