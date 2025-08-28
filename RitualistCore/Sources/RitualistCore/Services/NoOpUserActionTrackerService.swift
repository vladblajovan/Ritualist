//
//  NoOpUserActionTrackerService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import Foundation

public final class NoOpUserActionTrackerService: UserActionTrackerService {
    public init() {}
    
    public func track(_ event: UserActionEvent) {
        // No-op implementation for when no tracking provider is configured
    }
    
    public func track(_ event: UserActionEvent, context: [String: Any]) {
        // No-op implementation
    }
    
    public func setUserProperty(key: String, value: Any) {
        // No-op implementation
    }
    
    public func identifyUser(userId: String, properties: [String: Any]?) {
        // No-op implementation
    }
    
    public func resetUser() {
        // No-op implementation
    }
    
    public func setTrackingEnabled(_ enabled: Bool) {
        // No-op implementation
    }
    
    public func flush() {
        // No-op implementation
    }
}