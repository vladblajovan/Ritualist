//
//  PersonalityInsightsView.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import SwiftUI
import FactoryKit

/// Main view for displaying personality insights in Settings
public struct PersonalityInsightsView: View {
    
    @StateObject private var viewModel: PersonalityInsightsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingPrivacy = false
    
    public init(viewModel: PersonalityInsightsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationView {
            VStack {
                // Status Banner
                HStack {
                    Image(systemName: viewModel.isAnalysisEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(viewModel.isAnalysisEnabled ? .green : .red)
                    
                    Text(viewModel.isAnalysisEnabled ? "Analysis is enabled" : "Analysis is disabled")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
                .padding()
                .background(viewModel.isAnalysisEnabled ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                
                // Main Content
                Group {
                    if !viewModel.isAnalysisEnabled {
                        // Disabled State
                        VStack(spacing: 20) {
                            Image(systemName: "person.crop.circle.badge.xmark")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            
                            Text("Personality Analysis Disabled")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Enable analysis to discover your Big Five personality traits based on your habit patterns.")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Enabled State - Show normal content
                        switch viewModel.viewState {
                        case .loading:
                            ProgressView("Analyzing your personality...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                        case .insufficientData(let requirements, let estimatedDays):
                            ScrollView {
                                DataThresholdPlaceholderView(
                                    requirements: requirements,
                                    estimatedDays: estimatedDays
                                )
                                .padding()
                            }
                            
                        case .ready(let profile):
                            PersonalityProfileView(profile: profile)
                            
                        case .error(let error):
                            PersonalityErrorView(error: error) {
                                await viewModel.refresh()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Personality Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("Privacy") {
                            showingPrivacy = true
                        }
                        
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(viewModel.isAnalysisEnabled ? "Disable" : "Enable") {
                        Task {
                            await viewModel.toggleAnalysis()
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadPersonalityInsights()
        }
        .sheet(isPresented: $showingPrivacy) {
            BasicPrivacyView()
        }
    }
}

// MARK: - Basic Privacy View (Step 1)

private struct BasicPrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    @Injected(\.personalityInsightsViewModel) private var viewModel: PersonalityInsightsViewModel
    @State private var allowDataCollection = true
    @State private var analysisFrequency: AnalysisFrequency = .weekly
    @State private var hasLoaded = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Allow Data Collection", isOn: $allowDataCollection)
                } footer: {
                    Text("Control whether new habit data can be used for personality analysis.")
                }
                
                Section {
                    NavigationLink {
                        FrequencySelectionView(selectedFrequency: $analysisFrequency)
                            .onDisappear {
                                print("🔍 NavigationLink returning with frequency: \(analysisFrequency.rawValue)")
                            }
                    } label: {
                        HStack {
                            Text("Analysis Frequency")
                            Spacer()
                            Text(analysisFrequency.displayName)
                                .foregroundColor(.secondary)
                        }
                    }
                } footer: {
                    Text("How often personality analysis is performed.")
                }
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await save() }
                    }
                }
            }
            .task { 
                if !hasLoaded {
                    await load()
                    hasLoaded = true
                }
            }
        }
    }
    
    @MainActor
    private func load() async {
        await viewModel.loadPreferences()
        if let prefs = viewModel.preferences {
            allowDataCollection = prefs.allowDataCollection
            analysisFrequency = prefs.analysisFrequency
            print("🔍 BasicPrivacyView loaded - allowDataCollection: \(allowDataCollection), frequency: \(analysisFrequency.rawValue)")
        } else {
            print("🔍 BasicPrivacyView loaded - no preferences found, using defaults")
        }
    }
    
    @MainActor
    private func save() async {
        guard let current = viewModel.preferences else { return }
        print("🔍 BasicPrivacyView saving - allowDataCollection: \(allowDataCollection), frequency: \(analysisFrequency.rawValue)")
        let updated = current.updated(
            analysisFrequency: analysisFrequency, allowDataCollection: allowDataCollection
        )
        await viewModel.savePreferences(updated)
        dismiss()
    }
}

private struct PersonalityProfileView: View {
    let profile: PersonalityProfile
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                dominantTraitSection
                
                allTraitsSection
                
                analysisDetailsSection
                
                insightsSection
            }
            .padding()
        }
    }
    
    private var dominantTraitSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("Your Dominant Trait")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(profile.dominantTrait.displayName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(profile.dominantTrait.highScoreDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            ConfidenceBadge(confidence: profile.confidence)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var allTraitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Personality Traits")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 12) {
                ForEach(profile.traitsByScore, id: \.trait) { item in
                    TraitRowView(
                        trait: item.trait,
                        score: item.score,
                        isDominant: item.trait == profile.dominantTrait
                    )
                }
            }
        }
    }
    
