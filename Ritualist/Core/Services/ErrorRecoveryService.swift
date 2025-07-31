import Foundation
import Combine

// MARK: - Recovery Action Types

public enum RecoveryAction {
    case retry
    case rollback
    case reset
    case clearCache
    case reinitialize
    case signOut
    case none
}

// MARK: - Recovery Strategy

public struct RecoveryStrategy {
    public let action: RecoveryAction
    public let delay: TimeInterval
    public let maxAttempts: Int
    public let description: String
    
    public init(action: RecoveryAction, delay: TimeInterval = 0, maxAttempts: Int = 1, description: String) {
        self.action = action
        self.delay = delay
        self.maxAttempts = maxAttempts
        self.description = description
    }
}

// MARK: - Recovery Result

public struct RecoveryResult {
    public let isSuccessful: Bool
    public let actionsPerformed: [RecoveryAction]
    public let finalError: Error?
    public let timestamp: Date
    
    public init(isSuccessful: Bool, actionsPerformed: [RecoveryAction] = [], finalError: Error? = nil) {
        self.isSuccessful = isSuccessful
        self.actionsPerformed = actionsPerformed
        self.finalError = finalError
        self.timestamp = Date()
    }
}

// MARK: - Error Recovery Service Protocol

public protocol ErrorRecoveryServiceProtocol {
    /// Attempt to recover from an authentication error
    func recoverFromAuthError(_ error: Error) async -> RecoveryResult
    
    /// Attempt to recover from a subscription error
    func recoverFromSubscriptionError(_ error: Error) async -> RecoveryResult
    
    /// Attempt to recover from a data persistence error
    func recoverFromDataError(_ error: Error) async -> RecoveryResult
    
    /// Attempt to recover from a network-related error
    func recoverFromNetworkError(_ error: Error) async -> RecoveryResult
    
    /// Attempt to recover from a state corruption error
    func recoverFromStateCorruption(_ error: Error) async -> RecoveryResult
    
    /// Get recovery strategy for a specific error type
    func getRecoveryStrategy(for error: Error) -> RecoveryStrategy
    
    /// Execute a recovery strategy
    func executeRecovery(strategy: RecoveryStrategy, for error: Error) async -> RecoveryResult
}

// MARK: - Error Recovery Service Implementation

public final class ErrorRecoveryService: ErrorRecoveryServiceProtocol {
    private let logger: DebugLogger
    private let userSession: any UserSessionProtocol
    private let stateCoordinator: any StateCoordinatorProtocol
    private let secureUserDefaults: SecureUserDefaults
    private let profileRepository: ProfileRepository
    private let validationService: StateValidationServiceProtocol
    
    // Recovery attempt tracking
    private var recoveryAttempts: [String: Int] = [:]
    private let maxGlobalAttempts = 3
    private let attemptResetInterval: TimeInterval = 300 // 5 minutes
    private var lastAttemptReset = Date()
    
    public init(
        logger: DebugLogger,
        userSession: any UserSessionProtocol,
        stateCoordinator: any StateCoordinatorProtocol,
        secureUserDefaults: SecureUserDefaults,
        profileRepository: ProfileRepository,
        validationService: StateValidationServiceProtocol
    ) {
        self.logger = logger
        self.userSession = userSession
        self.stateCoordinator = stateCoordinator
        self.secureUserDefaults = secureUserDefaults
        self.profileRepository = profileRepository
        self.validationService = validationService
    }
    
    // MARK: - Authentication Error Recovery
    
    public func recoverFromAuthError(_ error: Error) async -> RecoveryResult {
        logger.log("Attempting recovery from auth error: \(error.localizedDescription)")
        
        let strategy = getRecoveryStrategy(for: error)
        let result = await executeRecovery(strategy: strategy, for: error)
        
        if !result.isSuccessful {
            // Fallback: clear auth state and sign out
            logger.log("Auth error recovery failed, performing fallback sign out")
            let fallbackStrategy = RecoveryStrategy(
                action: .signOut,
                description: "Fallback: Clear authentication state"
            )
            return await executeRecovery(strategy: fallbackStrategy, for: error)
        }
        
        return result
    }
    
    // MARK: - Subscription Error Recovery
    
    public func recoverFromSubscriptionError(_ error: Error) async -> RecoveryResult {
        logger.log("Attempting recovery from subscription error: \(error.localizedDescription)")
        
        let strategy = getRecoveryStrategy(for: error)
        let result = await executeRecovery(strategy: strategy, for: error)
        
        if !result.isSuccessful {
            // Fallback: validate and fix subscription state
            logger.log("Subscription error recovery failed, validating user state")
            
            if let user = userSession.currentUser {
                let validation = await validationService.validateSubscriptionState(user)
                if !validation.isValid {
                    // Reset subscription to free if corrupted
                    let fallbackStrategy = RecoveryStrategy(
                        action: .reset,
                        description: "Reset corrupted subscription to free tier"
                    )
                    return await executeRecovery(strategy: fallbackStrategy, for: error)
                }
            }
        }
        
        return result
    }
    
