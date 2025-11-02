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
import os.log

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

    /// Logger for backup operations
    private let logger = Logger(subsystem: "com.vladblajovan.Ritualist", category: "BackupManager")

    /// UserDefaults key for pending restore
    private let pendingRestoreKey = "com.ritualist.pendingRestore"

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
        logger.info("Creating database backup")

        let databaseURL = getDatabaseURL()
        guard FileManager.default.fileExists(atPath: databaseURL.path) else {
            logger.warning("No database file found at: \(databaseURL.path)")
            throw PersistenceError.backupFailed(BackupError.databaseNotFound)
        }

        let backupURL = generateBackupURL()
        logger.debug("Backup destination: \(backupURL.path)")

        do {
            // Copy database file to backup location
            try FileManager.default.copyItem(at: databaseURL, to: backupURL)

            // Also backup associated files (WAL, SHM)
            try backupAssociatedFiles(databaseURL: databaseURL, backupURL: backupURL)

            logger.info("Successfully created backup at: \(backupURL.lastPathComponent)")

            // Clean up old backups
            try cleanupOldBackups()

            return backupURL
        } catch {
            logger.error("Failed to create backup: \(error.localizedDescription)")
            throw PersistenceError.backupFailed(error)
        }
    }

    /// Restores the database from the most recent backup
    ///
    /// - Throws: PersistenceError.restoreFailed if restore fails
    public func restoreLatestBackup() throws {
        logger.info("Restoring database from latest backup")

        guard let latestBackup = try getLatestBackup() else {
            logger.error("No backup available for restore")
            throw PersistenceError.restoreFailed(BackupError.noBackupAvailable)
        }

        try restore(from: latestBackup)
        logger.info("Successfully restored database from: \(latestBackup.lastPathComponent)")
    }

    /// Restores the database from a specific backup file
    ///
    /// - Parameter backupURL: URL of the backup file to restore
    /// - Throws: PersistenceError.restoreFailed if restore fails
    public func restore(from backupURL: URL) throws {
        logger.info("Restoring database from: \(backupURL.lastPathComponent)")

        let databaseURL = getDatabaseURL()

        do {
            // Remove existing database
            if FileManager.default.fileExists(atPath: databaseURL.path) {
                try FileManager.default.removeItem(at: databaseURL)
                logger.debug("Removed existing database")
            }

            // Copy backup to database location
            try FileManager.default.copyItem(at: backupURL, to: databaseURL)

            // Also restore associated files (WAL, SHM)
            try restoreAssociatedFiles(backupURL: backupURL, databaseURL: databaseURL)

            logger.info("Database restored successfully")
        } catch {
            logger.error("Failed to restore database: \(error.localizedDescription)")
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
            logger.debug("No backup directory found")
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

        logger.debug("Found \(backupFiles.count) backup(s)")
        return backupFiles
    }

    /// Deletes all backup files
    ///
    /// - Throws: Error if deletion fails
    public func deleteAllBackups() throws {
        logger.info("Deleting all backups")

        let backupDirectory = getBackupDirectory()

        guard FileManager.default.fileExists(atPath: backupDirectory.path) else {
            logger.debug("No backup directory to delete")
            return
        }

        try FileManager.default.removeItem(at: backupDirectory)
        logger.info("All backups deleted")
    }

    // MARK: - Pending Restore Management

    /// Schedules a restore to happen on next app launch (before ModelContainer creation)
    ///
    /// This is the SAFE way to restore because it happens when no SQLite connection exists
    ///
    /// - Parameter backupURL: URL of the backup file to restore
    public func schedulePendingRestore(from backupURL: URL) {
        logger.info("Scheduling pending restore from: \(backupURL.lastPathComponent)")
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

        logger.info("Executing pending restore from: \(backupPath)")

        let backupURL = URL(fileURLWithPath: backupPath)

        // Verify backup still exists
        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            logger.error("Pending restore backup not found: \(backupPath)")
            clearPendingRestore()
            throw PersistenceError.restoreFailed(BackupError.noBackupAvailable)
        }

        // Now it's safe to restore because ModelContainer hasn't been created yet
        try restore(from: backupURL)

        // Clear the pending restore flag
        clearPendingRestore()

        logger.info("Pending restore completed successfully")
    }

    /// Clears the pending restore flag
    public func clearPendingRestore() {
        userDefaults.removeObject(forKey: pendingRestoreKey)
        logger.debug("Cleared pending restore flag")
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
            logger.debug("Backup count (\(backups.count)) within limit (\(self.maxBackupCount))")
            return
        }

        let backupsToDelete = backups.dropFirst(self.maxBackupCount)
        logger.info("Cleaning up \(backupsToDelete.count) old backup(s)")

        for backupURL in backupsToDelete {
            try FileManager.default.removeItem(at: backupURL)
            logger.debug("Deleted old backup: \(backupURL.lastPathComponent)")
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
            logger.debug("Backed up WAL file")
        }

        // Copy SHM file if exists
        if FileManager.default.fileExists(atPath: shmURL.path) {
            try? FileManager.default.copyItem(at: shmURL, to: backupShmURL)
            logger.debug("Backed up SHM file")
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
            logger.debug("Restored WAL file")
        }

        // Restore SHM file if exists
        if FileManager.default.fileExists(atPath: backupShmURL.path) {
            if FileManager.default.fileExists(atPath: shmURL.path) {
                try FileManager.default.removeItem(at: shmURL)
            }
            try? FileManager.default.copyItem(at: backupShmURL, to: shmURL)
            logger.debug("Restored SHM file")
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
