//
//  HabitAnalyticsService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//

import Foundation

/// PHASE 2: Utility service for habit analytics calculations only
/// Business operations moved to UseCases following Clean Architecture
public protocol HabitAnalyticsService {
    
    /// Get logs for a single habit using optimized batch loading
    /// Delegates to proper UseCase following Clean Architecture
    func getSingleHabitLogs(habitId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog]
}
