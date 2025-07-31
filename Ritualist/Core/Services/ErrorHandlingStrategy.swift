import Foundation
import Combine

// MARK: - Error Classification

public enum ErrorSeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

public enum ErrorCategory: String, CaseIterable {
    case authentication = "authentication"
    case subscription = "subscription"
    case data = "data"
    case network = "network"
    case ui = "ui"
    case system = "system"
    case unknown = "unknown"
}

public struct ErrorContext {
    public let userID: String?
    public let sessionID: String
    public let appVersion: String
    public let platform: String
    public let timestamp: Date
    public let userAction: String?
    public let additionalInfo: [String: Any]
    
    public init(
        userID: String? = nil,
        sessionID: String = UUID().uuidString,
        appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
        platform: String = "iOS",
        timestamp: Date = Date(),
        userAction: String? = nil,
        additionalInfo: [String: Any] = [:]
    ) {
        self.userID = userID
        self.sessionID = sessionID
        self.appVersion = appVersion
        self.platform = platform
        self.timestamp = timestamp
        self.userAction = userAction
        self.additionalInfo = additionalInfo
    }
}

public struct ErrorReport {
    public let error: Error
    public let category: ErrorCategory
    public let severity: ErrorSeverity
    public let context: ErrorContext
    public let recoveryAttempted: Bool
    public let recoverySuccessful: Bool
    public let id: String
    
    public init(
        error: Error,
        category: ErrorCategory,
        severity: ErrorSeverity,
        context: ErrorContext,
        recoveryAttempted: Bool = false,
        recoverySuccessful: Bool = false
    ) {
        self.error = error
        self.category = category
        self.severity = severity
        self.context = context
        self.recoveryAttempted = recoveryAttempted
        self.recoverySuccessful = recoverySuccessful
        self.id = UUID().uuidString
    }
}

// MARK: - Error Handling Strategy Protocol

public protocol ErrorHandlingStrategyProtocol {
    /// Process an error with full strategy (classification, recovery, reporting)
    func handleError(_ error: Error, context: ErrorContext?) async -> ErrorReport
    
    /// Classify an error into category and severity
    func classifyError(_ error: Error) -> (category: ErrorCategory, severity: ErrorSeverity)
    
    /// Determine if an error should trigger recovery
    func shouldAttemptRecovery(for error: Error, severity: ErrorSeverity) -> Bool
    
    /// Create user-facing error message
    func createUserMessage(for error: Error, severity: ErrorSeverity) -> String
    
    /// Get error reports for analysis
    func getErrorReports(limit: Int?) -> [ErrorReport]
    
    /// Clear error reports
    func clearErrorReports()
}

// MARK: - Error Handling Strategy Implementation

public final class ErrorHandlingStrategy: ErrorHandlingStrategyProtocol {
    
    // Dependencies
    private let recoveryService: ErrorRecoveryServiceProtocol
    private let validationService: StateValidationServiceProtocol
    private let healthMonitor: any SystemHealthMonitorProtocol
    private let logger: DebugLogger
    private let userSession: any UserSessionProtocol
    
    // Error tracking
    private var errorReports: [ErrorReport] = []
    private let maxReports = 1000
    
    // Session context
    private let sessionID = UUID().uuidString
    
    public init(
        recoveryService: ErrorRecoveryServiceProtocol,
        validationService: StateValidationServiceProtocol,
        healthMonitor: any SystemHealthMonitorProtocol,
        logger: DebugLogger,
        userSession: any UserSessionProtocol
    ) {
        self.recoveryService = recoveryService
        self.validationService = validationService
        self.healthMonitor = healthMonitor
        self.logger = logger
        self.userSession = userSession
    }
    
    // MARK: - Main Error Handling
    
    public func handleError(_ error: Error, context: ErrorContext? = nil) async -> ErrorReport {
        let startTime = Date()
        
        // Create context if not provided
        let errorContext = context ?? createDefaultContext()
        
        // Classify the error
        let (category, severity) = classifyError(error)
        
        logger.log("Handling \(severity.rawValue) \(category.rawValue) error: \(error.localizedDescription)")
        
        // Record error in health monitor
        await healthMonitor.recordError(error)
        
        // Determine if recovery should be attempted
        let shouldRecover = shouldAttemptRecovery(for: error, severity: severity)
        
        var recoveryAttempted = false
        var recoverySuccessful = false
        
        // Attempt recovery if appropriate
        if shouldRecover {
            recoveryAttempted = true
            let recoveryResult = await attemptRecovery(for: error, category: category)
            recoverySuccessful = recoveryResult.isSuccessful
            
            if recoverySuccessful {
                logger.log("Error recovery successful for \(category.rawValue) error")
            } else {
                logger.log("Error recovery failed for \(category.rawValue) error")
                
                // Escalate if recovery failed and severity is high
                if severity == .critical {
                    await escalateError(error, category: category, context: errorContext)
                }
            }
        }
        
        // Create error report
        let report = ErrorReport(
            error: error,
            category: category,
            severity: severity,
            context: errorContext,
            recoveryAttempted: recoveryAttempted,
            recoverySuccessful: recoverySuccessful
        )
        
        // Store report
        storeErrorReport(report)
        
        // Log completion
        let duration = Date().timeIntervalSince(startTime)
        logger.log("Error handling completed in \(String(format: "%.3f", duration))s")
        
        return report
    }
    
