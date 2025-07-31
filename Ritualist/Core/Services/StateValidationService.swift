import Foundation
import Combine

// MARK: - State Validation Errors

public enum StateValidationError: Error, LocalizedError {
    case userDataInconsistent(String)
    case subscriptionDataCorrupted(String)
    case profileDataInvalid(String)
    case stateTransitionInvalid(String)
    case dataIntegrityViolation(String)
    
    public var errorDescription: String? {
        switch self {
        case .userDataInconsistent(let details):
            return "User data inconsistency: \(details)"
        case .subscriptionDataCorrupted(let details):
            return "Subscription data corruption: \(details)"
        case .profileDataInvalid(let details):
            return "Profile data invalid: \(details)"
        case .stateTransitionInvalid(let details):
            return "Invalid state transition: \(details)"
        case .dataIntegrityViolation(let details):
            return "Data integrity violation: \(details)"
        }
    }
}

// MARK: - State Validation Result

public struct StateValidationResult {
    public let isValid: Bool
    public let errors: [StateValidationError]
    public let warnings: [String]
    public let timestamp: Date
    
    public init(isValid: Bool, errors: [StateValidationError] = [], warnings: [String] = []) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
        self.timestamp = Date()
    }
    
    public static let valid = StateValidationResult(isValid: true)
}

// MARK: - State Validation Service Protocol

public protocol StateValidationServiceProtocol {
    /// Validate user session state integrity
    func validateUserSession(_ user: User?) async -> StateValidationResult
    
    /// Validate subscription state consistency
    func validateSubscriptionState(_ user: User?) async -> StateValidationResult
    
    /// Validate profile data integrity
    func validateProfile(_ profile: UserProfile) async -> StateValidationResult
    
    /// Validate state transition is allowed
    func validateStateTransition(from: AppState, to: AppState) async -> StateValidationResult
    
    /// Perform comprehensive system state validation
    func validateSystemState() async -> StateValidationResult
    
    /// Check for data corruption indicators
    func checkDataIntegrity() async -> StateValidationResult
}

// MARK: - App State Definition

public enum AppState: Equatable {
    case launching
    case unauthenticated
    case authenticating
    case authenticated(User)
    case error(String)
    case backgrounded
    case terminated
}

// MARK: - State Validation Service Implementation

public final class StateValidationService: StateValidationServiceProtocol {
    private let dateProvider: DateProvider
    private let logger: DebugLogger
    private let userSession: any UserSessionProtocol
    private let profileRepository: ProfileRepository
    
    public init(
        dateProvider: DateProvider,
        logger: DebugLogger,
        userSession: any UserSessionProtocol,
        profileRepository: ProfileRepository
    ) {
        self.dateProvider = dateProvider
        self.logger = logger
        self.userSession = userSession
        self.profileRepository = profileRepository
    }
    
    // MARK: - User Session Validation
    
