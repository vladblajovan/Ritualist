//
//  DebugMenuView.swift
//  Ritualist
//
//  Created by Claude on 18.08.2025.
//

import SwiftUI
import RitualistCore
import NaturalLanguage

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

            // ML Analysis Demo
            Section {
                Text("Compare keyword-based vs ML-based personality analysis for each scenario's custom habits and categories.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                MLAnalysisDemoView()
            } header: {
                HStack {
                    Text("ML Analysis Demo")
                    Spacer()
                    if #available(iOS 17.0, *), NLEmbedding.wordEmbedding(for: .english) != nil {
                        Text("ML Available")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    } else {
                        Text("Keyword Only")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    }
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

// MARK: - ML Analysis Demo View

struct MLAnalysisDemoView: View {
    @State private var selectedScenario: TestDataScenario = .opennessProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Scenario selector
            Picker("Scenario", selection: $selectedScenario) {
                ForEach(TestDataScenario.personalityProfileCases) { scenario in
                    Text(scenario.rawValue).tag(scenario)
                }
            }
            .pickerStyle(.menu)

            // Show analysis for selected scenario
            ScenarioAnalysisDemoView(scenario: selectedScenario)
        }
        .padding(.vertical, 8)
    }
}

struct ScenarioAnalysisDemoView: View {
    let scenario: TestDataScenario
    @State private var mlAvailable: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(scenario.icon) \(scenario.rawValue)")
                .font(.headline)

            // Show sample habits for this scenario
            Text("Sample Habits:")
                .font(.subheadline)
                .fontWeight(.semibold)

            ForEach(sampleHabits, id: \.0) { habit in
                Text("• \(habit.0)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Show expected vs actual analysis
            VStack(alignment: .leading, spacing: 8) {
                Text("Expected Trait:")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack {
                    Text(expectedTrait)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)

                    Spacer()
                }

                Text("Implementation:")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Keyword")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("✅ Always Active")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    Spacer()

                    if mlAvailable {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ML Embeddings")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("✅ iOS 17+ Devices")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ML Embeddings")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("⚠️ Unavailable")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }

            Text("How It Works:")
                .font(.subheadline)
                .fontWeight(.semibold)

            if mlAvailable {
                Text("On this device, semantic embeddings analyze the meaning and context of habit/category text, matching against trait descriptors using cosine similarity.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Keyword matching looks for specific words in habit/category names. ML semantic embeddings would provide better accuracy on iOS 17+ devices.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            checkMLAvailability()
        }
    }

    private var sampleHabits: [(String, String)] {
        switch scenario {
        case .opennessProfile:
            return [
                ("Try New Restaurant", "Weekly exploration"),
                ("Learn New Language", "Daily learning"),
                ("Creative Writing", "Expression")
            ]
        case .conscientiousnessProfile:
            return [
                ("Morning Routine", "Daily structure"),
                ("Daily Planning", "Organization"),
                ("Track Goals", "Achievement focus")
            ]
        case .extraversionProfile:
            return [
                ("Call Friends", "Social connection"),
                ("Meet New People", "Networking"),
                ("Social Activity", "Group engagement")
            ]
        case .agreeablenessProfile:
            return [
                ("Help Someone", "Altruism"),
                ("Family Time", "Caring"),
                ("Volunteer Work", "Community service")
            ]
        case .neuroticismProfile:
            return [
                ("Stress Management", "Coping"),
                ("Anxiety Journal", "Emotional tracking"),
                ("Therapy Exercises", "Mental health")
            ]
        default:
            return []
        }
    }

    private var expectedTrait: String {
        switch scenario {
        case .opennessProfile: return "Openness to Experience"
        case .conscientiousnessProfile: return "Conscientiousness"
        case .extraversionProfile: return "Extraversion"
        case .agreeablenessProfile: return "Agreeableness"
        case .neuroticismProfile: return "Neuroticism"
        default: return "N/A"
        }
    }

    private func checkMLAvailability() {
        if #available(iOS 17.0, *) {
            mlAvailable = NLEmbedding.wordEmbedding(for: .english) != nil
        } else {
            mlAvailable = false
        }
    }
}

extension TestDataScenario {
    static var personalityProfileCases: [TestDataScenario] {
        return [.opennessProfile, .conscientiousnessProfile, .extraversionProfile, .agreeablenessProfile, .neuroticismProfile]
    }
}

// Preview is available when the debug menu is shown from the main settings view
#endif