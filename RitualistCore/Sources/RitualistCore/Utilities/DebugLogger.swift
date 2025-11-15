import Foundation
import os.log

// MARK: - Log Level and Category

public enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
    
    public var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }
}

public enum LogCategory: String, CaseIterable {
    case userAction = "UserAction"
    case authentication = "Auth"
    case subscription = "Subscription"
    case stateManagement = "State"
    case errorRecovery = "Recovery"
    case healthMonitoring = "Health"
    case dataIntegrity = "Data"
    case performance = "Performance"
    case network = "Network"
    case ui = "UI"
    case system = "System"
    case personality = "Personality"
    case notifications = "Notifications"
    case deepLinking = "DeepLinking"
    case navigation = "Navigation"
    case location = "Location"
    case debug = "Debug"
}

// MARK: - Enhanced Debug Logger

/// Enhanced logging system for debugging and diagnostics
public final class DebugLogger {
    
    // OS Logging
    private let osLog: OSLog
    private let isProductionBuild: Bool
    
    // In-memory log buffer for diagnostics
    private var logBuffer: [LogEntry] = []
    private let maxBufferSize = 1000
    private let bufferLock = NSLock()
    
    // Log entry structure
    private struct LogEntry {
        let timestamp: Date
        let level: LogLevel
        let category: LogCategory
        let message: String
        let metadata: [String: Any]?
        
        var formattedMessage: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            let timestampStr = formatter.string(from: timestamp)
            
            var result = "[\(timestampStr)] [\(level.rawValue)] [\(category.rawValue)] \(message)"
            
            if let metadata = metadata, !metadata.isEmpty {
                result += " | Metadata: \(metadata)"
            }
            
