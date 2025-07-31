import Foundation

/// Helper class for debug logging in DebugUserActionTracker
public final class DebugLogger {
    
    public init() {}
    
    /// Log an event with properties and user context
    public func logEvent(
        name: String,
        properties: [String: Any],
        userId: String?,
        userProperties: [String: Any]
    ) {
        print("🔍 [UserActionTracker] Event: \(name)")
        
        if !properties.isEmpty {
            print("   Properties: \(properties)")
        }
        
        if let userId = userId {
            print("   User: \(userId)")
        }
        
        if !userProperties.isEmpty {
            print("   User Properties: \(userProperties)")
        }
    }
    
    /// Log user property changes
    public func logUserProperty(key: String, value: Any) {
        print("🔍 [UserActionTracker] User Property Set: \(key) = \(value)")
    }
    
    /// Log user identification
    public func logUserIdentified(userId: String, properties: [String: Any]?) {
        print("🔍 [UserActionTracker] User Identified: \(userId)")
        if let properties = properties {
            print("   Initial Properties: \(properties)")
        }
    }
    
    /// Log user reset
    public func logUserReset() {
        print("🔍 [UserActionTracker] User Reset")
    }
    
    /// Log tracking state changes
    public func logTrackingStateChanged(enabled: Bool) {
        print("🔍 [UserActionTracker] Tracking \(enabled ? "Enabled" : "Disabled")")
    }
    
    /// Log flush requests
    public func logFlushRequested() {
        print("🔍 [UserActionTracker] Flush Requested")
    }
}