//
//  TestDataScenariosView.swift
//  Ritualist
//
//  Created by Claude on 01.11.2025.
//

import SwiftUI
import RitualistCore
import NaturalLanguage

#if DEBUG
struct TestDataScenariosView: View {
    @Bindable var vm: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                Text("Choose a test data scenario to populate the database. Each scenario represents a different user journey stage with specific data characteristics.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Available Scenarios")
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
        }
        .navigationTitle("Test Data Scenarios")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
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
                VStack(alignment: .leading, spacing: 6) {
                    Text("• Custom Categories: 100% semantic analysis of habit/category names")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("• Predefined Categories: 60% psychology prior + 40% semantic habit analysis")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Example: 'Health' category suggests conscientiousness, but habits like 'Manage anxiety symptoms' shift analysis toward neuroticism using semantic embeddings.")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .italic()
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("• Keyword matching looks for specific words in habit/category names")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("• ML semantic embeddings (iOS 17+) would capture nuanced meaning and context, improving accuracy for predefined categories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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
        [.opennessProfile, .conscientiousnessProfile, .extraversionProfile, .agreeablenessProfile, .neuroticismProfile]
    }
}

#endif
