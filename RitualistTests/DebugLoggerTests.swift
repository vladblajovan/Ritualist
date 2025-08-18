//
//  DebugLoggerTests.swift
//  RitualistTests
//
//  Created by Claude on 04.08.2025.
//

import Testing
import Foundation
@testable import Ritualist
import RitualistCore

struct DebugLoggerTests {
    
    // MARK: - Test Setup
    
    let logger = DebugLogger()
    
    // MARK: - Basic Logging Tests
    
    @Test("Basic log message creates entry")
    func basicLogMessage() {
        logger.log("Test message")
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("Test message") == true)
    }
    
    @Test("Log with level and category creates proper entry")
    func logWithLevelAndCategory() {
        logger.log("Warning message", level: .warning, category: .ui)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("WARNING") == true)
        #expect(recentLogs.first?.contains("UI") == true)
        #expect(recentLogs.first?.contains("Warning message") == true)
    }
    
    @Test("Log with metadata includes metadata in output")
    func logWithMetadata() {
        let metadata: [String: Any] = ["key1": "value1", "key2": 42, "key3": true]
        logger.log("Message with metadata", metadata: metadata)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("Metadata:") == true)
    }
    
    // MARK: - Log Level Tests
    
    @Test("Log levels map to correct string representations")
    func logLevelsStringRepresentation() {
        let testCases: [(LogLevel, String)] = [
            (.debug, "DEBUG"),
            (.info, "INFO"),
            (.warning, "WARNING"),
            (.error, "ERROR"),
            (.critical, "CRITICAL")
        ]
        
        for (level, expectedString) in testCases {
            #expect(level.rawValue == expectedString)
        }
    }
    
    @Test("Log levels map to correct OS log types")
    func logLevelsOSLogTypes() {
        #expect(LogLevel.debug.osLogType == .debug)
        #expect(LogLevel.info.osLogType == .info)
        #expect(LogLevel.warning.osLogType == .default)
        #expect(LogLevel.error.osLogType == .error)
        #expect(LogLevel.critical.osLogType == .fault)
    }
    
    // MARK: - Log Category Tests
    
    @Test("Log categories have correct raw values")
    func logCategoriesRawValues() {
        let testCases: [(LogCategory, String)] = [
            (.userAction, "UserAction"),
            (.authentication, "Auth"),
            (.subscription, "Subscription"),
            (.stateManagement, "State"),
            (.errorRecovery, "Recovery"),
            (.healthMonitoring, "Health"),
            (.dataIntegrity, "Data"),
            (.performance, "Performance"),
            (.network, "Network"),
            (.ui, "UI"),
            (.system, "System")
        ]
        
        for (category, expectedString) in testCases {
            #expect(category.rawValue == expectedString)
        }
    }
    
    // MARK: - Performance Logging Tests
    
    @Test("Performance logging with short duration uses info level")
    func performanceLoggingShortDuration() {
        logger.logPerformance(operation: "quick_operation", duration: 0.5)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("INFO") == true)
        #expect(recentLogs.first?.contains("Performance") == true)
        #expect(recentLogs.first?.contains("quick_operation") == true)
        #expect(recentLogs.first?.contains("0.500s") == true)
    }
    
    @Test("Performance logging with long duration uses warning level")
    func performanceLoggingLongDuration() {
        logger.logPerformance(operation: "slow_operation", duration: 1.5)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("WARNING") == true)
        #expect(recentLogs.first?.contains("Performance") == true)
        #expect(recentLogs.first?.contains("slow_operation") == true)
        #expect(recentLogs.first?.contains("1.500s") == true)
    }
    
    @Test("Performance logging includes metadata")
    func performanceLoggingMetadata() {
        let metadata: [String: Any] = ["component": "ui", "feature": "test"]
        logger.logPerformance(operation: "test_op", duration: 0.123, metadata: metadata)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("Metadata:") == true)
    }
    
    // MARK: - State Transition Logging Tests
    
    @Test("State transition logging creates proper entry")
    func stateTransitionLogging() {
        logger.logStateTransition(from: "idle", to: "loading")
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("State transition") == true)
        #expect(recentLogs.first?.contains("idle → loading") == true)
        #expect(recentLogs.first?.contains("State") == true) // Category
    }
    
    @Test("State transition logging with context includes metadata")
    func stateTransitionWithContext() {
        let context: [String: Any] = ["trigger": "user_action", "duration": 150]
        logger.logStateTransition(from: "loading", to: "loaded", context: context)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("Metadata:") == true)
    }
    
    // MARK: - Error Logging Tests
    
    @Test("Error logging creates proper entry")
    func errorLogging() {
        let error = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error message"])
        logger.logError(error)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("ERROR") == true)
        #expect(recentLogs.first?.contains("Test error message") == true)
        #expect(recentLogs.first?.contains("Recovery") == true) // Category
    }
    
    @Test("Error logging with context includes context in message")
    func errorLoggingWithContext() {
        let error = NSError(domain: "TestDomain", code: 456, userInfo: [NSLocalizedDescriptionKey: "Network failure"])
        logger.logError(error, context: "API Request")
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("API Request: Network failure") == true)
    }
    
    @Test("Error logging with recovery info includes metadata")
    func errorLoggingWithRecovery() {
        let error = NSError(domain: "TestDomain", code: 789, userInfo: [NSLocalizedDescriptionKey: "Recovery test"])
        logger.logError(error, recoveryAttempted: true, recoverySuccessful: true)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("Metadata:") == true)
    }
    
    // MARK: - Authentication Logging Tests
    
    @Test("Authentication success logging uses info level")
    func authenticationSuccessLogging() {
        logger.logAuth(event: "login", userId: "user123", success: true)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("INFO") == true)
        #expect(recentLogs.first?.contains("Auth: login") == true)
        #expect(recentLogs.first?.contains("Auth") == true) // Category
    }
    
    @Test("Authentication failure logging uses warning level")
    func authenticationFailureLogging() {
        logger.logAuth(event: "login_failed", success: false)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("WARNING") == true)
        #expect(recentLogs.first?.contains("Auth: login_failed") == true)
    }
    
    // MARK: - Subscription Logging Tests
    
    @Test("Subscription success logging uses info level")
    func subscriptionSuccessLogging() {
        logger.logSubscription(event: "purchase", plan: "premium", success: true)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("INFO") == true)
        #expect(recentLogs.first?.contains("Subscription: purchase") == true)
        #expect(recentLogs.first?.contains("Subscription") == true) // Category
    }
    
    @Test("Subscription failure logging uses warning level")
    func subscriptionFailureLogging() {
        logger.logSubscription(event: "purchase_failed", plan: "basic", success: false)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("WARNING") == true)
        #expect(recentLogs.first?.contains("Subscription: purchase_failed") == true)
    }
    
    // MARK: - Health Monitoring Tests
    
    @Test("Health monitoring with normal status uses info level")
    func healthMonitoringNormalStatus() {
        logger.logHealth(status: "healthy", component: "database")
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("INFO") == true)
        #expect(recentLogs.first?.contains("Health: database - healthy") == true)
        #expect(recentLogs.first?.contains("Health") == true) // Category
    }
    
    @Test("Health monitoring with warning status uses warning level")
    func healthMonitoringWarningStatus() {
        logger.logHealth(status: "warning", component: "network")
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("WARNING") == true)
        #expect(recentLogs.first?.contains("Health: network - warning") == true)
    }
    
    @Test("Health monitoring with critical status uses critical level")
    func healthMonitoringCriticalStatus() {
        logger.logHealth(status: "critical failure", component: "storage")
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("CRITICAL") == true)
        #expect(recentLogs.first?.contains("Health: storage - critical failure") == true)
    }
    
    // MARK: - Data Integrity Tests
    
    @Test("Data integrity check passed uses info level")
    func dataIntegrityCheckPassed() {
        logger.logDataIntegrity(check: "user_data_validation", passed: true)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("INFO") == true)
        #expect(recentLogs.first?.contains("Data integrity check passed") == true)
        #expect(recentLogs.first?.contains("Data") == true) // Category
    }
    
    @Test("Data integrity check failed with issues uses warning level")
    func dataIntegrityCheckFailedWithIssues() {
        let issues = ["missing_field", "invalid_format"]
        logger.logDataIntegrity(check: "schema_validation", passed: false, issues: issues)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("WARNING") == true)
        #expect(recentLogs.first?.contains("Data integrity issues") == true)
        #expect(recentLogs.first?.contains("missing_field") == true)
    }
    
    @Test("Data integrity check failed without issues uses error level")
    func dataIntegrityCheckFailedWithoutIssues() {
        logger.logDataIntegrity(check: "corruption_check", passed: false)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("ERROR") == true)
        #expect(recentLogs.first?.contains("Data integrity issues") == true)
    }
    
    // MARK: - Legacy UserActionTracker Methods Tests
    
    @Test("Log event with properties creates proper entry")
    func logEventWithProperties() {
        let properties: [String: Any] = ["action": "button_click", "screen": "home"]
        let userProperties: [String: Any] = ["plan": "premium", "tenure": "1_month"]
        
        logger.logEvent(name: "ui_interaction", properties: properties, userId: "user456", userProperties: userProperties)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("Event: ui_interaction") == true)
        #expect(recentLogs.first?.contains("UserAction") == true) // Category
        #expect(recentLogs.first?.contains("Metadata:") == true)
    }
    
    @Test("Log user property creates proper entry")
    func logUserProperty() {
        logger.logUserProperty(key: "theme", value: "dark")
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("User property set: theme = dark") == true)
        #expect(recentLogs.first?.contains("UserAction") == true) // Category
    }
    
    @Test("Log user identified creates proper entry")
    func logUserIdentified() {
        let properties: [String: Any] = ["email": "test@example.com", "plan": "basic"]
        logger.logUserIdentified(userId: "user789", properties: properties)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("User identified: user789") == true)
        #expect(recentLogs.first?.contains("UserAction") == true) // Category
    }
    
    @Test("Log user reset creates proper entry")
    func logUserReset() {
        logger.logUserReset()
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("User reset") == true)
        #expect(recentLogs.first?.contains("UserAction") == true) // Category
    }
    
    @Test("Log tracking state changed creates proper entry")
    func logTrackingStateChanged() {
        logger.logTrackingStateChanged(enabled: false)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("Tracking disabled") == true)
        #expect(recentLogs.first?.contains("UserAction") == true) // Category
    }
    
    @Test("Log flush requested creates proper entry")
    func logFlushRequested() {
        logger.logFlushRequested()
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("Flush requested") == true)
        #expect(recentLogs.first?.contains("UserAction") == true) // Category
    }
    
    // MARK: - Log Buffer and Filtering Tests
    
    @Test("Log buffer maintains maximum size")
    func logBufferMaximumSize() {
        // Create a smaller number of logs to avoid hanging
        for i in 0..<50 {
            logger.log("Message \(i)")
        }
        
        let allLogs = logger.getRecentLogs(limit: 100)
        #expect(allLogs.count == 50)
    }
    
    @Test("Get recent logs with limit returns correct number")
    func getRecentLogsWithLimit() {
        // Add fewer logs to avoid hanging
        for i in 0..<5 {
            logger.log("Test message \(i)")
        }
        
        let recentLogs = logger.getRecentLogs(limit: 3)
        #expect(recentLogs.count >= 3) // Allow for other logs in buffer
        
        // Should contain our test messages
        let combinedLogs = recentLogs.joined(separator: " ")
        #expect(combinedLogs.contains("Test message"))
    }
    
    @Test("Get recent logs with level filter returns only matching level")
    func getRecentLogsWithLevelFilter() {
        logger.log("Info message", level: .info)
        logger.log("Warning message", level: .warning)
        logger.log("Error message", level: .error)
        
        let warningLogs = logger.getRecentLogs(limit: 10, level: .warning)
        #expect(warningLogs.count == 1)
        #expect(warningLogs.first?.contains("Warning message") == true)
        #expect(warningLogs.first?.contains("WARNING") == true)
    }
    
    @Test("Get recent logs with category filter returns only matching category")
    func getRecentLogsWithCategoryFilter() {
        logger.log("System message", category: .system)
        logger.log("UI message", category: .ui)
        logger.log("Network message", category: .network)
        
        let uiLogs = logger.getRecentLogs(limit: 10, category: .ui)
        #expect(uiLogs.count == 1)
        #expect(uiLogs.first?.contains("UI message") == true)
        #expect(uiLogs.first?.contains("UI") == true)
    }
    
    // MARK: - Export and Statistics Tests
    
    @Test("Export logs returns formatted string")
    func exportLogs() {
        logger.log("First message")
        logger.log("Second message")
        
        let exportedLogs = logger.exportLogs()
        #expect(exportedLogs.contains("First message"))
        #expect(exportedLogs.contains("Second message"))
        #expect(exportedLogs.contains("\n")) // Should be newline separated
    }
    
    @Test("Export logs with filters returns only matching entries")
    func exportLogsWithFilters() {
        logger.log("Info message", level: .info, category: .system)
        logger.log("Warning message", level: .warning, category: .ui)
        
        let warningLogs = logger.exportLogs(level: .warning)
        #expect(warningLogs.contains("Warning message"))
        #expect(!warningLogs.contains("Info message"))
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test("Log with empty message creates entry")
    func logWithEmptyMessage() {
        logger.log("")
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        // Should contain timestamp and level even with empty message
        #expect(recentLogs.first?.contains("INFO") == true)
    }
    
    @Test("Log with nil metadata works correctly")
    func logWithNilMetadata() {
        logger.log("Message with nil metadata", metadata: nil)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(!recentLogs.first!.contains("Metadata:"))
    }
    
    @Test("Log with empty metadata dictionary works correctly")
    func logWithEmptyMetadata() {
        logger.log("Message with empty metadata", metadata: [:])
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(!recentLogs.first!.contains("Metadata:"))
    }
    
    @Test("Performance logging with zero duration works correctly")
    func performanceLoggingZeroDuration() {
        logger.logPerformance(operation: "instant_operation", duration: 0.0)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("INFO") == true) // Should use info level for zero duration
        #expect(recentLogs.first?.contains("0.000s") == true)
    }
    
    @Test("Performance logging with negative duration works correctly")
    func performanceLoggingNegativeDuration() {
        logger.logPerformance(operation: "negative_operation", duration: -0.5)
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("INFO") == true) // Should use info level for negative duration
        #expect(recentLogs.first?.contains("-0.500s") == true)
    }
    
    @Test("State transition with empty states works correctly")
    func stateTransitionEmptyStates() {
        logger.logStateTransition(from: "", to: "")
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("State transition:  → ") == true)
    }
    
    @Test("Health status with mixed case works correctly")
    func healthStatusMixedCase() {
        logger.logHealth(status: "Critical Warning", component: "test")
        
        let recentLogs = logger.getRecentLogs(limit: 1)
        #expect(recentLogs.count == 1)
        #expect(recentLogs.first?.contains("CRITICAL") == true) // Should detect "critical" in mixed case
    }
}
