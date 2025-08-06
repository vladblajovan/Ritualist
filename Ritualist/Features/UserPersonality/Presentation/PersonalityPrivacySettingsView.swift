//
//  PersonalityPrivacySettingsView.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import SwiftUI
import FactoryKit

// swiftlint:disable type_body_length
public struct PersonalityPrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Injected(\.personalityInsightsViewModel) private var viewModel
    
    @State private var showingDeleteConfirmation = false
    @State private var showingDataUsageInfo = false
    
    // Local state for form - will be set from viewModel on load
    @State private var isEnabled = false
    @State private var analysisFrequency: AnalysisFrequency = .weekly
    @State private var dataRetentionDays = 365
    @State private var allowDataCollection = true
    @State private var enabledTraits: Set<PersonalityTrait> = Set(PersonalityTrait.allCases)
    @State private var sensitivityLevel: AnalysisSensitivity = .standard
    @State private var shareInsights = false
    @State private var allowFutureEnhancements = true
    @State private var showDataUsage = true
    
    public var body: some View {
        Group {
                if viewModel.isLoadingPreferences {
                    ProgressView("Loading privacy settings...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Form {
                        personalityAnalysisSection
                        dataControlSection
                        analysisCustomizationSection
                        privacyTransparencySection
                        dataManagementSection
                    }
                }
            }
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await savePreferences() }
                    }
                    .fontWeight(.semibold)
                    .disabled(!hasChanges)
                }
            }
            .task { await loadPreferences() }
            .onAppear {
                // Initialize local state from ViewModel on appear
                if let prefs = viewModel.preferences {
                    isEnabled = prefs.isEnabled
                    analysisFrequency = prefs.analysisFrequency
                    dataRetentionDays = prefs.dataRetentionDays
                    allowDataCollection = prefs.allowDataCollection
                    enabledTraits = prefs.enabledTraits
                    sensitivityLevel = prefs.sensitivityLevel
                    shareInsights = prefs.shareInsights
                    allowFutureEnhancements = prefs.allowFutureEnhancements
                    showDataUsage = prefs.showDataUsage
                }
            }
            .alert("Delete All Personality Data?", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task { await deleteAllData() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your personality analysis history. This action cannot be undone.")
            }
            .sheet(isPresented: $showingDataUsageInfo) {
                DataUsageInfoView()
            }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private var personalityAnalysisSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Personality Analysis")
                        .font(.headline)
                    Text(isEnabled ? "Analysis is enabled" : "Analysis is disabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isEnabled)
                    .toggleStyle(SwitchToggleStyle())
            }
            .padding(.vertical, 4)
            
            if isEnabled {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analysis Frequency")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(analysisFrequency.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Picker("", selection: $analysisFrequency) {
                        ForEach(AnalysisFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.displayName)
                                .tag(frequency)
                        }
                    }
                    .pickerStyle(.automatic)
                    .foregroundColor(.blue)
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("Analysis Control")
        } footer: {
            if isEnabled {
                Text("Personality analysis uses your habit tracking patterns to provide insights about your Big Five personality traits.")
            } else {
                Text("When disabled, no new personality analysis will be performed, but existing data is preserved.")
            }
        }
    }
    
    @ViewBuilder
    private var dataControlSection: some View {
        if isEnabled {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Data Retention Period")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(dataRetentionDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Picker("", selection: $dataRetentionDays) {
                        Text("30 days").tag(30)
                        Text("3 months").tag(90)
                        Text("1 year").tag(365)
                        Text("Forever").tag(-1)
                    }
                    .pickerStyle(.automatic)
                    .foregroundColor(.blue)
                }
                .padding(.vertical, 8)
                
                Toggle("Allow Data Collection", isOn: $allowDataCollection)
                    .disabled(!isEnabled)
            } header: {
                Text("Data Management")
            } footer: {
                Text("Control how long your personality analysis data is stored and whether new data can be collected for analysis.")
            }
        }
    }
    
    @ViewBuilder
    private var analysisCustomizationSection: some View {
        if isEnabled {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Personality Traits to Analyze")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(PersonalityTrait.allCases, id: \.self) { trait in
                            Button {
                                toggleTrait(trait)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: enabledTraits.contains(trait) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(enabledTraits.contains(trait) ? .blue : .secondary)
                                        .font(.system(size: 16))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(trait.displayName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        Text(trait.shortDescription)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(enabledTraits.contains(trait) ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                                .cornerRadius(8)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(enabledTraits.contains(trait) ? Color.blue : Color.secondary.opacity(0.3), lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analysis Detail Level")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(sensitivityLevel.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Picker("", selection: $sensitivityLevel) {
                        ForEach(AnalysisSensitivity.allCases, id: \.self) { level in
                            Text(level.displayName)
                                .tag(level)
                        }
                    }
                    .pickerStyle(.automatic)
                    .foregroundColor(.blue)
                }
                .padding(.vertical, 8)
            } header: {
                Text("Analysis Customization")
            } footer: {
                Text("Choose which personality traits to analyze and how detailed the analysis should be. You need at least 3 traits selected.")
            }
        }
    }
    
    @ViewBuilder
    private var privacyTransparencySection: some View {
        Section {
            Toggle("Show Data Usage Details", isOn: $showDataUsage)
            
            Button {
                showingDataUsageInfo = true
            } label: {
                HStack {
                    Text("What Data is Used?")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
            }
            
            Toggle("Allow Future Enhancements", isOn: $allowFutureEnhancements)
        } header: {
            Text("Privacy & Transparency")
        } footer: {
            Text("Control transparency features and whether to participate in future analysis improvements.")
        }
    }
    
    @ViewBuilder
    private var dataManagementSection: some View {
        Section {
            Button("Delete All Personality Data") {
                showingDeleteConfirmation = true
            }
            .foregroundColor(.red)
            
            if let preferences = viewModel.preferences, let lastAnalysis = preferences.lastAnalysisDate {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Analysis")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(DateFormatter.mediumDateFormatter.string(from: lastAnalysis))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Data Management")
        } footer: {
            Text("Permanently delete all stored personality analysis data. You can always generate new analysis later.")
        }
    }
    
    // MARK: - Helper Methods
    
    private var hasChanges: Bool {
        guard let preferences = viewModel.preferences else { return false }
        
        return isEnabled != preferences.isEnabled ||
               analysisFrequency != preferences.analysisFrequency ||
               dataRetentionDays != preferences.dataRetentionDays ||
               allowDataCollection != preferences.allowDataCollection ||
               enabledTraits != preferences.enabledTraits ||
               sensitivityLevel != preferences.sensitivityLevel ||
               shareInsights != preferences.shareInsights ||
               allowFutureEnhancements != preferences.allowFutureEnhancements ||
               showDataUsage != preferences.showDataUsage
    }
    
    private var dataRetentionDescription: String {
        switch dataRetentionDays {
        case 30: return "Data is deleted after 30 days"
        case 90: return "Data is deleted after 3 months"
        case 365: return "Data is deleted after 1 year"
        case -1: return "Data is kept indefinitely"
        default: return "Custom retention period"
        }
    }
    
    private func toggleTrait(_ trait: PersonalityTrait) {
        if enabledTraits.contains(trait) {
            // Don't allow removing if it would leave less than 3 traits
            if enabledTraits.count > 3 {
                enabledTraits.remove(trait)
            }
        } else {
            enabledTraits.insert(trait)
        }
    }
    
    @MainActor
    private func loadPreferences() async {
        // Get current preferences from ViewModel
        await viewModel.loadPreferences()
        
        // Update local state from viewModel preferences
        if let currentPrefs = viewModel.preferences {
            isEnabled = currentPrefs.isEnabled
            analysisFrequency = currentPrefs.analysisFrequency
            dataRetentionDays = currentPrefs.dataRetentionDays
            allowDataCollection = currentPrefs.allowDataCollection
            enabledTraits = currentPrefs.enabledTraits
            sensitivityLevel = currentPrefs.sensitivityLevel
            shareInsights = currentPrefs.shareInsights
            allowFutureEnhancements = currentPrefs.allowFutureEnhancements
            showDataUsage = currentPrefs.showDataUsage
        }
    }
    
    @MainActor
    private func savePreferences() async {
        guard let currentPrefs = viewModel.preferences else { return }
        
        let updatedPrefs = currentPrefs.updated(
            isEnabled: isEnabled,
            analysisFrequency: analysisFrequency,
            dataRetentionDays: dataRetentionDays,
            allowDataCollection: allowDataCollection,
            pausedUntil: nil, // Always clear pause state for simplicity
            enabledTraits: enabledTraits,
            sensitivityLevel: sensitivityLevel,
            shareInsights: shareInsights,
            allowFutureEnhancements: allowFutureEnhancements,
            showDataUsage: showDataUsage
        )
        
        await viewModel.savePreferences(updatedPrefs)
        dismiss()
    }
    
    @MainActor
    private func deleteAllData() async {
        await viewModel.deleteAllPersonalityData()
        // TODO: Show success feedback
        dismiss()
    }
}
// swiftlint:enable type_body_length

// MARK: - Data Usage Info View

private struct DataUsageInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How We Analyze Your Personality")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Your personality analysis is based entirely on your habit tracking patterns. All analysis happens locally on your device.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Data We Use")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach([
                            ("Habit Selection", "Types of habits you choose to track"),
                            ("Completion Patterns", "How consistently you complete habits"),
                            ("Custom Habits", "Habits you create vs. suggested habits"),
                            ("Categories", "How you organize your habits"),
                            ("Tracking Duration", "How long you maintain habits")
                        ], id: \.0) { title, description in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Data We Don't Use")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach([
                            "Personal information or contacts",
                            "Location data or device identifiers",
                            "Text content or habit names",
                            "External app data or integrations",
                            "Any data outside the Ritualist app"
                        ], id: \.self) { item in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 16))
                                
                                Text(item)
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Privacy Rights")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("• All analysis happens locally on your device\n• You can disable analysis at any time\n• You control which traits are analyzed\n• You can delete all personality data\n• Your data is never shared or transmitted")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Data Usage")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Extensions

private extension DateFormatter {
    static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    PersonalityPrivacySettingsView()
}
