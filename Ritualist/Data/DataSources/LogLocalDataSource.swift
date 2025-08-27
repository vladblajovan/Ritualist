import Foundation
import SwiftData
import RitualistCore

/// @ModelActor implementation of LogLocalDataSource  
/// Runs database operations on background actor thread for optimal performance
@ModelActor
public actor LogLocalDataSource: LogLocalDataSourceProtocol {
    
    /// Fetch logs for specific habit from background thread, return Domain models
    public func logs(for habitID: UUID) async throws -> [HabitLog] {
        let descriptor = FetchDescriptor<HabitLogModel>(
            predicate: #Predicate { $0.habitID == habitID },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let logs = try modelContext.fetch(descriptor)
        return logs.map { $0.toEntity() }
    }
    
    /// Batch fetch logs for multiple habits in a SINGLE database query
    public func logs(for habitIDs: [UUID]) async throws -> [HabitLog] {
        // Handle empty input gracefully
        guard !habitIDs.isEmpty else { return [] }
        
        let descriptor = FetchDescriptor<HabitLogModel>(
            predicate: #Predicate<HabitLogModel> { habitIDs.contains($0.habitID) },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let logs = try modelContext.fetch(descriptor)
        return logs.map { $0.toEntity() }
    }
    
    /// Insert or update log on background thread - accepts Domain model
    public func upsert(_ log: HabitLog) async throws {
        // Check if log already exists
        let descriptor = FetchDescriptor<HabitLogModel>(
            predicate: #Predicate { $0.id == log.id }
        )
        
        if let existing = try modelContext.fetch(descriptor).first {
            // Update existing log
            existing.habitID = log.habitID
            existing.date = log.date
            existing.value = log.value
        } else {
            // Create new log in this ModelContext
            let habitLogModel = HabitLogModel.fromEntity(log, context: modelContext)
            modelContext.insert(habitLogModel)
        }
        
        try modelContext.save()
    }
    
    /// Delete log by ID on background thread
    public func delete(id: UUID) async throws {
        let descriptor = FetchDescriptor<HabitLogModel>(predicate: #Predicate { $0.id == id })
        let logs = try modelContext.fetch(descriptor)
        
        for log in logs {
            modelContext.delete(log)
        }
        try modelContext.save()
    }
}
