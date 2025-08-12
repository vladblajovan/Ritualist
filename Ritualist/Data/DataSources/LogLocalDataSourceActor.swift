import Foundation
import SwiftData
import RitualistCore

/// @ModelActor implementation of LogLocalDataSource  
/// Runs database operations on background actor thread for optimal performance
@ModelActor
public actor LogLocalDataSource: LogLocalDataSourceProtocol {
    
    /// Fetch logs for specific habit from background thread, return Domain models
    public func logs(for habitID: UUID) async throws -> [HabitLog] {
        let descriptor = FetchDescriptor<SDHabitLog>(
            predicate: #Predicate { $0.habitID == habitID },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let sdLogs = try modelContext.fetch(descriptor)
        return sdLogs.map { HabitLogMapper.fromSD($0) }
    }
    
    /// Insert or update log on background thread - accepts Domain model
    public func upsert(_ log: HabitLog) async throws {
        // Check if log already exists
        let descriptor = FetchDescriptor<SDHabitLog>(
            predicate: #Predicate { $0.id == log.id }
        )
        
        if let existing = try modelContext.fetch(descriptor).first {
            // Update existing log
            existing.habitID = log.habitID
            existing.date = log.date
            existing.value = log.value
        } else {
            // Create new log in this ModelContext
            let sdLog = HabitLogMapper.toSD(log, context: modelContext)
            modelContext.insert(sdLog)
        }
        
        try modelContext.save()
    }
    
    /// Delete log by ID on background thread
    public func delete(id: UUID) async throws {
        let descriptor = FetchDescriptor<SDHabitLog>(predicate: #Predicate { $0.id == id })
        let logs = try modelContext.fetch(descriptor)
        
        for log in logs {
            modelContext.delete(log)
        }
        try modelContext.save()
    }
}