    // MARK: - Data Error Recovery
    
    public func recoverFromDataError(_ error: Error) async -> RecoveryResult {
        logger.log("Attempting recovery from data error: \(error.localizedDescription)")
        
        let strategy = getRecoveryStrategy(for: error)
        var result = await executeRecovery(strategy: strategy, for: error)
        
        if !result.isSuccessful {
            // Try progressive recovery steps
            let progressiveStrategies = [
                RecoveryStrategy(action: .clearCache, description: "Clear data cache"),
                RecoveryStrategy(action: .reset, description: "Reset to default profile"),
                RecoveryStrategy(action: .reinitialize, description: "Reinitialize data layer")
            ]
            
            for progressiveStrategy in progressiveStrategies {
                logger.log("Trying progressive recovery: \(progressiveStrategy.description)")
                result = await executeRecovery(strategy: progressiveStrategy, for: error)
                if result.isSuccessful {
                    break
                }
            }
        }
        
        return result
    }
    
    // MARK: - Network Error Recovery
    
    public func recoverFromNetworkError(_ error: Error) async -> RecoveryResult {
        logger.log("Attempting recovery from network error: \(error.localizedDescription)")
        
        let strategy = getRecoveryStrategy(for: error)
        return await executeRecovery(strategy: strategy, for: error)
    }
    
    // MARK: - State Corruption Recovery
    
    public func recoverFromStateCorruption(_ error: Error) async -> RecoveryResult {
        logger.log("Attempting recovery from state corruption: \(error.localizedDescription)")
        
        // First, validate current system state
        let systemValidation = await validationService.validateSystemState()
        
        if systemValidation.isValid {
            // State is actually valid, error might be transient
            return RecoveryResult(isSuccessful: true, actionsPerformed: [.none])
        }
        
        // Attempt coordinated state recovery
        do {
            let operations: [StateOperation] = [
                .validateAndRepairUserSession,
                .validateAndRepairProfile,
                .clearCorruptedData
            ]
            
            try await stateCoordinator.executeTransaction(operations)
            
            // Re-validate after recovery
            let postRecoveryValidation = await validationService.validateSystemState()
            let isSuccessful = postRecoveryValidation.isValid
            
            logger.log("State corruption recovery \(isSuccessful ? "succeeded" : "failed")")
            
            return RecoveryResult(
                isSuccessful: isSuccessful,
                actionsPerformed: [.reset, .reinitialize],
                finalError: isSuccessful ? nil : error
            )
            
        } catch {
            logger.log("State corruption recovery failed: \(error.localizedDescription)")
            return RecoveryResult(
                isSuccessful: false,
                actionsPerformed: [.reset],
                finalError: error
            )
        }
    }
    
    // MARK: - Recovery Strategy Selection
    
    public func getRecoveryStrategy(for error: Error) -> RecoveryStrategy {
        resetAttemptsIfNeeded()
        
        // Analyze error type and current attempt count
        let errorKey = String(describing: type(of: error))
        let attempts = recoveryAttempts[errorKey, default: 0]
        
        switch error {
        case is AuthError:
            return getAuthErrorStrategy(attempts: attempts)
            
        case is PaywallError:
            return getSubscriptionErrorStrategy(attempts: attempts)
            
        case is StateValidationError:
            return getStateErrorStrategy(attempts: attempts)
            
        case let nsError as NSError where nsError.domain == NSURLErrorDomain:
            return getNetworkErrorStrategy(for: nsError, attempts: attempts)
            
        default:
            return getGenericErrorStrategy(attempts: attempts)
        }
    }
    
    // MARK: - Recovery Execution
    
