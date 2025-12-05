//
//  BackupManager.swift
//  RitualistCore
//
//  Created by Claude on 11.02.2025.
//
//  Manages automatic database backups for safe migrations.
//  Creates backups before migrations and enables rollback on failure.
//

import Foundation

/// Manages SQLite database backups for migration safety
///
/// Usage:
/// ```swift
/// let manager = BackupManager()
///
/// // Before migration
/// try manager.createBackup()
///
/// // Perform migration...
///
/// // If migration fails
/// try manager.restoreLatestBackup()
/// ```
public final class BackupManager {

    // MARK: - Properties

    /// App Group identifier for shared container access
    private static let appGroupIdentifier = "group.com.vladblajovan.Ritualist"

    /// Maximum number of backups to retain
    private let maxBackupCount = 3

    /// Logger for backup operations (uses DebugLogger for consistency)
    private let logger = DebugLogger(subsystem: "com.vladblajovan.Ritualist", category: "BackupManager")

    /// UserDefaults key for pending restore
    private let pendingRestoreKey = UserDefaultsKeys.pendingRestore

    /// UserDefaults for storing pending restore
    private let userDefaults = UserDefaults.standard

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    /// Creates a backup of the current database
    ///
    /// - Returns: URL of the created backup file
    /// - Throws: PersistenceError.backupFailed if backup creation fails
    @discardableResult
    public func createBackup() throws -> URL {
        logger.log("Creating database backup", level: .info, category: .dataIntegrity)

        let databaseURL = getDatabaseURL()
        guard FileManager.default.fileExists(atPath: databaseURL.path) else {
            logger.log("No database file found at: \(databaseURL.path)", level: .warning, category: .dataIntegrity)
            throw PersistenceError.backupFailed(BackupError.databaseNotFound)
        }

        let backupURL = generateBackupURL()
        logger.log("Backup destination: \(backupURL.path)", level: .debug, category: .dataIntegrity)

        do {
            // Copy database file to backup location
            try FileManager.default.copyItem(at: databaseURL, to: backupURL)

            // Also backup associated files (WAL, SHM)
            try backupAssociatedFiles(databaseURL: databaseURL, backupURL: backupURL)

            logger.log("Successfully created backup at: \(backupURL.lastPathComponent)", level: .info, category: .dataIntegrity)

            // Clean up old backups
            try cleanupOldBackups()

            return backupURL
        } catch {
            logger.log("Failed to create backup: \(error.localizedDescription)", level: .error, category: .dataIntegrity)
            throw PersistenceError.backupFailed(error)
        }
    }

    /// Restores the database from the most recent backup
    ///
    /// - Throws: PersistenceError.restoreFailed if restore fails
    public func restoreLatestBackup() throws {
        logger.log("Restoring database from latest backup", level: .info, category: .dataIntegrity)

        guard let latestBackup = try getLatestBackup() else {
            logger.log("No backup available for restore", level: .error, category: .dataIntegrity)
            throw PersistenceError.restoreFailed(BackupError.noBackupAvailable)
        }

        try restore(from: latestBackup)
        logger.log("Successfully restored database from: \(latestBackup.lastPathComponent)", level: .info, category: .dataIntegrity)
    }

    /// Restores the database from a specific backup file
    ///
    /// - Parameter backupURL: URL of the backup file to restore
    /// - Throws: PersistenceError.restoreFailed if restore fails
    public func restore(from backupURL: URL) throws {
        logger.log("Restoring database from: \(backupURL.lastPathComponent)", level: .info, category: .dataIntegrity)

        let databaseURL = getDatabaseURL()

        do {
            // Remove existing database
            if FileManager.default.fileExists(atPath: databaseURL.path) {
                try FileManager.default.removeItem(at: databaseURL)
                logger.log("Removed existing database", level: .debug, category: .dataIntegrity)
            }

            // Copy backup to database location
            try FileManager.default.copyItem(at: backupURL, to: databaseURL)

            // Also restore associated files (WAL, SHM)
            try restoreAssociatedFiles(backupURL: backupURL, databaseURL: databaseURL)

            logger.log("Database restored successfully", level: .info, category: .dataIntegrity)
        } catch {
            logger.log("Failed to restore database: \(error.localizedDescription)", level: .error, category: .dataIntegrity)
            throw PersistenceError.restoreFailed(error)
        }
    }