    private var analysisDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis Details")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                AnalysisDetailRow(
                    label: "Analysis Date",
                    value: DateFormatter.mediumDateFormatter.string(from: profile.analysisMetadata.analysisDate)
                )
                
                AnalysisDetailRow(
                    label: "Data Points Analyzed",
                    value: "\(profile.analysisMetadata.dataPointsAnalyzed)"
                )
                
                AnalysisDetailRow(
                    label: "Time Range",
                    value: "\(profile.analysisMetadata.timeRangeAnalyzed) days"
                )
                
                AnalysisDetailRow(
                    label: "Analysis Version",
                    value: profile.analysisMetadata.version
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights for Habit Building")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Based on your personality profile, consider these approaches:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(personalityInsights, id: \.self) { insight in
                    InsightRowView(insight: insight)
                }
            }
        }
    }
    
    private var personalityInsights: [String] {
        var insights: [String] = []
        
        let topTraits = profile.traitsByScore.prefix(3)
        
        for (trait, score) in topTraits {
            if score > 0.6 {
                switch trait {
                case .openness:
                    insights.append("Try creative or novel activities to leverage your openness")
                case .conscientiousness:
                    insights.append("Set structured schedules to match your organized nature")
                case .extraversion:
                    insights.append("Include social habits to match your outgoing personality")
                case .agreeableness:
                    insights.append("Consider habits that help others or build community")
                case .neuroticism:
                    insights.append("Focus on stress-reduction and mindfulness practices")
                }
            }
        }
        
        if insights.isEmpty {
            insights.append("Your balanced personality allows flexibility in habit choices")
        }
        
        return insights
    }
}

private struct TraitRowView: View {
    let trait: PersonalityTrait
    let score: Double
    let isDominant: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(trait.displayName)
                    .font(.headline)
                    .fontWeight(isDominant ? .semibold : .medium)
                
                Text(trait.shortDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(score * 100))%")
                    .font(.headline)
                    .fontWeight(isDominant ? .semibold : .medium)
                    .foregroundColor(isDominant ? .blue : .primary)
                
                ProgressView(value: score)
                    .frame(width: 60)
                    .tint(isDominant ? .blue : .gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDominant ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isDominant ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

private struct ConfidenceBadge: View {
    let confidence: ConfidenceLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(confidence.color)
            
            Text(confidence.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(confidence.color.opacity(0.2))
        )
    }
}

private struct AnalysisDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

private struct InsightRowView: View {
    let insight: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.caption)
            
            Text(insight)
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }
}

private struct PersonalityErrorView: View {
    let error: PersonalityAnalysisError
    let onRetry: () async -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Analysis Unavailable")
                    .font(.headline)
                
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if let recovery = error.recoverySuggestion {
                    Text(recovery)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            
            if error.isRecoverable {
                Button("Try Again") {
                    Task {
                        await onRetry()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

private extension ConfidenceLevel {
    var color: Color {
        switch self {
        case .insufficient: return .gray
        case .low: return .red
        case .medium: return .orange
        case .high: return .green
        }
    }
}

private extension DateFormatter {
    static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

#Preview {
    let sampleProfile = PersonalityProfile(
        id: UUID(),
        userId: UUID(),
        traitScores: [
            .conscientiousness: 0.85,
            .openness: 0.72,
            .agreeableness: 0.68,
            .extraversion: 0.45,
            .neuroticism: 0.32
        ],
        dominantTrait: .conscientiousness,
        confidence: .high,
        analysisMetadata: AnalysisMetadata(
            analysisDate: Date(),
            dataPointsAnalyzed: 156,
            timeRangeAnalyzed: 30,
            version: "1.0"
        )
    )
    
    PersonalityProfileView(profile: sampleProfile)
}

// MARK: - Frequency Selection View

private struct FrequencySelectionView: View {
    @Binding var selectedFrequency: AnalysisFrequency
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(AnalysisFrequency.allCases, id: \.self) { frequency in
                Button {
                    print("🔍 User selected frequency: \(frequency.rawValue)")
                    selectedFrequency = frequency
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(frequency.displayName)
                                .font(.body)
                                .foregroundColor(.primary)
                            Text(frequency.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selectedFrequency == frequency {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Analysis Frequency")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("🔍 FrequencySelectionView appeared with: \(selectedFrequency.rawValue)")
        }
    }
}
