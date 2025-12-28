//
//  DebugMenuMigrationSection.swift
//  Ritualist
//

import SwiftUI
import RitualistCore
import FactoryKit

#if DEBUG
struct DebugMenuMigrationSection: View {
    @Injected(\.userDefaultsService) private var userDefaults
    @Injected(\.debugLogger) private var logger
    @Binding var showingMigrationSimulationAlert: Bool
    @Binding var showingMigrationHistory: Bool
    @Binding var showingBackupList: Bool
    @Binding var migrationHistoryCount: Int
    @Binding var backupCount: Int
    let migrationLogger: MigrationLogger
    let onRefresh: () -> Void

    var body: some View {
        Section("Migration Management") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Schema Version")
                        .font(.headline)
                    Spacer()
                    Text("V\(RitualistMigrationPlan.currentSchemaVersion.description)")
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }

                if let lastVersion = userDefaults.string(forKey: UserDefaultsKeys.lastSchemaVersion) {
                    Text("Last Known: \(lastVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("No migration history (first launch)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("SwiftData versioned schema system enabled")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)

            Button(role: .destructive) {
                simulateMigration()
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.purple)

                    Text("Simulate Migration from V\(getPreviousVersionNumber())")

                    Spacer()
                }
            }

            Text("Sets schema version to \(getPreviousVersionNumber()).0.0 to trigger migration on next app launch")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(role: .destructive) {
                cleanDuplicateMigrations()
            } label: {
                HStack {
                    Image(systemName: "trash.circle")
                        .foregroundColor(.orange)

                    Text("Clean Duplicate Migrations")

                    Spacer()
                }
            }
            .disabled(migrationHistoryCount <= 1)

            Text("Removes duplicate migration entries, keeping only the latest for each version transition")
                .font(.caption)
                .foregroundColor(.secondary)

            GenericRowView.settingsRow(
                title: "Migration History",
                subtitle: migrationHistoryCount > 0
                    ? "\(migrationHistoryCount) migration(s) recorded"
                    : "No migrations recorded yet",
                icon: "clock.arrow.circlepath",
                iconColor: .purple
            ) {
                showingMigrationHistory = true
            }

            GenericRowView.settingsRow(
                title: "Database Backups",
                subtitle: backupCount > 0
                    ? "\(backupCount) manual backup(s) available"
                    : "No manual backups created yet",
                icon: "externaldrive",
                iconColor: .blue
            ) {
                showingBackupList = true
            }
        }
    }

    private func getPreviousVersionNumber() -> Int {
        let currentVersion = RitualistMigrationPlan.currentSchemaVersion.description
        if let majorVersion = Int(currentVersion.split(separator: ".").first ?? "0") {
            return max(majorVersion - 1, 1)
        }
        return 1
    }

    private func simulateMigration() {
        let previousVersion = getPreviousVersionNumber()
        let versionString = "\(previousVersion).0.0"

        userDefaults.set(versionString, forKey: UserDefaultsKeys.lastSchemaVersion)

        logger.log("Set schema version to \(versionString) - restart app to see migration modal", level: .info, category: .debug)

        showingMigrationSimulationAlert = true
    }

    private func cleanDuplicateMigrations() {
        let history = migrationLogger.getMigrationHistory()
        var uniqueMigrations: [String: MigrationEvent] = [:]

        for event in history {
            let key = "\(event.fromVersion) → \(event.toVersion)"
            if let existing = uniqueMigrations[key] {
                if event.startTime > existing.startTime {
                    uniqueMigrations[key] = event
                }
            } else {
                uniqueMigrations[key] = event
            }
        }

        migrationLogger.clearHistory()

        let encoder = JSONEncoder()
        if let data = try? encoder.encode(Array(uniqueMigrations.values)) {
            userDefaults.set(data, forKey: UserDefaultsKeys.migrationHistory)
        }

        onRefresh()

        logger.log("Cleaned migration history: \(history.count) → \(uniqueMigrations.count) entries", level: .info, category: .debug)
    }
}
#endif
