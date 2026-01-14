//
//  PersonalityInsightsView.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 06.08.2025.
//

import SwiftUI
import FactoryKit
import UserNotifications
import RitualistCore

/// Main view for displaying personality insights in Settings
public struct PersonalityInsightsView: View {
    
    @State private var viewModel: PersonalityInsightsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingPrivacy = false
    
    public init(viewModel: PersonalityInsightsViewModel) {
        self._viewModel = State(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationView {
            Group {
                if !viewModel.isAnalysisEnabled {
                    // Disabled State
                    disabledStateView
                } else {
                    // Enabled State - Show content based on viewState
                    switch viewModel.viewState {
                    case .loading:
                        loadingView

                    case .insufficientData(let requirements, let estimatedDays):
                        ScrollView {
                            PersonalityAnalysisInsuficientDataView(
                                requirements: requirements,
                                estimatedDays: estimatedDays
                            )
                            .padding()
                        }

                    case .ready(let profile):
                        PersonalityProfileView(profile: profile)

                    case .readyWithInsufficientData(let profile, _, _):
                        ScrollView {
                            VStack(spacing: 16) {
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

                                PersonalityProfileView(profile: profile)
                            }
                            .padding()
                        }

                    case .error(let error):
                        PersonalityErrorView(error: error) {
                            await viewModel.refresh()
                        }
                    }
                }
            }
            .navigationTitle(Strings.PersonalityInsights.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Settings") {
                        showingPrivacy = true
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .task {
            await viewModel.loadPersonalityInsights()
        }
        .onAppear {
            // Clear any personality analysis notification badges when user opens insights
            UNUserNotificationCenter.current().setBadgeCount(0)
        }
        .fullScreenCover(isPresented: $showingPrivacy) {
            SettingsView()
                .background(.ultraThinMaterial)
        }
    }

    // MARK: - Helper Views

    private var disabledStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Personality Analysis Disabled")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Enable analysis in Settings to discover your Big Five personality traits based on your habit patterns.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button {
                showingPrivacy = true
            } label: {
                Text("Open Settings")
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer()

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

            Spacer()
        }
    }
}

// MARK: - Settings View

private struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Injected(\.personalityInsightsViewModel) private var viewModel: PersonalityInsightsViewModel
    @State private var analysisFrequency: AnalysisFrequency = .weekly
    @State private var isEnabled: Bool = true
    @State private var hasLoaded = false
    @State private var isToggling = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.title2)
                            .foregroundColor(.green)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your data stays on this device")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("Personality analysis is performed locally. Your habit data and personality insights are never sent to any server.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Toggle("Enable Analysis", isOn: $isEnabled)
                        .disabled(isToggling)
                        .onChange(of: isEnabled) { _, newValue in
                            Task {
                                isToggling = true
                                await viewModel.setAnalysisEnabled(newValue)
                                isToggling = false
                            }
                        }
                } footer: {
                    Text("When enabled, your habit patterns are analyzed to generate personality insights.")
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
                    .disabled(!isEnabled)

                    Button {
                        Task {
                            await viewModel.triggerManualAnalysisCheck()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Regenerate Analysis")
                        }
                    }
                    .disabled(!isEnabled || !viewModel.isForceRedoAnalysisButtonEnabled || viewModel.isLoading)
                } footer: {
                    Text("How often personality analysis is performed. Regenerate to update analysis with latest habit data.")
                }
            }
            .navigationTitle(Strings.PersonalityInsights.settingsTitle)
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
            analysisFrequency = prefs.analysisFrequency
            isEnabled = prefs.isEnabled
        }
    }

    @MainActor
    private func save() async {
        guard let current = viewModel.preferences else { return }
        let updated = current.updated(
            analysisFrequency: analysisFrequency
        )
        await viewModel.savePreferences(updated)
        dismiss()
    }
}

private struct PersonalityProfileView: View {
    let profile: PersonalityProfile
    @State private var showingConfidenceInfo = false
    @Injected(\.settingsViewModel) private var settingsVM
    @Injected(\.personalityInsightsViewModel) private var insightsVM

    // Avatar sizing (larger than header avatar)
    private let avatarSize: CGFloat = 72

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // New Analysis Banner (dismissible)
                if insightsVM.hasUnseenAnalysis {
                    newAnalysisBanner
                }

                dominantTraitSection

                insightsSection

                allTraitsSection