    public func validateUserSession(_ user: User?) async -> StateValidationResult {
        var errors: [StateValidationError] = []
        var warnings: [String] = []
        
        // Check for nil user when session claims to be authenticated
        if userSession.isAuthenticated && user == nil {
            errors.append(.userDataInconsistent("Session claims authenticated but user is nil"))
        }
        
        // Check for user present when session claims unauthenticated
        if !userSession.isAuthenticated && user != nil {
            errors.append(.userDataInconsistent("Session claims unauthenticated but user is present"))
        }
        
        if let user = user {
            // Validate user data completeness
            if user.email.isEmpty {
                errors.append(.userDataInconsistent("User email is empty"))
            }
            
            if user.name.isEmpty {
                warnings.append("User name is empty")
            }
            
            // Validate email format
            if !isValidEmail(user.email) {
                errors.append(.userDataInconsistent("User email format is invalid"))
            }
            
            // Validate subscription consistency
            let subscriptionValidation = await validateSubscriptionState(user)
            errors.append(contentsOf: subscriptionValidation.errors)
            warnings.append(contentsOf: subscriptionValidation.warnings)
        }
        
        logger.log("User session validation completed with \(errors.count) errors, \(warnings.count) warnings")
        
        return StateValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    // MARK: - Subscription State Validation
    
    public func validateSubscriptionState(_ user: User?) async -> StateValidationResult {
        var errors: [StateValidationError] = []
        var warnings: [String] = []
        
        guard let user = user else {
            return StateValidationResult(isValid: true) // No user, no subscription to validate
        }
        
        let currentDate = dateProvider.now
        
        // Check subscription plan consistency
        switch user.subscriptionPlan {
        case .free:
            if user.subscriptionExpiryDate != nil {
                errors.append(.subscriptionDataCorrupted("Free user has expiry date"))
            }
            if user.isPremiumUser {
                errors.append(.subscriptionDataCorrupted("Free user marked as premium"))
            }
            
        case .monthly, .annual:
            if user.subscriptionExpiryDate == nil {
                errors.append(.subscriptionDataCorrupted("Premium user missing expiry date"))
            } else if let expiryDate = user.subscriptionExpiryDate {
                if expiryDate <= currentDate {
                    warnings.append("Premium subscription has expired")
                }
                
                // Check if expiry date is too far in the future (potential corruption)
                let maxFutureDate = Calendar.current.date(byAdding: .year, value: 2, to: currentDate) ?? currentDate
                if expiryDate > maxFutureDate {
                    warnings.append("Subscription expiry date is suspiciously far in the future")
                }
            }
            
            if !user.isPremiumUser && user.subscriptionExpiryDate ?? currentDate > currentDate {
                errors.append(.subscriptionDataCorrupted("User has valid subscription but not marked as premium"))
            }
        }
        
        logger.log("Subscription validation completed with \(errors.count) errors, \(warnings.count) warnings")
        
        return StateValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    // MARK: - Profile Data Validation
    
    public func validateProfile(_ profile: UserProfile) async -> StateValidationResult {
        var errors: [StateValidationError] = []
        var warnings: [String] = []
        
        // Validate first day of week
        if profile.firstDayOfWeek < 1 || profile.firstDayOfWeek > 7 {
            errors.append(.profileDataInvalid("First day of week must be between 1-7, got \(profile.firstDayOfWeek)"))
        }
        
        // Validate appearance setting
        if profile.appearance < 0 || profile.appearance > 2 {
            errors.append(.profileDataInvalid("Appearance setting must be 0-2, got \(profile.appearance)"))
        }
        
        // Validate name length
        if profile.name.count > 100 {
            warnings.append("Profile name is unusually long (\(profile.name.count) characters)")
        }
        
        // Check for suspicious characters in name
        let allowedCharacters = CharacterSet.letters.union(.whitespaces).union(.punctuationCharacters)
        if !profile.name.allSatisfy({ char in
            String(char).rangeOfCharacter(from: allowedCharacters) != nil
        }) {
            warnings.append("Profile name contains unusual characters")
        }
        
        logger.log("Profile validation completed with \(errors.count) errors, \(warnings.count) warnings")
        
        return StateValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    // MARK: - State Transition Validation
    
    public func validateStateTransition(from: AppState, to: AppState) async -> StateValidationResult {
        var errors: [StateValidationError] = []
        
        // Define valid state transitions
        let isValidTransition = isValidStateTransition(from: from, to: to)
        
        if !isValidTransition {
            errors.append(.stateTransitionInvalid("Invalid transition from \(from) to \(to)"))
        }
        
        // Additional validation for specific transitions
        switch (from, to) {
        case (.unauthenticated, .authenticated(let user)):
            let userValidation = await validateUserSession(user)
            errors.append(contentsOf: userValidation.errors)
            
        case (.authenticated(let oldUser), .authenticated(let newUser)):
            if oldUser.id != newUser.id {
                errors.append(.stateTransitionInvalid("User ID changed during authenticated state transition"))
            }
            
        default:
            break
        }
        
        logger.log("State transition validation (\(from) -> \(to)) completed with \(errors.count) errors")
        
        return StateValidationResult(
            isValid: errors.isEmpty,
            errors: errors
        )
    }
    
    // MARK: - System State Validation
    
    public func validateSystemState() async -> StateValidationResult {
        var errors: [StateValidationError] = []
        var warnings: [String] = []
        
        // Validate user session
        let userValidation = await validateUserSession(userSession.currentUser)
        errors.append(contentsOf: userValidation.errors)
        warnings.append(contentsOf: userValidation.warnings)
        
        // Validate profile data
        do {
            let profile = try await profileRepository.loadProfile()
            let profileValidation = await validateProfile(profile)
            errors.append(contentsOf: profileValidation.errors)
            warnings.append(contentsOf: profileValidation.warnings)
        } catch {
            errors.append(.profileDataInvalid("Failed to load profile: \(error.localizedDescription)"))
        }
        
        // Check data integrity
        let integrityValidation = await checkDataIntegrity()
        errors.append(contentsOf: integrityValidation.errors)
        warnings.append(contentsOf: integrityValidation.warnings)
        
        logger.log("System state validation completed with \(errors.count) errors, \(warnings.count) warnings")
        
        return StateValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    // MARK: - Data Integrity Checks
    
    public func checkDataIntegrity() async -> StateValidationResult {
        var errors: [StateValidationError] = []
        var warnings: [String] = []
        
        // Check UserDefaults consistency
        let userDefaults = UserDefaults.standard
        
        // Validate stored user data format
        if let userData = userDefaults.data(forKey: "currentUser") {
            do {
                _ = try JSONDecoder().decode(User.self, from: userData)
            } catch {
                errors.append(.dataIntegrityViolation("Stored user data is corrupted: \(error.localizedDescription)"))
            }
        }
        
        // Check for circular references or impossible states
        if userSession.isAuthenticated && userSession.currentUser == nil {
            errors.append(.dataIntegrityViolation("Session authenticated but current user is nil"))
        }
        
        if !userSession.isAuthenticated && userSession.isPremiumUser {
            errors.append(.dataIntegrityViolation("Unauthenticated user marked as premium"))
        }
        
        logger.log("Data integrity check completed with \(errors.count) errors, \(warnings.count) warnings")
        
        return StateValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    // MARK: - Helper Methods
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidStateTransition(from: AppState, to: AppState) -> Bool {
        switch (from, to) {
        case (.launching, .unauthenticated),
             (.launching, .authenticated),
             (.launching, .error):
            return true
            
        case (.unauthenticated, .authenticating),
             (.unauthenticated, .error),
             (.unauthenticated, .backgrounded),
             (.unauthenticated, .terminated):
            return true
            
        case (.authenticating, .authenticated),
             (.authenticating, .unauthenticated),
             (.authenticating, .error):
            return true
            
        case (.authenticated, .unauthenticated),
             (.authenticated, .authenticated),
             (.authenticated, .error),
             (.authenticated, .backgrounded),
             (.authenticated, .terminated):
            return true
            
        case (.error, .unauthenticated),
             (.error, .authenticating),
             (.error, .authenticated),
             (.error, .terminated):
            return true
            
        case (.backgrounded, .unauthenticated),
             (.backgrounded, .authenticated),
             (.backgrounded, .terminated):
            return true
            
        case (_, .terminated):
            return true // Can always terminate
            
        default:
            return false
        }
    }
}