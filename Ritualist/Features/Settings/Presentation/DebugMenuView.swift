//
//  DebugMenuView.swift
//  Ritualist
//
//  Created by Claude on 18.08.2025.
//

import SwiftUI
import RitualistCore
import NaturalLanguage
import os.log

#if DEBUG
struct DebugMenuView: View {
    @Bindable var vm: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingScenarios = false
    @State private var showingMigrationHistory = false
    @State private var showingBackupList = false
    @State private var migrationLogger = MigrationLogger.shared
    @State private var backupManager = BackupManager()
    @State private var backupCount: Int = 0
    @State private var migrationHistoryCount: Int = 0
    
    var body: some View {
        Form {
            Section {
                Text("Debug tools for development and testing. These options are only available in debug builds.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Test Data") {
                GenericRowView.settingsRow(
                    title: "Test Data Scenarios",
                    subtitle: "Populate database with test user journeys",
                    icon: "cylinder.split.1x2",
                    iconColor: .blue
                ) {
                    showingScenarios = true
                }

                // Show progress inline when populating
                if vm.isPopulatingTestData {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "hourglass")
                                .foregroundColor(.blue)

                            Text(vm.testDataProgressMessage.isEmpty ? "Populating test data..." : vm.testDataProgressMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()
                        }

                        ProgressView(value: vm.testDataProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Database Management") {
                // Database Statistics
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Database Statistics")
                            .font(.headline)
                        
                        Spacer()
                        
                        if vm.databaseStats == nil {
                            Button("Load Stats") {
                                Task {
                                    await vm.loadDatabaseStats()
                                }
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.blue)
                        }
                    }
                    
                    if let stats = vm.databaseStats {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Habits:")
                                Spacer()
                                Text("\(stats.habitsCount)")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Habit Logs:")
                                Spacer()
                                Text("\(stats.logsCount)")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Categories:")
                                Spacer()
                                Text("\(stats.categoriesCount)")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Profiles:")
                                Spacer()
                                Text("\(stats.profilesCount)")
                                    .fontWeight(.medium)
                            }
                        }
                        .font(.subheadline)
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 4)
                
                // Clear Database Button
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Image(systemName: vm.isClearingDatabase ? "hourglass" : "trash")
                            .foregroundColor(.red)
                        
                        if vm.isClearingDatabase {
                            Text("Clearing Database...")
                        } else {
                            Text("Clear All Database Data")
                        }
                        
                        Spacer()
                    }
                }
                .disabled(vm.isClearingDatabase)
            }

            Section("Migration Management") {
                // Current Schema Version
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Schema Version")
                            .font(.headline)
                        Spacer()
                        Text("V2.0.0")
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }

                    Text("SwiftData versioned schema with V1→V2 migration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)

                // Migration History
                GenericRowView.settingsRow(
                    title: "Migration History",
                    subtitle: "\(migrationHistoryCount) migration events recorded",
                    icon: "clock.arrow.circlepath",
                    iconColor: .purple
                ) {
                    showingMigrationHistory = true
                }

                // Backup Management
                GenericRowView.settingsRow(
                    title: "Database Backups",
                    subtitle: "\(backupCount) backup(s) available",
                    icon: "externaldrive",
                    iconColor: .blue
                ) {
                    showingBackupList = true
                }

                // Create Backup Button
                Button {
                    createBackup()
                } label: {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                            .foregroundColor(.blue)

                        Text("Create Backup Now")

                        Spacer()
                    }
                }
            }

            Section("Performance Monitoring") {
                // FPS Overlay Toggle
                Toggle(isOn: $vm.showFPSOverlay) {
                    HStack {
                        Image(systemName: "gauge.with.dots.needle.67percent")
                            .foregroundColor(.green)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show FPS Overlay")
                                .fontWeight(.medium)

                            Text("Display frames-per-second in top-right corner")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Performance Stats Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Performance Statistics")
                            .font(.headline)

                        Spacer()

                        Button {
                            vm.updatePerformanceStats()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.blue)
                    }

                    if let memoryMB = vm.memoryUsageMB {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Memory Usage:")
                                Spacer()
                                Text("\(memoryMB, specifier: "%.1f") MB")
                                    .fontWeight(.medium)
                                    .foregroundColor(memoryColor(for: memoryMB))
                            }

                            // Memory usage bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 8)

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(memoryColor(for: memoryMB))
                                        .frame(width: min(geometry.size.width * (memoryMB / 500.0), geometry.size.width), height: 8)
                                }
                            }
                            .frame(height: 8)

                            Text("Typical range: 150-300 MB. Warning at 500+ MB")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Build Information") {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Build Configuration:")
                        Spacer()
                        Text("Debug")
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                    
                    HStack {
                        Text("All Features Enabled:")
                        Spacer()
                        #if ALL_FEATURES_ENABLED
                        Text("Yes")
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        #else
                        Text("No")
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        #endif
                    }
                    
                    HStack {
                        Text("Subscription Enabled:")
                        Spacer()
                        #if SUBSCRIPTION_ENABLED
                        Text("Yes")
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        #else
                        Text("No")
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        #endif
                    }
                }
                .font(.subheadline)
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Debug Menu")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .task {
            // Load database stats when the view appears
            await vm.loadDatabaseStats()
            // Load migration stats
            loadMigrationStats()
        }
        .sheet(isPresented: $showingScenarios) {
            NavigationStack {
                TestDataScenariosView(vm: vm)
            }
        }
        .sheet(isPresented: $showingMigrationHistory) {
            NavigationStack {
                MigrationHistoryView(logger: migrationLogger)
            }
        }
        .sheet(isPresented: $showingBackupList) {
            NavigationStack {
                BackupListView(backupManager: backupManager, onRefresh: loadMigrationStats)
            }
        }
        .alert("Clear Database?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All Data", role: .destructive) {
                Task {
                    await vm.clearDatabase()
                }
            }
        } message: {
            Text("This will permanently delete all habits, logs, categories, and user data from the local database. This action cannot be undone.\n\nThis is useful for testing with a clean slate.")
        }
        .refreshable {
            await vm.loadDatabaseStats()
        }
    }

    // MARK: - Helper Functions

    /// Returns appropriate color for memory usage level
    /// Typical iOS app memory usage:
    /// - Small apps: 50-150MB
    /// - Medium apps: 150-300MB
    /// - Large apps: 300-500MB
    /// - Warning territory: 500MB+
    private func memoryColor(for memoryMB: Double) -> Color {
        if memoryMB < 200 {
            return .green       // Excellent - well within normal range
        } else if memoryMB < 400 {
            return .orange      // Acceptable - normal for feature-rich apps
        } else {
            return .red         // High - approaching memory warning territory
        }
    }

    // MARK: - Migration Management

    /// Loads migration statistics (backup count, migration history count)
    private func loadMigrationStats() {
        backupCount = (try? backupManager.listBackups().count) ?? 0
        migrationHistoryCount = migrationLogger.getMigrationHistory().count
    }

    /// Creates a manual database backup
    private func createBackup() {
        Task {
            do {
                try backupManager.createBackup()
                loadMigrationStats()
            } catch {
                Logger(subsystem: "com.vladblajovan.Ritualist", category: "Debug")
                    .error("Failed to create backup: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Migration History View

struct MigrationHistoryView: View {
    let logger: MigrationLogger
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            let history = logger.getMigrationHistory()

            if history.isEmpty {
                ContentUnavailableView(
                    "No Migration History",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Migrations will appear here when schema versions change")
                )
            } else {
                ForEach(Array(history.enumerated()), id: \.offset) { _, event in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(event.status.emoji) \(event.fromVersion) → \(event.toVersion)")
                                .font(.headline)

                            Spacer()

                            Text(event.status.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor(for: event.status).opacity(0.2))
                                .foregroundColor(statusColor(for: event.status))
                                .cornerRadius(8)
                        }

                        Text(event.startTime, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let duration = event.duration {
                            Text("Duration: \(String(format: "%.2f", duration))s")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let error = event.error {
                            Text("Error: \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Migration History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }

    private func statusColor(for status: MigrationStatus) -> Color {
        switch status {
        case .started: return .blue
        case .succeeded: return .green
        case .failed: return .red
        }
    }
}

// MARK: - Backup List View

struct BackupListView: View {
    let backupManager: BackupManager
    let onRefresh: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var backups: [URL] = []
    @State private var showingRestoreAlert = false
    @State private var selectedBackup: URL?

    var body: some View {
        List {
            if backups.isEmpty {
                ContentUnavailableView(
                    "No Backups Available",
                    systemImage: "externaldrive.badge.xmark",
                    description: Text("Database backups will appear here")
                )
            } else {
                Section {
                    Text("Backups are automatically created before migrations. You can also create manual backups.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Available Backups") {
                    ForEach(backups, id: \.self) { backup in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(backup.lastPathComponent)
                                .font(.headline)

                            if let creationDate = try? backup.resourceValues(forKeys: [.creationDateKey]).creationDate {
                                Text(creationDate, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if let fileSize = try? backup.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                                Text("Size: \(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedBackup = backup
                            showingRestoreAlert = true
                        }
                    }
                    .onDelete(perform: deleteBackups)
                }
            }
        }
        .navigationTitle("Database Backups")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .task {
            loadBackups()
        }
        .alert("Restore Backup?", isPresented: $showingRestoreAlert) {
            Button("Cancel", role: .cancel) {
                selectedBackup = nil
            }
            Button("Restore", role: .destructive) {
                restoreBackup()
            }
        } message: {
            Text("This will replace the current database with the selected backup. The current database will be backed up first.\n\nThe app will need to restart after restoration.")
        }
    }

    private func loadBackups() {
        backups = (try? backupManager.listBackups()) ?? []
    }

    private func deleteBackups(at offsets: IndexSet) {
        for index in offsets {
            let backup = backups[index]
            try? FileManager.default.removeItem(at: backup)
        }
        loadBackups()
        onRefresh()
    }

    private func restoreBackup() {
        guard let backup = selectedBackup else { return }

        Task {
            do {
                // Create a backup of current database before restoring
                try backupManager.createBackup()
                // Restore from selected backup
                try backupManager.restore(from: backup)

                // Notify user to restart
                // In a real implementation, you'd show an alert and restart the app
                Logger(subsystem: "com.vladblajovan.Ritualist", category: "Debug")
                    .info("Database restored successfully from: \(backup.lastPathComponent)")

                loadBackups()
                onRefresh()
                dismiss()
            } catch {
                Logger(subsystem: "com.vladblajovan.Ritualist", category: "Debug")
                    .error("Failed to restore backup: \(error.localizedDescription)")
            }
        }

        selectedBackup = nil
    }
}

#endif