    /// Lists all available backups, sorted by creation date (newest first)
    ///
    /// - Returns: Array of backup file URLs
    /// - Throws: Error if directory listing fails
    public func listBackups() throws -> [URL] {
        let backupDirectory = getBackupDirectory()

        guard FileManager.default.fileExists(atPath: backupDirectory.path) else {
            logger.log("No backup directory found", level: .debug, category: .dataIntegrity)
            return []
        }

        let backupFiles = try FileManager.default.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension == "sqlite" }
        .sorted { url1, url2 in
            let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
            return date1 > date2
        }

        logger.log("Found \(backupFiles.count) backup(s)", level: .debug, category: .dataIntegrity)
        return backupFiles
    }

    /// Deletes all backup files
    ///
    /// - Throws: Error if deletion fails
    public func deleteAllBackups() throws {
        logger.log("Deleting all backups", level: .info, category: .dataIntegrity)

        let backupDirectory = getBackupDirectory()

        guard FileManager.default.fileExists(atPath: backupDirectory.path) else {
            logger.log("No backup directory to delete", level: .debug, category: .dataIntegrity)
            return
        }

        try FileManager.default.removeItem(at: backupDirectory)
        logger.log("All backups deleted", level: .info, category: .dataIntegrity)
    }

    // MARK: - Pending Restore Management

    /// Schedules a restore to happen on next app launch (before ModelContainer creation)
    ///
    /// This is the SAFE way to restore because it happens when no SQLite connection exists
    ///
    /// - Parameter backupURL: URL of the backup file to restore
    public func schedulePendingRestore(from backupURL: URL) {
        logger.log("Scheduling pending restore from: \(backupURL.lastPathComponent)", level: .info, category: .dataIntegrity)
        userDefaults.set(backupURL.path, forKey: pendingRestoreKey)
    }

    /// Checks if there's a pending restore scheduled
    ///
    /// - Returns: True if a restore is pending
    public func hasPendingRestore() -> Bool {
        return userDefaults.string(forKey: pendingRestoreKey) != nil
    }

    /// Executes a pending restore if one exists
    ///
    /// MUST be called BEFORE creating ModelContainer to avoid SQLite violations
    ///
    /// - Throws: PersistenceError.restoreFailed if restore fails
    public func executePendingRestoreIfNeeded() throws {
        guard let backupPath = userDefaults.string(forKey: pendingRestoreKey) else {
            return  // No pending restore
        }

        logger.log("Executing pending restore from: \(backupPath)", level: .info, category: .dataIntegrity)

        let backupURL = URL(fileURLWithPath: backupPath)

        // Verify backup still exists
        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            logger.log("Pending restore backup not found: \(backupPath)", level: .error, category: .dataIntegrity)
            clearPendingRestore()
            throw PersistenceError.restoreFailed(BackupError.noBackupAvailable)
        }

        // Now it's safe to restore because ModelContainer hasn't been created yet
        try restore(from: backupURL)

        // Clear the pending restore flag
        clearPendingRestore()

        logger.log("Pending restore completed successfully", level: .info, category: .dataIntegrity)
    }

    /// Clears the pending restore flag
    public func clearPendingRestore() {
        userDefaults.removeObject(forKey: pendingRestoreKey)
        logger.log("Cleared pending restore flag", level: .debug, category: .dataIntegrity)
    }

    // MARK: - Private Methods

    /// Gets the latest backup file URL
    private func getLatestBackup() throws -> URL? {
        let backups = try listBackups()
        return backups.first
    }

    /// Cleans up old backups, keeping only the most recent maxBackupCount files
    private func cleanupOldBackups() throws {
        let backups = try listBackups()

        guard backups.count > self.maxBackupCount else {
            logger.log("Backup count (\(backups.count)) within limit (\(self.maxBackupCount))", level: .debug, category: .dataIntegrity)
            return
        }

        let backupsToDelete = backups.dropFirst(self.maxBackupCount)
        logger.log("Cleaning up \(backupsToDelete.count) old backup(s)", level: .info, category: .dataIntegrity)

        for backupURL in backupsToDelete {
            try FileManager.default.removeItem(at: backupURL)
            logger.log("Deleted old backup: \(backupURL.lastPathComponent)", level: .debug, category: .dataIntegrity)
        }
    }

    /// Generates a unique backup file URL with timestamp
    private func generateBackupURL() -> URL {
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let filename = "Ritualist_backup_\(timestamp).sqlite"
        return getBackupDirectory().appendingPathComponent(filename)
    }

    /// Gets the backup directory URL, creating it if necessary
    private func getBackupDirectory() -> URL {
        let backupDir = getSharedContainerURL().appendingPathComponent("Backups")

        if !FileManager.default.fileExists(atPath: backupDir.path) {
            try? FileManager.default.createDirectory(
                at: backupDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        return backupDir
    }

    /// Gets the database file URL
    private func getDatabaseURL() -> URL {
        getSharedContainerURL().appendingPathComponent("Ritualist.sqlite")
    }

    /// Gets the shared container URL for app group
    private func getSharedContainerURL() -> URL {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier
        ) else {
            fatalError("Failed to get shared container URL for app group: \(Self.appGroupIdentifier)")
        }
        return url
    }

    /// Backs up associated database files (WAL, SHM)
    private func backupAssociatedFiles(databaseURL: URL, backupURL: URL) throws {
        let walURL = databaseURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
        let shmURL = databaseURL.deletingPathExtension().appendingPathExtension("sqlite-shm")

        let backupWalURL = backupURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
        let backupShmURL = backupURL.deletingPathExtension().appendingPathExtension("sqlite-shm")

        // Copy WAL file if exists
        if FileManager.default.fileExists(atPath: walURL.path) {
            try? FileManager.default.copyItem(at: walURL, to: backupWalURL)
            logger.log("Backed up WAL file", level: .debug, category: .dataIntegrity)
        }

        // Copy SHM file if exists
        if FileManager.default.fileExists(atPath: shmURL.path) {
            try? FileManager.default.copyItem(at: shmURL, to: backupShmURL)
            logger.log("Backed up SHM file", level: .debug, category: .dataIntegrity)
        }
    }

    /// Restores associated database files (WAL, SHM)
    private func restoreAssociatedFiles(backupURL: URL, databaseURL: URL) throws {
        let backupWalURL = backupURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
        let backupShmURL = backupURL.deletingPathExtension().appendingPathExtension("sqlite-shm")

        let walURL = databaseURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
        let shmURL = databaseURL.deletingPathExtension().appendingPathExtension("sqlite-shm")

        // Restore WAL file if exists
        if FileManager.default.fileExists(atPath: backupWalURL.path) {
            if FileManager.default.fileExists(atPath: walURL.path) {
                try FileManager.default.removeItem(at: walURL)
            }
            try? FileManager.default.copyItem(at: backupWalURL, to: walURL)
            logger.log("Restored WAL file", level: .debug, category: .dataIntegrity)
        }

        // Restore SHM file if exists
        if FileManager.default.fileExists(atPath: backupShmURL.path) {
            if FileManager.default.fileExists(atPath: shmURL.path) {
                try FileManager.default.removeItem(at: shmURL)
            }
            try? FileManager.default.copyItem(at: backupShmURL, to: shmURL)
            logger.log("Restored SHM file", level: .debug, category: .dataIntegrity)
        }
    }
}

// MARK: - Backup Errors

/// Errors specific to backup operations
enum BackupError: LocalizedError {
    case databaseNotFound
    case noBackupAvailable
    case backupCorrupted

    var errorDescription: String? {
        switch self {
        case .databaseNotFound:
            return "Database file not found"
        case .noBackupAvailable:
            return "No backup available to restore"
        case .backupCorrupted:
            return "Backup file is corrupted or invalid"
        }
    }
}
