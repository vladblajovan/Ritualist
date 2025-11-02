//
//  MigrationHistoryView.swift
//  Ritualist
//
//  Created by Claude on 03.11.2025.
//
//  Displays migration history with timestamps and change descriptions.
//

import SwiftUI
import RitualistCore

struct MigrationHistoryView: View {
    let logger: MigrationLogger

    @Environment(\.dismiss) private var dismiss
    @State private var migrationHistory: [MigrationEvent] = []
    @State private var showingClearAlert = false

    var body: some View {
        List {
            if migrationHistory.isEmpty {
                ContentUnavailableView(
                    "No Migration History",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Migrations will appear here when schema versions change")
                )
            } else {
                ForEach(migrationHistory) { event in
                    NavigationLink(destination: MigrationDetailView(event: event)) {
                        MigrationEventRow(event: event)
                    }
                }
            }
        }
        .navigationTitle("Migration History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !migrationHistory.isEmpty {
                    Button(role: .destructive) {
                        showingClearAlert = true
                    } label: {
                        Label("Clear", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            // Backfill descriptions for legacy migration events
            logger.backfillChangeDescriptions()
            loadHistory()
        }
        .alert("Clear Migration History?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                clearMigrationHistory()
            }
        } message: {
            Text("This will permanently delete all migration history records. This action cannot be undone.")
        }
    }

    private func loadHistory() {
        migrationHistory = logger.getMigrationHistory().reversed()
    }

    private func clearMigrationHistory() {
        logger.clearHistory()
        loadHistory()
    }
}

// MARK: - Migration Event Row

struct MigrationEventRow: View {
    let event: MigrationEvent

    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Status icon
            Text(event.status.emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: Spacing.small) {
                // Version transition
                Text("\(event.fromVersion) → \(event.toVersion)")
                    .font(.headline)
                    .foregroundColor(.primary)

                // Date and time
                Text(formatDateTime(event.startTime))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Duration
                if let duration = event.duration {
                    Text(formatDuration(duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Error message if failed
                if let error = event.error {
                    Text("Error: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.vertical, Spacing.small)
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 1 {
            return String(format: "%.0f ms", duration * 1000)
        } else {
            return String(format: "%.2f seconds", duration)
        }
    }
}

// MARK: - Migration Detail View

struct MigrationDetailView: View {
    let event: MigrationEvent

    var body: some View {
        List {
            // Status Section
            Section {
                HStack {
                    Text("Status")
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: Spacing.small) {
                        Text(event.status.emoji)
                        Text(event.status.rawValue)
                            .fontWeight(.semibold)
                    }
                }
            }

            // Version Section
            Section("Migration Details") {
                HStack {
                    Text("From Version")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(event.fromVersion)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("To Version")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(event.toVersion)
                        .fontWeight(.medium)
                }
            }

            // Timing Section
            Section("Timing") {
                HStack {
                    Text("Started")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatFullDateTime(event.startTime))
                        .font(.subheadline)
                }

                if let endTime = event.endTime {
                    HStack {
                        Text("Completed")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatFullDateTime(endTime))
                            .font(.subheadline)
                    }
                }

                if let duration = event.duration {
                    HStack {
                        Text("Duration")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatDuration(duration))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }

            // Changes Section
            if let changeDescription = event.changeDescription {
                Section("What Changed") {
                    Text(changeDescription)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }

            // Error Section
            if let error = event.error {
                Section("Error Details") {
                    Text(error)
                        .font(.body)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Migration Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatFullDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 1 {
            return String(format: "%.0f ms", duration * 1000)
        } else {
            return String(format: "%.2f seconds", duration)
        }
    }
}

// MARK: - Preview

#Preview("Migration History") {
    NavigationStack {
        MigrationHistoryView(logger: .shared)
    }
}

#Preview("Migration Detail") {
    NavigationStack {
        MigrationDetailView(
            event: MigrationEvent(
                fromVersion: "5.0.0",
                toVersion: "6.0.0",
                status: .succeeded,
                startTime: Date().addingTimeInterval(-60),
                endTime: Date(),
                duration: 0.04,
                error: nil,
                changeDescription: "Added habit archiving - habits can now be archived instead of deleted, preserving your history while decluttering active habits."
            )
        )
    }
}