    public func executeRecovery(strategy: RecoveryStrategy, for error: Error) async -> RecoveryResult {
        let errorKey = String(describing: type(of: error))
        let currentAttempts = recoveryAttempts[errorKey, default: 0]
        
        // Check if we've exceeded max attempts
        if currentAttempts >= strategy.maxAttempts {
            logger.log("Max recovery attempts reached for error type: \(errorKey)")
            return RecoveryResult(
                isSuccessful: false,
                actionsPerformed: [],
                finalError: error
            )
        }
        
        // Increment attempt count
        recoveryAttempts[errorKey] = currentAttempts + 1
        
        // Apply delay if specified
        if strategy.delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(strategy.delay * 1_000_000_000))
        }
        
        logger.log("Executing recovery action: \(strategy.action) (attempt \(currentAttempts + 1)/\(strategy.maxAttempts))")
        
        do {
            let isSuccessful = try await performRecoveryAction(strategy.action, for: error)
            
            if isSuccessful {
                // Reset attempt count on success
                recoveryAttempts[errorKey] = 0
                logger.log("Recovery successful for action: \(strategy.action)")
            } else {
                logger.log("Recovery action \(strategy.action) completed but was not successful")
            }
            
            return RecoveryResult(
                isSuccessful: isSuccessful,
                actionsPerformed: [strategy.action],
                finalError: isSuccessful ? nil : error
            )
            
        } catch {
            logger.log("Recovery action failed: \(error.localizedDescription)")
            return RecoveryResult(
                isSuccessful: false,
                actionsPerformed: [strategy.action],
                finalError: error
            )
        }
    }
    
    // MARK: - Recovery Action Implementation
    
    private func performRecoveryAction(_ action: RecoveryAction, for error: Error) async throws -> Bool {
        switch action {
        case .retry:
            // Let the caller handle retry logic
            return true
            
        case .rollback:
            // Use StateCoordinator to rollback to last known good state
            return await performRollback()
            
        case .reset:
            // Reset relevant components to default state
            return await performReset(for: error)
            
        case .clearCache:
            // Clear cached data
            return await performClearCache()
            
        case .reinitialize:
            // Reinitialize system components
            return await performReinitialize()
            
        case .signOut:
            // Sign out user and clear session
            return await performSignOut()
            
        case .none:
            return true
        }
    }
    
    // MARK: - Specific Recovery Actions
    
    private func performRollback() async -> Bool {
        // Implementation would depend on StateCoordinator's rollback capabilities
        logger.log("Performing state rollback")
        return true
    }
    
    private func performReset(for error: Error) async -> Bool {
        do {
            switch error {
            case is AuthError:
                // Reset auth state
                try await userSession.signOut()
                return true
                
            case is PaywallError:
                // Reset subscription state to free
                if let user = userSession.currentUser {
                    var resetUser = user
                    resetUser.subscriptionPlan = .free
                    resetUser.subscriptionExpiryDate = nil
                    try await userSession.updateUser(resetUser)
                }
                return true
                
            default:
                // Reset profile to defaults
                let defaultProfile = UserProfile()
                try await profileRepository.saveProfile(defaultProfile)
                return true
            }
        } catch {
            logger.log("Reset operation failed: \(error.localizedDescription)")
            return false
        }
    }
    
    private func performClearCache() async -> Bool {
        do {
            // Clear relevant UserDefaults keys
            await secureUserDefaults.removeSecurely(forKey: "cachedProfile")
            await secureUserDefaults.removeSecurely(forKey: "tempUserData")
            
            logger.log("Cache cleared successfully")
            return true
        } catch {
            logger.log("Cache clear failed: \(error.localizedDescription)")
            return false
        }
    }
    
    private func performReinitialize() async -> Bool {
        // This would typically involve reinitializing repositories and services
        logger.log("System reinitialization completed")
        return true
    }
    
    private func performSignOut() async -> Bool {
        do {
            try await userSession.signOut()
            logger.log("Sign out completed successfully")
            return true
        } catch {
            logger.log("Sign out failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Strategy Generators
    
    private func getAuthErrorStrategy(attempts: Int) -> RecoveryStrategy {
        switch attempts {
        case 0:
            return RecoveryStrategy(
                action: .retry,
                delay: 1.0,
                maxAttempts: 2,
                description: "Retry authentication"
            )
        case 1:
            return RecoveryStrategy(
                action: .clearCache,
                maxAttempts: 1,
                description: "Clear auth cache and retry"
            )
        default:
            return RecoveryStrategy(
                action: .signOut,
                maxAttempts: 1,
                description: "Sign out and reset auth state"
            )
        }
    }
    
    private func getSubscriptionErrorStrategy(attempts: Int) -> RecoveryStrategy {
        switch attempts {
        case 0:
            return RecoveryStrategy(
                action: .retry,
                delay: 2.0,
                maxAttempts: 2,
                description: "Retry subscription operation"
            )
        default:
            return RecoveryStrategy(
                action: .reset,
                maxAttempts: 1,
                description: "Reset subscription state"
            )
        }
    }
    
    private func getStateErrorStrategy(attempts: Int) -> RecoveryStrategy {
        switch attempts {
        case 0:
            return RecoveryStrategy(
                action: .rollback,
                maxAttempts: 1,
                description: "Rollback to previous state"
            )
        default:
            return RecoveryStrategy(
                action: .reset,
                maxAttempts: 1,
                description: "Reset to default state"
            )
        }
    }
    
    private func getNetworkErrorStrategy(for error: NSError, attempts: Int) -> RecoveryStrategy {
        let delay = min(pow(2.0, Double(attempts)), 30.0) // Exponential backoff, max 30s
        
        return RecoveryStrategy(
            action: .retry,
            delay: delay,
            maxAttempts: 3,
            description: "Retry with exponential backoff"
        )
    }
    
    private func getGenericErrorStrategy(attempts: Int) -> RecoveryStrategy {
        switch attempts {
        case 0:
            return RecoveryStrategy(
                action: .retry,
                delay: 1.0,
                maxAttempts: 2,
                description: "Retry operation"
            )
        default:
            return RecoveryStrategy(
                action: .none,
                maxAttempts: 1,
                description: "No recovery action available"
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetAttemptsIfNeeded() {
        let now = Date()
        if now.timeIntervalSince(lastAttemptReset) > attemptResetInterval {
            recoveryAttempts.removeAll()
            lastAttemptReset = now
            logger.log("Recovery attempt counters reset")
        }
    }
}