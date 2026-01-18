//
//  PersonalityInsightsView+Sheets.swift
//  Ritualist
//
//  Sheet views extracted from PersonalityInsightsView to reduce file length.
//

import SwiftUI
import RitualistCore

// MARK: - Confidence Badge

struct ConfidenceBadge: View {
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

// MARK: - Frequency Selection View

struct FrequencySelectionView: View {
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

struct ConfidenceInfoSheet: View {
    let confidence: ConfidenceLevel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isIPad: Bool { horizontalSizeClass == .regular }

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
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents(isIPad ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
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
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func traitInfoCard(_ trait: PersonalityTrait) -> some View {
        let isHighlighted = trait == highlightedTrait
        return VStack(alignment: .leading, spacing: 8) {
            traitInfoHeader(trait: trait, isHighlighted: isHighlighted)
            Text(trait.shortDescription).font(.caption).foregroundColor(.secondary)
            traitScoreDescriptions(trait: trait)
        }
        .padding()
        .background(traitInfoCardBackground(isHighlighted: isHighlighted))
    }

    @ViewBuilder
    private func traitInfoHeader(trait: PersonalityTrait, isHighlighted: Bool) -> some View {
        HStack {
            Text(trait.emoji).font(.title2)
            Text(trait.displayName).font(.subheadline).fontWeight(.semibold)
            Spacer()
            if isHighlighted {
                Text("Your tap").font(.caption2).foregroundColor(.blue)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1)).cornerRadius(4)
            }
        }
    }

    @ViewBuilder
    private func traitScoreDescriptions(trait: PersonalityTrait) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Text("High:").font(.caption).fontWeight(.medium).frame(width: 40, alignment: .leading)
                Text(trait.highScoreDescription).font(.caption).foregroundColor(.secondary)
            }
            HStack(alignment: .top) {
                Text("Low:").font(.caption).fontWeight(.medium).frame(width: 40, alignment: .leading)
                Text(trait.lowScoreDescription).font(.caption).foregroundColor(.secondary)
            }
        }.padding(.top, 4)
    }

    private func traitInfoCardBackground(isHighlighted: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isHighlighted ? Color.blue.opacity(0.05) : .gray.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isHighlighted ? Color.blue.opacity(0.2) : Color.clear, lineWidth: 1))
    }
}
