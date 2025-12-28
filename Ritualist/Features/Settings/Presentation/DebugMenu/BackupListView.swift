//
//  BackupListView.swift
//  Ritualist
//

import SwiftUI
import RitualistCore
import FactoryKit

#if DEBUG
struct BackupListView: View {
    let backupManager: BackupManager
    let onRefresh: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Injected(\.debugLogger) private var logger
    @State private var backups: [URL] = []
    @State private var showingRestoreAlert = false
    @State private var showingRestoreSuccessAlert = false
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

                            if let backupDate = extractBackupDate(from: backup) {
                                HStack(spacing: 4) {
                                    Text(backupDate, style: .date)
                                    Text("at")
                                    Text(backupDate, style: .time)
                                }
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
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    createBackup()
                } label: {
                    Label("Create Backup", systemImage: "doc.badge.plus")
                }
            }

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
        .alert("Database Restored", isPresented: $showingRestoreSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("The database has been successfully restored. Please close and reopen the app to load the restored data.")
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

        backupManager.schedulePendingRestore(from: backup)

        logger.log("Scheduled restore from: \(backup.lastPathComponent)", level: .info, category: .debug)

        selectedBackup = nil
        showingRestoreSuccessAlert = true
    }

    private func extractBackupDate(from url: URL) -> Date? {
        let filename = url.lastPathComponent

        guard let timestampRange = filename.range(of: "Ritualist_backup_"),
              let extensionRange = filename.range(of: ".sqlite") else {
            return nil
        }

        let startIndex = timestampRange.upperBound
        let endIndex = extensionRange.lowerBound
        let timestamp = String(filename[startIndex..<endIndex])

        let components = timestamp.components(separatedBy: "T")
        guard components.count == 2 else { return nil }

        let datePart = components[0]
        let timePart = components[1].replacingOccurrences(of: "-", with: ":")
        let iso8601String = "\(datePart)T\(timePart)"

        let formatter = ISO8601DateFormatter()
        return formatter.date(from: iso8601String)
    }

    private func createBackup() {
        Task {
            do {
                try backupManager.createBackup()
                loadBackups()
                onRefresh()
            } catch {
                logger.logError(error, context: "Failed to create backup")
            }
        }
    }
}
#endif
