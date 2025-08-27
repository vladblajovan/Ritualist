//
//  OverviewError.swift
//  RitualistCore
//
//  Created by Claude on 27.08.2025.
//

import Foundation

/// Errors related to overview data operations
public enum OverviewError: Error, LocalizedError, Equatable {
    case dateRangeCalculationFailed(reason: String)
    case dataLoadingFailed(reason: String)
    case insightGenerationFailed(reason: String)
    case invalidTimeRange(from: Date, to: Date)
    
    public var errorDescription: String? {
        switch self {
        case .dateRangeCalculationFailed(let reason):
            return "Failed to calculate date range: \(reason)"
        case .dataLoadingFailed(let reason):
            return "Failed to load overview data: \(reason)"
        case .insightGenerationFailed(let reason):
            return "Failed to generate insights: \(reason)"
        case .invalidTimeRange(let from, let to):
            return "Invalid time range from \(from) to \(to)"
        }
    }
    
    public var failureReason: String? {
        return errorDescription
    }
}