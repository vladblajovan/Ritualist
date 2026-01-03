//
//  HistoricalDateValidationService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 19.08.2025.
//

import Foundation

// MARK: - Historical Date Validation Errors

/// Comprehensive error types for historical date validation
/// Provides specific reasons for validation failures to enable proper error handling
public enum HistoricalDateValidationError: Error, Equatable, CustomStringConvertible {
    case futureDate(Date)
    case beyondHistoryLimit(Date, Int)
    case invalidDateFormat(String)
    
    public var description: String {
        switch self {
        case .futureDate(let date):
            return "Cannot complete habit for future date: \(date)"
        case .beyondHistoryLimit(let date, let maxDays):
            return "Date beyond \(maxDays)-day limit: \(date)"
        case .invalidDateFormat(let dateString):
            return "Invalid date format: \(dateString)"
        }
    }
}

// MARK: - Date Validation Configuration

/// Configuration for historical date validation boundaries
/// Allows customization of validation limits without code changes
public struct HistoricalDateValidationConfig {
    /// Maximum number of days user can navigate back in history
    public let maxHistoryDays: Int
    
    /// Creates configuration with specified parameters
    /// - Parameters:
    ///   - maxHistoryDays: Maximum days back in history (default: 30)
    public init(maxHistoryDays: Int = 30) {
        self.maxHistoryDays = maxHistoryDays
    }
}

// MARK: - Historical Date Validation Service Protocol

/// Protocol for historical date validation services
/// Provides abstraction for date boundary validation logic
public protocol HistoricalDateValidationServiceProtocol {
    /// Validate that a date is within allowed historical bounds
    /// - Parameter date: Date to validate
    /// - Throws: HistoricalDateValidationError if validation fails
    /// - Returns: Normalized date (start of day) if validation succeeds
    func validateHistoricalDate(_ date: Date) throws -> Date
    
    /// Validate and parse date string into Date object
    /// - Parameter dateString: ISO8601 formatted date string
    /// - Throws: HistoricalDateValidationError if parsing or validation fails
    /// - Returns: Validated and normalized Date object
    func validateHistoricalDateString(_ dateString: String) throws -> Date
    
    /// Check if date is within navigation bounds without throwing
    /// - Parameter date: Date to check
    /// - Returns: True if date is valid, false otherwise
    func isDateWithinBounds(_ date: Date) -> Bool
    
    /// Get the earliest allowed historical date
    /// - Returns: Earliest date that can be used for historical logging
    func getEarliestAllowedDate() -> Date
    
    /// Get current configuration
    /// - Returns: Current validation configuration
    func getConfiguration() -> HistoricalDateValidationConfig
}

// MARK: - Default Historical Date Validation Service

/// Default implementation of historical date validation service
/// Handles date boundary validation with configurable limits
public final class DefaultHistoricalDateValidationService: HistoricalDateValidationServiceProtocol {
    
    // MARK: - Properties
    
    /// Validation configuration
    private let config: HistoricalDateValidationConfig
    
    /// ISO8601 date formatter for parsing date strings
    private let dateFormatter: ISO8601DateFormatter
    
    // MARK: - Initialization
    
    /// Creates service with specified configuration
    /// - Parameter config: Validation configuration (default: 30 days)
    public init(config: HistoricalDateValidationConfig = HistoricalDateValidationConfig()) {
        self.config = config
        
        // Configure ISO8601 formatter for consistent date parsing
        self.dateFormatter = ISO8601DateFormatter()
        self.dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }
    
    // MARK: - Public Interface
    
    /// Validate that a date is within allowed historical bounds
    /// - Parameter date: Date to validate
    /// - Throws: HistoricalDateValidationError if validation fails
    /// - Returns: Normalized date (start of day) if validation succeeds
    public func validateHistoricalDate(_ date: Date) throws -> Date {
        let normalizedDate = CalendarUtils.startOfDayLocal(for: date)
        let today = CalendarUtils.startOfDayLocal(for: Date())
        
        // Check if date is in future
        if normalizedDate > today {
            throw HistoricalDateValidationError.futureDate(normalizedDate)
        }
        
        // Check if date is beyond history limit
        let earliestAllowed = getEarliestAllowedDate()
        if normalizedDate < earliestAllowed {
            throw HistoricalDateValidationError.beyondHistoryLimit(normalizedDate, config.maxHistoryDays)
        }
        
        return normalizedDate
    }
    
    /// Validate and parse date string into Date object
    /// - Parameter dateString: ISO8601 formatted date string
    /// - Throws: HistoricalDateValidationError if parsing or validation fails
    /// - Returns: Validated and normalized Date object
    public func validateHistoricalDateString(_ dateString: String) throws -> Date {
        guard let parsedDate = dateFormatter.date(from: dateString) else {
            throw HistoricalDateValidationError.invalidDateFormat(dateString)
        }
        
        return try validateHistoricalDate(parsedDate)
    }
    
    /// Check if date is within navigation bounds without throwing
    /// - Parameter date: Date to check
    /// - Returns: True if date is valid, false otherwise
    public func isDateWithinBounds(_ date: Date) -> Bool {
        do {
            _ = try validateHistoricalDate(date)
            return true
        } catch {
            return false
        }
    }
    
    /// Get the earliest allowed historical date
    /// - Returns: Earliest date that can be used for historical logging
    public func getEarliestAllowedDate() -> Date {
        let today = CalendarUtils.startOfDayLocal(for: Date())
        return CalendarUtils.addDays(-config.maxHistoryDays, to: today)
    }
    
    /// Get current configuration
    /// - Returns: Current validation configuration
    public func getConfiguration() -> HistoricalDateValidationConfig {
        return config
    }
}

// MARK: - Debug Support

#if DEBUG
extension DefaultHistoricalDateValidationService {
    
    /// Create service with custom max history days for testing
    /// - Parameter maxHistoryDays: Custom history limit
    /// - Returns: Service configured for testing
    public static func forTesting(maxHistoryDays: Int) -> DefaultHistoricalDateValidationService {
        let config = HistoricalDateValidationConfig(maxHistoryDays: maxHistoryDays)
        return DefaultHistoricalDateValidationService(config: config)
    }
}
#endif