                analysisDetailsSection
            }
            .padding()
            .animation(.easeOut(duration: 0.2), value: insightsVM.hasUnseenAnalysis)
        }
        .task {
            // Ensure profile is loaded for avatar display
            if settingsVM.profile.name.isEmpty {
                await settingsVM.load()
            }
        }
        .sheet(isPresented: $showingConfidenceInfo) {
            ConfidenceInfoSheet(confidence: profile.confidence)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
        }
    }
    
    private var dominantTraitSection: some View {
        VStack(spacing: 16) {
            profileAvatarView

            VStack(spacing: 8) {
                Text("Your Dominant Trait")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text(profile.dominantTrait.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(profile.dominantTrait.highScoreDescription)
                    .font(.subheadline)
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
                    label: "Generated",
                    value: profile.analysisMetadata.analysisDate.relativeOrAbsoluteString()
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
        VStack(spacing: 12) {
            Text("Insights for Habit Building")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Based on your personality profile, consider these approaches:")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(personalityInsights, id: \.self) { insight in
                    InsightRowView(insight: insight)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.gray.opacity(0.05))
        )
    }

    // MARK: - Profile Avatar

    @ViewBuilder
    private var profileAvatarView: some View {
        let contentType = AppBrandHeaderViewLogic.avatarContentType(
            hasAvatarImage: settingsVM.profile.avatarImageData != nil,
            name: settingsVM.profile.name
        )

        ZStack {
            // Gradient background (always shown, unless there's an image)
            if contentType != .image {
                Circle()
                    .fill(GradientTokens.profileIcon)
                    .frame(width: avatarSize, height: avatarSize)
            }

            // Inner content based on type
            switch contentType {
            case .image:
                if let imageData = settingsVM.profile.avatarImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: avatarSize, height: avatarSize)
                        .clipShape(Circle())
                }
            case .initials:
                Text(AppBrandHeaderViewLogic.avatarInitials(from: settingsVM.profile.name))
                    .font(.system(size: avatarSize * 0.38, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            case .empty:
                EmptyView()
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

    // MARK: - New Analysis Banner

    private var newAnalysisBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(.linearGradient(
                    colors: [.purple, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            VStack(alignment: .leading, spacing: 2) {
                Text("New Analysis Available")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("Your personality insights have been updated")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    insightsVM.markAnalysisAsSeen()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.linearGradient(
                    colors: [.purple.opacity(0.08), .blue.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.linearGradient(
                            colors: [.purple.opacity(0.2), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), lineWidth: 1)
                )
        )
        .transition(.asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        ))
    }
}

private struct TraitRowView: View {
    let trait: PersonalityTrait
    let score: Double
    let isDominant: Bool
    @State private var showingInfo = false

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

            Button {
                showingInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
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
        .sheet(isPresented: $showingInfo) {
            BigFiveInfoSheet(highlightedTrait: trait)
        }
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
        Button(
            action: { onInfoTap?() },
            label: {
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
        )
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
            return "Great job! Your analysis is highly reliable. Keep tracking to maintain accuracy."
        case .veryHigh:
            return "Excellent! You've achieved maximum confidence in your personality analysis."
        }
    }

    var tipHeader: String {
        switch self {
        case .insufficient, .low, .medium:
            return "How to improve:"
        case .high, .veryHigh:
            return "Status:"
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
        .navigationTitle(Strings.PersonalityInsights.analysisFrequency)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Confidence Info Sheet

private struct ConfidenceInfoSheet: View {
    let confidence: ConfidenceLevel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with confidence badge
                    VStack(spacing: 12) {
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

                        // Tip section
                        VStack(alignment: .leading, spacing: 8) {
                            Text(confidence.tipHeader)
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
                .padding()
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
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

// MARK: - Big Five Info Sheet

struct BigFiveInfoSheet: View {
    let highlightedTrait: PersonalityTrait?
    @Environment(\.dismiss) private var dismiss

    init(highlightedTrait: PersonalityTrait? = nil) {
        self.highlightedTrait = highlightedTrait
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Introduction
                        VStack(alignment: .leading, spacing: 12) {
                            Text("The Big Five Personality Model")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("The Big Five, also known as OCEAN, is the most widely accepted scientific model for understanding personality. It identifies five core dimensions that describe human personality traits.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        // Traits
                        VStack(alignment: .leading, spacing: 16) {
                            Text("The Five Traits")
                                .font(.headline)

                            ForEach(PersonalityTrait.allCases, id: \.self) { trait in
                                traitInfoCard(trait)
                                    .id(trait)
                            }
                        }

                        // How it's used
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How We Use It")
                                .font(.headline)

                            Text("Ritualist analyzes your habit patterns to estimate your personality profile. This helps provide personalized insights and recommendations for building habits that align with your natural tendencies.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.blue.opacity(0.05))
                        )
                    }
                    .padding()
                }
                .onAppear {
                    if let trait = highlightedTrait {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(trait, anchor: .center)
                            }
                        }
                    }
                }
            }
            .navigationTitle(Strings.PersonalityInsights.aboutBigFive)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
    }

    private func traitInfoCard(_ trait: PersonalityTrait) -> some View {
        let isHighlighted = trait == highlightedTrait

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trait.emoji)
                    .font(.title2)

                Text(trait.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                if isHighlighted {
                    Text("Your tap")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }

            Text(trait.shortDescription)
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text("High:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(width: 40, alignment: .leading)
                    Text(trait.highScoreDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(alignment: .top) {
                    Text("Low:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(width: 40, alignment: .leading)
                    Text(trait.lowScoreDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHighlighted ? Color.blue.opacity(0.05) : .gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isHighlighted ? Color.blue.opacity(0.2) : Color.clear, lineWidth: 1)
                )
        )
    }
}
