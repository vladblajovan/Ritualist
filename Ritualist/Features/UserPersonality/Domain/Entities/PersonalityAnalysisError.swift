//
//  PersonalityAnalysisError.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation

/// Errors that can occur during personality analysis
public enum PersonalityAnalysisError: Error, LocalizedError, Equatable {
    case insufficientData
    case invalidUserId
    case noHabitsFound
    case noLogsFound
    case analysisDisabled
    case dataCorrupted
    case networkError
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .insufficientData:
            return "Not enough data to perform reliable personality analysis. Please track more habits and create custom content."
        case .invalidUserId:
            return "Invalid user identifier provided for analysis."
        case .noHabitsFound:
            return "No active habits found for analysis. Please create and track some habits first."
        case .noLogsFound:
            return "No habit logs found for analysis. Please log your habits consistently for at least a week."
        case .analysisDisabled:
            return "Personality analysis has been disabled. You can enable it in Settings."
        case .dataCorrupted:
            return "The analysis data appears to be corrupted. Please try refreshing the analysis."
        case .networkError:
            return "Network error occurred during analysis. Please check your connection and try again."
        case .unknownError(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .insufficientData:
            return "Track at least 5 active habits for a week and create 3 custom habits and categories."
        case .noHabitsFound:
            return "Create some habits that reflect your interests and start tracking them."
        case .noLogsFound:
            return "Log your habits consistently for at least 7 consecutive days."
        case .analysisDisabled:
            return "Go to Settings > Personality Insights and enable the analysis feature."
        case .dataCorrupted:
            return "Try refreshing the analysis or contact support if the issue persists."
        case .networkError:
            return "Check your internet connection and try again."
        default:
            return "Please try again or contact support if the problem continues."
        }
    }
    
    /// Whether this error is recoverable by user action
    public var isRecoverable: Bool {
        switch self {
        case .insufficientData, .noHabitsFound, .noLogsFound, .analysisDisabled:
            return true
        case .invalidUserId, .dataCorrupted, .networkError, .unknownError:
            return false
        }
    }
    
    /// Category of error for analytics/logging
    public var category: String {
        switch self {
        case .insufficientData, .noHabitsFound, .noLogsFound:
            return "data_insufficient"
        case .analysisDisabled:
            return "user_disabled"
        case .invalidUserId, .dataCorrupted:
            return "data_invalid"
        case .networkError:
            return "network"
        case .unknownError:
            return "unknown"
        }
    }
}