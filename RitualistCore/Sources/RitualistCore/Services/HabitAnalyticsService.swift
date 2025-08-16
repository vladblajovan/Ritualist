//
//  HabitAnalyticsService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//

import Foundation

/// Domain service responsible for habit data access and retrieval
public protocol HabitAnalyticsService {
    
    /// Get all active habits for a user
    func getActiveHabits(for userId: UUID) async throws -> [Habit]
    
    /// Get habit logs for a user within a date range
    func getHabitLogs(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog]
    
    /// Get habit completion statistics for a user within a date range
    func getHabitCompletionStats(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> HabitCompletionStats
}
