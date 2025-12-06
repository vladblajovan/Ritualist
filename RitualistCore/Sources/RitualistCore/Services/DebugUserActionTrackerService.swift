//
//  DebugUserActionTrackerService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 30.07.2025.
//

import Foundation

// MARK: - Debug Implementation (Console Logging)

public final class DebugUserActionTrackerService: UserActionTrackerService {
    private var isTrackingEnabled = true
    private var userProperties: [String: Any] = [:]
    private var currentUserId: String?

    private let eventMapper = UserActionEventMapper()
    private let logger: DebugLogger

    public init(logger: DebugLogger = DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "userAction")) {
        self.logger = logger
    }
    
    public func track(_ event: UserActionEvent) {
        track(event, context: [:])
    }
    
    public func track(_ event: UserActionEvent, context: [String: Any]) {
        guard isTrackingEnabled else { return }
        
        let eventName = eventMapper.eventName(for: event)
        var eventProperties = eventMapper.eventProperties(for: event)
        
        // Merge context into properties
        for (key, value) in context {
            eventProperties[key] = value
        }
        
        logger.logEvent(
            name: eventName,
            properties: eventProperties,
            userId: currentUserId,
            userProperties: userProperties
        )
    }
    
    public func setUserProperty(key: String, value: Any) {
        guard isTrackingEnabled else { return }
        userProperties[key] = value
        logger.logUserProperty(key: key, value: value)
    }
    
    public func identifyUser(userId: String, properties: [String: Any]?) {
        guard isTrackingEnabled else { return }
        currentUserId = userId
        if let properties = properties {
            for (key, value) in properties {
                userProperties[key] = value
            }
        }
        logger.logUserIdentified(userId: userId, properties: properties)
    }
    
    public func resetUser() {
        guard isTrackingEnabled else { return }
        currentUserId = nil
        userProperties.removeAll()
        logger.logUserReset()
    }
    
    public func setTrackingEnabled(_ enabled: Bool) {
        isTrackingEnabled = enabled
        logger.logTrackingStateChanged(enabled: enabled)
    }
    
    public func flush() {
        guard isTrackingEnabled else { return }
        logger.logFlushRequested()
    }
}