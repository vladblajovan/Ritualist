//
//  PersonalityInsightsView.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import SwiftUI
import FactoryKit
import UserNotifications
import RitualistCore

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
            Group {
                if !viewModel.isAnalysisEnabled {
                    // Disabled State with status banner
                    ScrollView {
                        VStack(spacing: 20) {
                            // Status Banner
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                
                                Text("Analysis is disabled")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Button("Enable") {
                                    Task {
                                        await viewModel.toggleAnalysis()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            .padding()
                            .background(Color.red.opacity(0.05))
                            .cornerRadius(8)
                            .padding(.horizontal)
                            
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
                                .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                } else {
                    // Enabled State - Show normal content
                    switch viewModel.viewState {
                    case .loading:
                        VStack {
                            // Status Banner for loading state
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                
                                Text("Analysis is enabled")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    if viewModel.preferences?.analysisFrequency == .manual {
                                        Button {
                                            Task {
                                                await viewModel.triggerManualAnalysisCheck()
                                            }
                                        } label: {
                                            Image(systemName: "arrow.clockwise")
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                        .disabled(!viewModel.isForceRedoAnalysisButtonEnabled || viewModel.isLoading)
                                    }
                                    
                                    Button("Disable") {
                                        Task {
                                            await viewModel.toggleAnalysis()
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            .padding()
                            .background(Color.green.opacity(0.05))
                            .cornerRadius(8)
                            .padding(.horizontal)
                            
                            Spacer()
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                
                                VStack(spacing: 4) {
                                    Text("Analyzing your personality...")
                                        .font(.headline)
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "calendar")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("Based on your last 30 days")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            Spacer()
                        }
                        
                    case .insufficientData(let requirements, let estimatedDays):
                        ScrollView {
                            VStack(spacing: 20) {
                                // Status Banner
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    
                                    Text("Analysis is enabled")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        if viewModel.preferences?.analysisFrequency == .manual {
                                            Button {
                                                Task {
                                                    await viewModel.triggerManualAnalysisCheck()
                                                }
                                            } label: {
                                                Image(systemName: "arrow.clockwise")
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)
                                            .disabled(!viewModel.isForceRedoAnalysisButtonEnabled || viewModel.isLoading)
                                        }
                                        
                                        Button("Disable") {
                                            Task {
                                                await viewModel.toggleAnalysis()
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                }
                                .padding()
                                .background(Color.green.opacity(0.05))
                                .cornerRadius(8)
                                .padding(.horizontal)
                                
                                PersonalityAnalysisInsuficientDataView(
                                    requirements: requirements,
                                    estimatedDays: estimatedDays
                                )
                                .padding(.horizontal)
                            }
                            .padding(.vertical)
                        }
                        
                    case .ready(let profile):
                        ScrollView {
                            VStack(spacing: 24) {
                                // Status Banner
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    
                                    Text("Analysis is enabled")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        if viewModel.preferences?.analysisFrequency == .manual {
                                            Button {
                                                Task {
                                                    await viewModel.triggerManualAnalysisCheck()
                                                }
                                            } label: {
                                                Image(systemName: "arrow.clockwise")
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)
                                            .disabled(!viewModel.isForceRedoAnalysisButtonEnabled || viewModel.isLoading)
                                        }
                                        
                                        Button("Disable") {
                                            Task {
                                                await viewModel.toggleAnalysis()
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                }
                                .padding()
                                .background(Color.green.opacity(0.05))
                                .cornerRadius(8)
                                .padding(.horizontal)
                                
                                // Personality Profile Content
                                PersonalityProfileView(profile: profile)
                            }
                            .padding(.vertical)
                        }
                        
                    case .readyWithInsufficientData(let profile, let requirements, let estimatedDays):
                        ScrollView {
                            VStack(spacing: 24) {
                                // Status Banner
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    
                                    Text("Analysis is enabled")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        if viewModel.preferences?.analysisFrequency == .manual {
                                            Button {
                                                Task {
                                                    await viewModel.triggerManualAnalysisCheck()
                                                }
                                            } label: {
                                                Image(systemName: "arrow.clockwise")
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)
                                            .disabled(!viewModel.isForceRedoAnalysisButtonEnabled || viewModel.isLoading)
                                        }
                                        
                                        Button("Disable") {
                                            Task {
                                                await viewModel.toggleAnalysis()
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                }
                                .padding()
                                .background(Color.green.opacity(0.05))
                                .cornerRadius(8)
                                .padding(.horizontal)
                                
                                // Warning Banner
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    
                                    Text("This analysis is from your previous data. Create more habits to unlock updated analysis.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.orange.opacity(0.05))
                                .cornerRadius(8)
                                .padding(.horizontal)
                                
                                // Personality Profile Content
                                PersonalityProfileView(profile: profile)
                            }
                            .padding(.vertical)
                        }
                        
                    case .error(let error):
                        VStack {
                            // Status Banner
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                
                                Text("Analysis is enabled")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    if viewModel.preferences?.analysisFrequency == .manual {
                                        Button {
                                            Task {
                                                await viewModel.triggerManualAnalysisCheck()
                                            }
                                        } label: {
                                            Image(systemName: "arrow.clockwise")
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                        .disabled(!viewModel.isForceRedoAnalysisButtonEnabled || viewModel.isLoading)
                                    }
                                    
                                    Button("Disable") {
                                        Task {
                                            await viewModel.toggleAnalysis()
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            .padding()
                            .background(Color.green.opacity(0.05))
                            .cornerRadius(8)
                            .padding(.horizontal)
                            
                            Spacer()
                            PersonalityErrorView(error: error) {
                                await viewModel.refresh()
                            }
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Personality Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Privacy") {
                        showingPrivacy = true
                    }
                    .disabled(!viewModel.isAnalysisEnabled)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.loadPersonalityInsights()
        }
        .onAppear {
            // Clear any personality analysis notification badges when user opens insights
            UNUserNotificationCenter.current().setBadgeCount(0)
        }
        .sheet(isPresented: $showingPrivacy) {
            BasicPrivacyView()
                .deviceAwareSheetSizing(
                    compactMultiplier: (min: 0.53, ideal: 0.62, max: 0.79),
                    regularMultiplier: (min: 0.47, ideal: 0.53, max: 0.67),
                    largeMultiplier: (min: 0.39, ideal: 0.50, max: 0.61)
                )
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
        } else {
        }
    }
    
    @MainActor
    private func save() async {
        guard let current = viewModel.preferences else { return }
        let updated = current.updated(
            analysisFrequency: analysisFrequency, allowDataCollection: allowDataCollection
        )
        await viewModel.savePreferences(updated)
        dismiss()
    }
}

private struct PersonalityProfileView: View {
    let profile: PersonalityProfile
    @State private var showingConfidenceInfo = false
    
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
        .sheet(isPresented: $showingConfidenceInfo) {
            ConfidenceInfoSheet(confidence: profile.confidence)
                .deviceAwareSheetSizing(
                    compactMultiplier: (min: 0.53, ideal: 0.62, max: 0.79),
                    regularMultiplier: (min: 0.47, ideal: 0.53, max: 0.67),
                    largeMultiplier: (min: 0.39, ideal: 0.50, max: 0.61)
                )
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
            
            ConfidenceBadge(confidence: profile.confidence) {
                showingConfidenceInfo = true
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.gray.opacity(0.05))
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
                    label: "Date",
                    value: DateFormatter.mediumDateFormatter.string(from: profile.analysisMetadata.analysisDate)
                )
                
                AnalysisDetailRow(
                    label: "Period", value: "Last \(profile.analysisMetadata.timeRangeAnalyzed) days"
                )
                
                AnalysisDetailRow(
                    label: "Data Points",
                    value: "\(profile.analysisMetadata.dataPointsAnalyzed)"
                )
                
                AnalysisDetailRow(
                    label: "Algorithm Version",
                    value: profile.analysisMetadata.version
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.05))
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
        
        for (trait, score) in topTraits where score > 0.6 {
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
                .fill(isDominant ? Color.blue.opacity(0.05) : .gray.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isDominant ? Color.blue.opacity(0.15) : Color.clear, lineWidth: 1)
                )
        )
    }
}

private struct ConfidenceBadge: View {
    let confidence: ConfidenceLevel
    let onInfoTap: (() -> Void)?
    
    init(confidence: ConfidenceLevel, onInfoTap: (() -> Void)? = nil) {
        self.confidence = confidence
        self.onInfoTap = onInfoTap
    }
    
    var body: some View {
        Button(action: {
            onInfoTap?()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(confidence.color)
                
                Text("Confidence level: \(confidence.displayName)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if onInfoTap != nil {
                    Image(systemName: "info.circle.fill")
                        .font(.caption2)
                        .foregroundColor(confidence.color)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(confidence.color.opacity(0.2))
            )
        }
        .buttonStyle(.plain)
        .disabled(onInfoTap == nil)
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
        case .veryHigh: return Color(red: 0.0, green: 0.8, blue: 0.2) // Vibrant green
        }
    }
    
    var displayName: String {
        switch self {
        case .insufficient: return "Insufficient"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .veryHigh: return "Very High"
        }
    }
    
    var explanation: String {
        switch self {
        case .insufficient:
            return "There isn't enough data to provide a reliable personality analysis. More habit tracking is needed."
        case .low:
            return "This analysis is based on limited data. The results give a general indication but may not be highly accurate."
        case .medium:
            return "This analysis is based on a moderate amount of data. The results are reasonably reliable but could improve with more tracking."
        case .high:
            return "This analysis is based on extensive data from your habit tracking. The results are highly reliable and accurately reflect your patterns."
        case .veryHigh:
            return "This analysis is based on comprehensive, long-term data from your habit tracking. The results are exceptionally reliable and provide deep insights into your personality patterns."
        }
    }
    
    var improvementTip: String {
        switch self {
        case .insufficient:
            return "Continue tracking habits daily and create habits across different categories to build up your analysis data."
        case .low:
            return "Keep tracking your habits consistently for a few more weeks to improve analysis accuracy."
        case .medium:
            return "Track more habits or extend your tracking period to reach high confidence analysis."
        case .high:
            return "" // No improvement needed
        case .veryHigh:
            return "" // Maximum confidence achieved
        }
    }
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
    }
}

// MARK: - Confidence Info Sheet

private struct ConfidenceInfoSheet: View {
    let confidence: ConfidenceLevel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header with confidence badge
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundColor(confidence.color)
                    
                    Text("Analysis Confidence")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    ConfidenceBadge(confidence: confidence)
                }
                .padding(.top)
                
                // Explanation
                VStack(alignment: .leading, spacing: 16) {
                    Text("What does this mean?")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(confidence.explanation)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Data requirements
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confidence Levels:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            confidenceLevelRow(.veryHigh, "150+ data points")
                            confidenceLevelRow(.high, "75-149 data points")
                            confidenceLevelRow(.medium, "30-74 data points")  
                            confidenceLevelRow(.low, "Less than 30 data points")
                        }
                        .padding(.leading, 8)
                    }
                    
                    // Improvement tip
                    if confidence != .high {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How to improve:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(confidence.improvementTip)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Confidence Level")
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
    
    private func confidenceLevelRow(_ level: ConfidenceLevel, _ description: String) -> some View {
        HStack {
            Circle()
                .fill(level.color)
                .frame(width: 8, height: 8)
            
            Text(level.rawValue.capitalized)
                .font(.caption)
                .fontWeight(level == confidence ? .semibold : .regular)
            
            Text("- \(description)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}