            return result
        }
    }
    
    public init(subsystem: String = "com.ritualist.app", category: String = "general") {
        self.osLog = OSLog(subsystem: subsystem, category: category)
        
        #if DEBUG
        self.isProductionBuild = false
        #else
        self.isProductionBuild = true
        #endif
    }
    
    // MARK: - Enhanced Logging Methods
    
    /// Primary logging method with full metadata support
    public func log(
        _ message: String,
        level: LogLevel = .info,
        category: LogCategory = .system,
        metadata: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            message: message,
            metadata: metadata
        )
        
        // Add to buffer
        addToBuffer(entry)
        
        // Console output for debug builds or critical logs
        if !isProductionBuild || level == .critical || level == .error {
            let emoji = emojiForLevel(level)
            print("\(emoji) \(entry.formattedMessage)")
        }
        
        // OS Log
        os_log("%{public}@", log: osLog, type: level.osLogType, entry.formattedMessage)
    }
    
    /// Convenience method for simple logging (maintains backward compatibility)
    public func log(_ message: String) {
        log(message, level: .info, category: .system)
    }
    
    /// Log performance metrics
    public func logPerformance(
        operation: String,
        duration: TimeInterval,
        metadata: [String: Any]? = nil
    ) {
        var perfMetadata = metadata ?? [:]
        perfMetadata["duration_ms"] = duration * 1000
        perfMetadata["operation"] = operation
        
        let level: LogLevel = duration > 1.0 ? .warning : .info
        log("Performance: \(operation) took \(String(format: "%.3f", duration))s", 
            level: level, 
            category: .performance, 
            metadata: perfMetadata)
    }
    
    /// Log state transitions
    public func logStateTransition(
        from: String,
        to: String,
        context: [String: Any]? = nil
    ) {
        var metadata = context ?? [:]
        metadata["from_state"] = from
        metadata["to_state"] = to
        
        log("State transition: \(from) → \(to)", 
            level: .info, 
            category: .stateManagement, 
            metadata: metadata)
    }
    
    /// Log error with recovery context
    public func logError(
        _ error: Error,
        context: String? = nil,
        recoveryAttempted: Bool = false,
        recoverySuccessful: Bool = false,
        metadata: [String: Any]? = nil
    ) {
        var errorMetadata = metadata ?? [:]
        errorMetadata["error_description"] = error.localizedDescription
        errorMetadata["error_type"] = String(describing: type(of: error))
        errorMetadata["recovery_attempted"] = recoveryAttempted
        errorMetadata["recovery_successful"] = recoverySuccessful
        
        if let context = context {
            errorMetadata["context"] = context
        }
        
        let message = context != nil ? "\(context!): \(error.localizedDescription)" : error.localizedDescription
        log(message, level: .error, category: .errorRecovery, metadata: errorMetadata)
    }
    
    /// Log authentication events
    public func logAuth(
        event: String,
        userId: String? = nil,
        success: Bool = true,
        metadata: [String: Any]? = nil
    ) {
        var authMetadata = metadata ?? [:]
        authMetadata["auth_event"] = event
        authMetadata["success"] = success
        
        if let userId = userId {
            authMetadata["user_id"] = userId
        }
        
        let level: LogLevel = success ? .info : .warning
        log("Auth: \(event)", level: level, category: .authentication, metadata: authMetadata)
    }
    
    /// Log subscription events
    public func logSubscription(
        event: String,
        plan: String? = nil,
        success: Bool = true,
        metadata: [String: Any]? = nil
    ) {
        var subMetadata = metadata ?? [:]
        subMetadata["subscription_event"] = event
        subMetadata["success"] = success
        
        if let plan = plan {
            subMetadata["plan"] = plan
        }
        
        let level: LogLevel = success ? .info : .warning
        log("Subscription: \(event)", level: level, category: .subscription, metadata: subMetadata)
    }
    
    /// Log health monitoring events
    public func logHealth(
        status: String,
        component: String,
        details: [String: Any]? = nil
    ) {
        var healthMetadata = details ?? [:]
        healthMetadata["component"] = component
        healthMetadata["health_status"] = status
        
        let level: LogLevel = status.lowercased().contains("critical") ? .critical :
                              status.lowercased().contains("warning") ? .warning : .info
        
        log("Health: \(component) - \(status)", level: level, category: .healthMonitoring, metadata: healthMetadata)
    }
    
    /// Log data integrity events
    public func logDataIntegrity(
        check: String,
        passed: Bool,
        issues: [String]? = nil,
        metadata: [String: Any]? = nil
    ) {
        var dataMetadata = metadata ?? [:]
        dataMetadata["integrity_check"] = check
        dataMetadata["passed"] = passed
        
        if let issues = issues {
            dataMetadata["issues"] = issues
        }
        
        let level: LogLevel = passed ? .info : (issues?.count ?? 0 > 0 ? .warning : .error)
        let message = passed ? "Data integrity check passed: \(check)" : 
                               "Data integrity issues in \(check): \(issues?.joined(separator: ", ") ?? "unknown")"
        
        log(message, level: level, category: .dataIntegrity, metadata: dataMetadata)
    }
    
    // MARK: - Legacy UserActionTracker Methods (for backward compatibility)
    
    /// Log an event with properties and user context
    public func logEvent(
        name: String,
        properties: [String: Any],
        userId: String?,
        userProperties: [String: Any]
    ) {
        var metadata = properties
        metadata["user_id"] = userId
        metadata["user_properties"] = userProperties
        
        log("Event: \(name)", level: .info, category: .userAction, metadata: metadata)
    }
    
    /// Log user property changes
    public func logUserProperty(key: String, value: Any) {
        let metadata = ["property_key": key, "property_value": value]
        log("User property set: \(key) = \(value)", level: .info, category: .userAction, metadata: metadata)
    }
    
    /// Log user identification
    public func logUserIdentified(userId: String, properties: [String: Any]?) {
        var metadata: [String: Any] = ["user_id": userId]
        if let properties = properties {
            metadata["initial_properties"] = properties
        }
        log("User identified: \(userId)", level: .info, category: .userAction, metadata: metadata)
    }
    
    /// Log user reset
    public func logUserReset() {
        log("User reset", level: .info, category: .userAction)
    }
    
    /// Log tracking state changes
    public func logTrackingStateChanged(enabled: Bool) {
        let metadata = ["tracking_enabled": enabled]
        log("Tracking \(enabled ? "enabled" : "disabled")", level: .info, category: .userAction, metadata: metadata)
    }
    
    /// Log flush requests
    public func logFlushRequested() {
        log("Flush requested", level: .info, category: .userAction)
    }

    // MARK: - Personality Analysis Logging

    /// Log personality analysis events
    public func logPersonality(
        event: String,
        context: [String: Any]? = nil
    ) {
        log("PersonalityAnalysis: \(event)", level: .debug, category: .personality, metadata: context)
    }

    /// Log personality analysis sheet state changes
    public func logPersonalitySheet(
        state: String,
        shouldSwitchTab: Bool? = nil,
        currentTab: String? = nil,
        metadata: [String: Any]? = nil
    ) {
        var context = metadata ?? [:]
        if let shouldSwitchTab = shouldSwitchTab {
            context["should_switch_tab"] = shouldSwitchTab
        }
        if let currentTab = currentTab {
            context["current_tab"] = currentTab
        }

        log("PersonalityAnalysis: \(state)", level: .debug, category: .personality, metadata: context)
    }

    // MARK: - Notification Logging

    /// Log notification events
    public func logNotification(
        event: String,
        type: String? = nil,
        habitId: String? = nil,
        metadata: [String: Any]? = nil
    ) {
        var notifMetadata = metadata ?? [:]
        if let type = type {
            notifMetadata["notification_type"] = type
        }
        if let habitId = habitId {
            notifMetadata["habit_id"] = habitId
        }

        log("Notification: \(event)", level: .debug, category: .notifications, metadata: notifMetadata)
    }

    // MARK: - Navigation \u0026 Deep Linking

    /// Log navigation events
    public func logNavigation(
        event: String,
        from: String? = nil,
        to: String? = nil,
        metadata: [String: Any]? = nil
    ) {
        var navMetadata = metadata ?? [:]
        if let from = from {
            navMetadata["from"] = from
        }
        if let to = to {
            navMetadata["to"] = to
        }

        log("Navigation: \(event)", level: .debug, category: .navigation, metadata: navMetadata)
    }

    /// Log deep link handling
    public func logDeepLink(
        event: String,
        url: String? = nil,
        action: String? = nil,
        metadata: [String: Any]? = nil
    ) {
        var linkMetadata = metadata ?? [:]
        if let url = url {
            linkMetadata["url"] = url
        }
        if let action = action {
            linkMetadata["action"] = action
        }

        log("DeepLink: \(event)", level: .debug, category: .deepLinking, metadata: linkMetadata)
    }

    // MARK: - Diagnostics and Export
    
    /// Get recent logs for diagnostics
    public func getRecentLogs(limit: Int = 100, level: LogLevel? = nil, category: LogCategory? = nil) -> [String] {
        bufferLock.lock()
        defer { bufferLock.unlock() }
        
        var filteredLogs = logBuffer
        
        if let level = level {
            filteredLogs = filteredLogs.filter { $0.level == level }
        }
        
        if let category = category {
            filteredLogs = filteredLogs.filter { $0.category == category }
        }
        
        return Array(filteredLogs.suffix(limit)).map { $0.formattedMessage }
    }
    
    /// Export logs as string for debugging
    public func exportLogs(level: LogLevel? = nil, category: LogCategory? = nil) -> String {
        let logs = getRecentLogs(limit: maxBufferSize, level: level, category: category)
        return logs.joined(separator: "\n")
    }
    
    /// Clear log buffer
    public func clearLogs() {
        bufferLock.lock()
        defer { bufferLock.unlock() }
        
        logBuffer.removeAll()
        log("Log buffer cleared", level: .info, category: .system)
    }
    
    /// Get log statistics
    public func getLogStatistics() -> [String: Any] {
        bufferLock.lock()
        defer { bufferLock.unlock() }
        
        var stats: [String: Any] = [:]
        stats["total_logs"] = logBuffer.count
        stats["buffer_size"] = maxBufferSize
        
        // Count by level
        var levelCounts: [String: Int] = [:]
        for level in LogLevel.allCases {
            levelCounts[level.rawValue] = logBuffer.filter { $0.level == level }.count
        }
        stats["level_counts"] = levelCounts
        
        // Count by category
        var categoryCounts: [String: Int] = [:]
        for category in LogCategory.allCases {
            categoryCounts[category.rawValue] = logBuffer.filter { $0.category == category }.count
        }
        stats["category_counts"] = categoryCounts
        
        return stats
    }
    
    // MARK: - Private Methods
    
    private func addToBuffer(_ entry: LogEntry) {
        bufferLock.lock()
        defer { bufferLock.unlock() }
        
        logBuffer.append(entry)
        
        // Maintain buffer size
        if logBuffer.count > maxBufferSize {
            logBuffer.removeFirst(logBuffer.count - maxBufferSize)
        }
    }
    
    private func emojiForLevel(_ level: LogLevel) -> String {
        switch level {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🚨"
        }
    }
}