    // MARK: - Error Classification
    
    public func classifyError(_ error: Error) -> (category: ErrorCategory, severity: ErrorSeverity) {
        let category = categorizeError(error)
        let severity = determineSeverity(error, category: category)
        return (category, severity)
    }
    
    private func categorizeError(_ error: Error) -> ErrorCategory {
        switch error {
        case is AuthError:
            return .authentication
            
        case is PaywallError:
            return .subscription
            
        case is StateValidationError:
            return .data
            
        case let nsError as NSError where nsError.domain == NSURLErrorDomain:
            return .network
            
        case let nsError as NSError where nsError.domain == NSCocoaErrorDomain:
            return .data
            
        default:
            // Try to categorize by error description patterns
            let description = error.localizedDescription.lowercased()
            
            if description.contains("network") || description.contains("connection") {
                return .network
            } else if description.contains("auth") || description.contains("login") {
                return .authentication
            } else if description.contains("subscription") || description.contains("purchase") {
                return .subscription
            } else if description.contains("data") || description.contains("save") || description.contains("load") {
                return .data
            } else {
                return .unknown
            }
        }
    }
    
    private func determineSeverity(_ error: Error, category: ErrorCategory) -> ErrorSeverity {
        // Base severity by category
        var baseSeverity: ErrorSeverity
        
        switch category {
        case .authentication:
            baseSeverity = .high // Auth issues are serious
        case .subscription:
            baseSeverity = .medium // Subscription issues affect monetization
        case .data:
            baseSeverity = .high // Data loss/corruption is serious
        case .network:
            baseSeverity = .low // Network issues are often transient
        case .ui:
            baseSeverity = .low // UI issues are usually not critical
        case .system:
            baseSeverity = .medium // System issues vary in severity
        case .unknown:
            baseSeverity = .medium // Unknown errors need investigation
        }
        
        // Adjust severity based on specific error types
        switch error {
        case let authError as AuthError:
            switch authError {
            case .invalidCredentials, .userNotFound:
                return .medium // Can be recovered
            case .networkError:
                return .low // Network issues are often transient
            case .unknown:
                return .critical // Unknown auth errors need investigation
            }
            
        case let validationError as StateValidationError:
            switch validationError {
            case .dataIntegrityViolation, .stateTransitionInvalid:
                return .critical // Data corruption is critical
            case .userDataInconsistent, .subscriptionDataCorrupted:
                return .high // Inconsistency is serious
            case .profileDataInvalid:
                return .medium // Profile issues are recoverable
            }
            
        case let nsError as NSError:
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorTimedOut:
                return .low // Transient network issues
            case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                return .medium // More serious network issues
            default:
                return baseSeverity
            }
            
        default:
            return baseSeverity
        }
    }
    
    // MARK: - Recovery Logic
    
    public func shouldAttemptRecovery(for error: Error, severity: ErrorSeverity) -> Bool {
        // Don't attempt recovery for low severity errors unless they're network related
        if severity == .low {
            if let nsError = error as? NSError, nsError.domain == NSURLErrorDomain {
                // This is a network error, attempt recovery even for low severity
            } else {
                return false
            }
        }
        
        // Always attempt recovery for critical errors
        if severity == .critical {
            return true
        }
        
        // Attempt recovery for medium/high severity errors
        return severity == .medium || severity == .high
    }
    
    private func attemptRecovery(for error: Error, category: ErrorCategory) async -> RecoveryResult {
        switch category {
        case .authentication:
            return await recoveryService.recoverFromAuthError(error)
        case .subscription:
            return await recoveryService.recoverFromSubscriptionError(error)
        case .data:
            return await recoveryService.recoverFromDataError(error)
        case .network:
            return await recoveryService.recoverFromNetworkError(error)
        case .system:
            return await recoveryService.recoverFromStateCorruption(error)
        case .ui, .unknown:
            // For UI and unknown errors, attempt generic recovery
            let strategy = recoveryService.getRecoveryStrategy(for: error)
            return await recoveryService.executeRecovery(strategy: strategy, for: error)
        }
    }
    
    // MARK: - Error Escalation
    
    private func escalateError(_ error: Error, category: ErrorCategory, context: ErrorContext) async {
        logger.log("Escalating critical \(category.rawValue) error: \(error.localizedDescription)")
        
        // For critical errors, we might want to:
        // 1. Force sign out user if auth-related
        // 2. Reset app state if data corruption
        // 3. Show maintenance mode if system-wide issues
        
        switch category {
        case .authentication:
            // Force sign out on critical auth errors
            do {
                try await userSession.signOut()
                logger.log("User signed out due to critical auth error")
            } catch {
                logger.log("Failed to sign out user during error escalation: \(error.localizedDescription)")
            }
            
        case .data:
            // For critical data errors, validate and potentially reset system state
            let systemValidation = await validationService.validateSystemState()
            if !systemValidation.isValid {
                logger.log("System state validation failed during escalation")
                // Could trigger app state reset here
            }
            
        default:
            // Log for other categories
            logger.log("Critical error escalated for category: \(category.rawValue)")
        }
    }
    
    // MARK: - User Messages
    
    public func createUserMessage(for error: Error, severity: ErrorSeverity) -> String {
        let (category, _) = classifyError(error)
        
        switch (category, severity) {
        case (.authentication, .critical):
            return "We're having trouble with your account. Please sign in again."
        case (.authentication, .high):
            return "Authentication issue detected. Trying to resolve automatically."
        case (.authentication, _):
            return "Please check your login credentials."
            
        case (.subscription, .critical):
            return "There's an issue with your subscription. Please contact support."
        case (.subscription, _):
            return "Subscription sync in progress. Please wait a moment."
            
        case (.data, .critical):
            return "Critical data issue detected. Your data is being protected."
        case (.data, .high):
            return "Data sync issue. We're working to resolve it."
        case (.data, _):
            return "Unable to save changes. Please try again."
            
        case (.network, _):
            return "Please check your internet connection and try again."
            
        case (.ui, _):
            return "Interface issue detected. Please refresh the screen."
            
        case (.system, .critical):
            return "System maintenance required. Please restart the app."
        case (.system, _):
            return "System issue detected. Attempting automatic resolution."
            
        case (.unknown, .critical):
            return "Unexpected error occurred. Please restart the app."
        case (.unknown, _):
            return "Something went wrong. Please try again."
        }
    }
    
    // MARK: - Report Management
    
    public func getErrorReports(limit: Int? = nil) -> [ErrorReport] {
        let reports = errorReports.sorted { $0.context.timestamp > $1.context.timestamp }
        
        if let limit = limit {
            return Array(reports.prefix(limit))
        }
        
        return reports
    }
    
    public func clearErrorReports() {
        errorReports.removeAll()
        logger.log("Error reports cleared")
    }
    
    private func storeErrorReport(_ report: ErrorReport) {
        errorReports.append(report)
        
        // Maintain maximum number of reports
        if errorReports.count > maxReports {
            errorReports.removeFirst(errorReports.count - maxReports)
        }
    }
    
    // MARK: - Context Creation
    
    private func createDefaultContext() -> ErrorContext {
        var additionalInfo = [String: Any]()
        additionalInfo["isAuthenticated"] = userSession.isAuthenticated
        additionalInfo["isPremiumUser"] = userSession.isPremiumUser
        
        let userID = userSession.currentUser?.id.uuidString
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        
        let context = ErrorContext(
            userID: userID,
            sessionID: sessionID,
            appVersion: appVersion,
            platform: "iOS",
            timestamp: Date(),
            userAction: nil,
            additionalInfo: additionalInfo
        )
        return context
    }
}

// MARK: - Convenience Extensions

public extension ErrorHandlingStrategy {
    /// Handle error with user action context
    func handleError(_ error: Error, userAction: String?) async -> ErrorReport {
        let additionalInfo = [String: Any]()
        let userID = userSession.currentUser?.id.uuidString
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        
        let context = ErrorContext(
            userID: userID,
            sessionID: sessionID,
            appVersion: appVersion,
            platform: "iOS",
            timestamp: Date(),
            userAction: userAction,
            additionalInfo: additionalInfo
        )
        return await handleError(error, context: context)
    }
    
    /// Get user-friendly message for error
    func getUserMessage(for error: Error) -> String {
        let (_, severity) = classifyError(error)
        return createUserMessage(for: error, severity: severity)
    }
    
    /// Check if error is critical and requires immediate attention
    func isCriticalError(_ error: Error) -> Bool {
        let (_, severity) = classifyError(error)
        return severity == .critical
    }
}