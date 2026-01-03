//
//  URLValidationService.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 19.08.2025.
//

import Foundation

// MARK: - URL Validation Protocol

/// Protocol for validating deep link URLs and their components
/// Provides centralized URL validation logic for consistent error handling
public protocol URLValidationService {
    /// Validates a deep link URL structure and components
    /// - Parameter url: The URL to validate
    /// - Returns: URLValidationResult indicating success or specific failure reason
    func validateDeepLinkURL(_ url: URL) -> URLValidationResult
    
    /// Validates habit ID from URL path
    /// - Parameter url: The URL containing habit ID in path
    /// - Returns: Extracted and validated UUID, or nil if invalid
    func extractHabitId(from url: URL) -> UUID?
    
    /// Validates and extracts date parameter from URL query
    /// - Parameter url: The URL containing date query parameter
    /// - Returns: Parsed Date object, or nil if invalid or missing
    func extractDate(from url: URL) -> Date?
    
    /// Validates and extracts action parameter from URL query
    /// - Parameter url: The URL containing action query parameter
    /// - Returns: DeepLinkAction enum, defaults to .view for invalid/missing
    func extractAction(from url: URL) -> DeepLinkAction
}

// MARK: - Validation Result

/// Result type for URL validation operations
public enum URLValidationResult {
    case valid
    case invalidScheme(expected: String, actual: String?)
    case invalidHost(expected: [String], actual: String?)
    case missingHabitId
    case invalidHabitId(String)
    case invalidDateFormat(String)
    case invalidActionType(String)
    case malformedURL
    
    /// Whether the validation was successful
    public var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }
    
    /// Human-readable description of the validation result
    public var description: String {
        switch self {
        case .valid:
            return "URL is valid"
        case .invalidScheme(let expected, let actual):
            return "Invalid URL scheme. Expected: \(expected), got: \(actual ?? "nil")"
        case .invalidHost(let expected, let actual):
            return "Invalid URL host. Expected one of: \(expected), got: \(actual ?? "nil")"
        case .missingHabitId:
            return "Missing habit ID in URL path"
        case .invalidHabitId(let id):
            return "Invalid habit ID format: \(id)"
        case .invalidDateFormat(let date):
            return "Invalid date format: \(date)"
        case .invalidActionType(let action):
            return "Invalid action type: \(action)"
        case .malformedURL:
            return "Malformed URL structure"
        }
    }
}

// MARK: - Default Implementation

/// Default implementation of URLValidationService
/// Validates Ritualist app deep link URLs according to expected format
public final class DefaultURLValidationService: URLValidationService {
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Constants
    
    private let expectedScheme = "ritualist"
    private let validHosts = ["habit", "overview"]
    private let dateFormatter = ISO8601DateFormatter()
    
    // MARK: - URL Validation
    
    public func validateDeepLinkURL(_ url: URL) -> URLValidationResult {
        // Validate scheme
        guard url.scheme == expectedScheme else {
            return .invalidScheme(expected: expectedScheme, actual: url.scheme)
        }
        
        // Validate host
        guard let host = url.host, validHosts.contains(host) else {
            return .invalidHost(expected: validHosts, actual: url.host)
        }
        
        // For habit URLs, validate habit ID
        if host == "habit" {
            guard let _ = extractHabitId(from: url) else {
                let pathComponents = url.pathComponents
                let habitIdString = pathComponents.count > 1 ? pathComponents[1] : ""
                if habitIdString.isEmpty {
                    return .missingHabitId
                } else {
                    return .invalidHabitId(habitIdString)
                }
            }
        }
        
        // Validate query parameters if present
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let queryItems = urlComponents?.queryItems {
            
            // Check date parameter if present
            if let dateString = queryItems.first(where: { $0.name == "date" })?.value,
               extractDate(from: url) == nil {
                return .invalidDateFormat(dateString)
            }
            
            // Action parameter is always valid due to fallback in extractAction
        }
        
        return .valid
    }
    
    // MARK: - Parameter Extraction
    
    public func extractHabitId(from url: URL) -> UUID? {
        let pathComponents = url.pathComponents
        guard pathComponents.count > 1 else { return nil }
        
        let habitIdString = pathComponents[1]
        return UUID(uuidString: habitIdString)
    }
    
    public func extractDate(from url: URL) -> Date? {
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let queryItems = urlComponents?.queryItems,
              let dateString = queryItems.first(where: { $0.name == "date" })?.value else {
            return nil
        }
        
        return dateFormatter.date(from: dateString)
    }
    
    public func extractAction(from url: URL) -> DeepLinkAction {
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let actionString = urlComponents?.queryItems?.first(where: { $0.name == "action" })?.value
        return DeepLinkAction.from(actionString: actionString)
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
/// Mock implementation for testing different validation scenarios
public final class MockURLValidationService: URLValidationService {
    
    public var validationResult: URLValidationResult = .valid
    public var mockHabitId: UUID?
    public var mockDate: Date?
    public var mockAction: DeepLinkAction = .view
    
    public func validateDeepLinkURL(_ url: URL) -> URLValidationResult {
        return validationResult
    }
    
    public func extractHabitId(from url: URL) -> UUID? {
        return mockHabitId
    }
    
    public func extractDate(from url: URL) -> Date? {
        return mockDate
    }
    
    public func extractAction(from url: URL) -> DeepLinkAction {
        return mockAction
    }
}
#endif
