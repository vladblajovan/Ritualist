import Foundation
import SwiftData

/// @ModelActor implementation of LogLocalDataSource
/// Runs database operations on background actor thread for optimal performance
@ModelActor
public actor LogLocalDataSource: LogLocalDataSourceProtocol {

    /// Local logger instance - @ModelActor cannot use DI injection (SwiftData limitation)
    private let logger = DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "data")

    /// Fetch logs for specific habit from background thread, return Domain models
    public func logs(for habitID: UUID) async throws -> [HabitLog] {
        do {
            let descriptor = FetchDescriptor<ActiveHabitLogModel>(
                predicate: #Predicate { $0.habitID == habitID },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let logs = try modelContext.fetch(descriptor)
            return logs.map { $0.toEntity() }
        } catch {
            logger.log(
                "Failed to fetch logs for habit",
                level: .error,
                category: .dataIntegrity,
                metadata: ["habit_id": habitID.uuidString, "error": error.localizedDescription]
            )
            throw error
        }
    }

    /// Batch fetch logs for multiple habits in a SINGLE database query
    public func logs(for habitIDs: [UUID]) async throws -> [HabitLog] {
        // Handle empty input gracefully
        guard !habitIDs.isEmpty else { return [] }

        do {
            let descriptor = FetchDescriptor<ActiveHabitLogModel>(
                predicate: #Predicate<ActiveHabitLogModel> { habitIDs.contains($0.habitID) },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let logs = try modelContext.fetch(descriptor)

            logger.log(
                "Batch fetched logs for habits",
                level: .debug,
                category: .dataIntegrity,
                metadata: ["habit_count": habitIDs.count, "log_count": logs.count]
            )

            return logs.map { $0.toEntity() }
        } catch {
            logger.log(
                "Failed to batch fetch logs",
                level: .error,
                category: .dataIntegrity,
                metadata: ["habit_count": habitIDs.count, "error": error.localizedDescription]
            )
            throw error
        }
    }

    /// Insert or update log on background thread - accepts Domain model
    public func upsert(_ log: HabitLog) async throws {
        // Validate log ID is not empty
        let logIdString = log.id.uuidString
        guard !logIdString.isEmpty else {
            logger.log(
                "Attempted to upsert log with empty ID",
                level: .error,
                category: .dataIntegrity
            )
            throw LogDataSourceError.invalidLogId
        }

        do {
            // Check if log already exists
            let descriptor = FetchDescriptor<ActiveHabitLogModel>(
                predicate: #Predicate { $0.id == log.id }
            )

            if let existing = try modelContext.fetch(descriptor).first {
                // Update existing log with timezone context
                existing.habitID = log.habitID
                existing.date = log.date
                existing.value = log.value
                existing.timezone = log.timezone

                logger.log(
                    "Updated existing log",
                    level: .debug,
                    category: .dataIntegrity,
                    metadata: ["log_id": logIdString, "habit_id": log.habitID.uuidString]
                )
            } else {
                // Create new log in this ModelContext
                let habitLogModel = ActiveHabitLogModel.fromEntity(log, context: modelContext)
                modelContext.insert(habitLogModel)

                logger.log(
                    "Created new log",
                    level: .debug,
                    category: .dataIntegrity,
                    metadata: ["log_id": logIdString, "habit_id": log.habitID.uuidString]
                )
            }

            try modelContext.save()
        } catch {
            logger.log(
                "Failed to upsert log",
                level: .error,
                category: .dataIntegrity,
                metadata: [
                    "log_id": logIdString,
                    "habit_id": log.habitID.uuidString,
                    "error": error.localizedDescription
                ]
            )
            throw error
        }
    }

    /// Delete log by ID on background thread
    public func delete(id: UUID) async throws {
        do {
            let descriptor = FetchDescriptor<ActiveHabitLogModel>(predicate: #Predicate { $0.id == id })
            let logs = try modelContext.fetch(descriptor)

            let deletedCount = logs.count
            for log in logs {
                modelContext.delete(log)
            }
            try modelContext.save()

            logger.log(
                "Deleted log(s)",
                level: .debug,
                category: .dataIntegrity,
                metadata: ["log_id": id.uuidString, "deleted_count": deletedCount]
            )
        } catch {
            logger.log(
                "Failed to delete log",
                level: .error,
                category: .dataIntegrity,
                metadata: ["log_id": id.uuidString, "error": error.localizedDescription]
            )
            throw error
        }
    }
}

// MARK: - Log Data Source Errors

public enum LogDataSourceError: LocalizedError {
    case invalidLogId

    public var errorDescription: String? {
        switch self {
        case .invalidLogId:
            return "Cannot save log with empty or invalid ID"
        }
    }
}
