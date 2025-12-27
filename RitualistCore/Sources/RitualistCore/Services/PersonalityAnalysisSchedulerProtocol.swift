//
//  PersonalityAnalysisSchedulerProtocol.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 16.08.2025.
//


import Foundation

/// Protocol for scheduling automatic personality analysis based on user preferences
public protocol PersonalityAnalysisSchedulerProtocol: Sendable {
    
    /// Starts the scheduler to monitor for automatic analysis triggers
    func startScheduling(for userId: UUID) async
    
    /// Stops the scheduler for a specific user
    func stopScheduling(for userId: UUID) async
    
    /// Manually triggers an analysis check (respects frequency settings)
    func triggerAnalysisCheck(for userId: UUID) async
    
    /// Forces analysis to run immediately, bypassing frequency checks (for manual mode)
    func forceManualAnalysis(for userId: UUID) async
    
    /// Checks if analysis should run based on frequency and data changes
    func shouldRunAnalysis(for userId: UUID) async throws -> Bool
    
    /// Updates the scheduling when preferences change
    func updateScheduling(for userId: UUID, preferences: PersonalityAnalysisPreferences) async
    
    /// Gets the next scheduled analysis date
    func getNextScheduledAnalysis(for userId: UUID) async -> Date?
}