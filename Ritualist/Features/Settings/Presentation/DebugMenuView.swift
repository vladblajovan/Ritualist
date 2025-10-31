//
//  DebugMenuView.swift
//  Ritualist
//
//  Created by Claude on 18.08.2025.
//

import SwiftUI
import RitualistCore

#if DEBUG
struct DebugMenuView: View {
    @Bindable var vm: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Form {
            Section {
                Text("Debug tools for development and testing. These options are only available in debug builds.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Text("Choose a test data scenario to populate the database. Each scenario represents a different user journey stage with specific data characteristics.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Test Data Scenarios")
            }

            // Scenario Cards
            ForEach(TestDataScenario.allCases) { scenario in
                Section {
                    Button {
                        Task {
                            await vm.populateTestData(scenario: scenario)
                        }
                    } label: {
                        ScenarioCardView(
                            scenario: scenario,
                            isPopulating: vm.isPopulatingTestData
                        )
                    }
                    .disabled(vm.isPopulatingTestData || vm.isClearingDatabase)
                    .buttonStyle(.plain)
                }
            }

            // Progress Bar (shown when populating)
            if vm.isPopulatingTestData {
                Section {
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
}

// MARK: - Scenario Card View

struct ScenarioCardView: View {
    let scenario: TestDataScenario
    let isPopulating: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and name
            HStack(spacing: 12) {
                Text(scenario.icon)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 2) {
                    Text(scenario.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(scenario.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Detailed description
            Text(scenario.detailedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Key metrics
            let config = TestDataScenarioConfig.config(for: scenario)
            let availability = ScenarioFeatureAvailability.availability(for: scenario)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("\(config.totalHabitCount) habits", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)

                    Label("\(config.historyDays) days", systemImage: "calendar")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }

                HStack {
                    Label(availability.dashboardMetricsLevel, systemImage: "chart.bar.fill")
                        .font(.caption2)
                        .foregroundColor(.green)

                    if availability.personalityAnalysisAvailable {
                        Label("Personality: \(availability.personalityAnalysisConfidence)", systemImage: "brain.head.profile")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    } else {
                        Label("Personality: N/A", systemImage: "xmark.circle")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .opacity(isPopulating ? 0.5 : 1.0)
    }
}

// Preview is available when the debug menu is shown from the main settings view
#endif