import SwiftUI
import RitualistCore

struct PersonalityInsightsCard: View {
    let insights: [OverviewPersonalityInsight]
    let dominantTrait: String?
    let isDataSufficient: Bool
    let thresholdRequirements: [ThresholdRequirement]
    let onOpenAnalysis: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(CardDesign.title2)
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Overview.personalityInsights)
                        .font(CardDesign.headline)
                        .foregroundColor(.primary)

                    if let trait = dominantTrait {
                        Text(Strings.Overview.basedOnProfile(trait.lowercased()))
                            .font(CardDesign.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Navigation indicator
                Image(systemName: "chevron.right")
                    .font(CardDesign.body.weight(.medium))
                    .foregroundColor(.secondary)
            }

            // Content based on state
            if !insights.isEmpty {
                // Show existing insights (even if data is now insufficient for new analysis)
                insightsContent

                // If data is now insufficient, show warning
                if !isDataSufficient {
                    warningBanner
                }
            } else if !isDataSufficient {
                // No insights and insufficient data - show requirements
                insufficientDataContent
            } else {
                // No insights but data is sufficient - show loading/error state
                noInsightsContent
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onOpenAnalysis()
        }
    }

    // MARK: - Content Views

    @ViewBuilder
    private var insightsContent: some View {
        let initialInsightsCount = 3
        // On large screens (iPad), show all insights in 2 columns
        let isRegular = horizontalSizeClass == .regular
        let visibleCount = isRegular || isExpanded ? insights.count : initialInsightsCount

        if isRegular {
            // iPad: 2-column grid layout
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 12) {
                ForEach(insights.prefix(visibleCount), id: \.id) { insight in
                    InsightRow(insight: insight)
                }
            }
        } else {
            // iPhone: single column with dividers
            VStack(spacing: 16) {
                ForEach(Array(insights.prefix(visibleCount).enumerated()), id: \.element.id) { index, insight in
                    InsightRow(insight: insight)

                    if index < visibleCount - 1 {
                        Divider()
                            .opacity(0.3)
                    }
                }

                // Show more/less indicator only on compact screens (iPhone) with additional insights
                if insights.count > initialInsightsCount {
                    HStack {
                        Text(isExpanded ? "Show less" : "View \(insights.count - initialInsightsCount) more insights")
                            .font(CardDesign.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(CardDesign.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        TapGesture().onEnded {
                            animateIfAllowed(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        }
                    )
                    .accessibilityLabel(isExpanded ? "Show less insights" : "View \(insights.count - 3) more insights")
                    .accessibilityHint("Double-tap to \(isExpanded ? "collapse" : "expand") the insights list")
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
    }
    
    @ViewBuilder
    private var warningBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(CardDesign.caption)
                .foregroundColor(.orange)
            
            Text(Strings.Overview.insightsFromPreviousAnalysis)
                .font(CardDesign.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private var insufficientDataContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Strings.Overview.completeRequirements)
                .font(CardDesign.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                ForEach(thresholdRequirements, id: \.id) { requirement in
                    HStack {
                        Image(systemName: requirement.isMet ? "checkmark.circle.fill" : "circle")
                            .font(CardDesign.caption)
                            .foregroundColor(requirement.isMet ? .green : .secondary)

                        Text(requirement.name)
                            .font(CardDesign.caption2)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(requirement.currentValue)/\(requirement.requiredValue)")
                            .font(CardDesign.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var noInsightsContent: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .font(CardDesign.title3)
                .foregroundColor(.secondary)
            
            Text(Strings.Overview.analysisInProgress)
                .font(CardDesign.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

private struct InsightRow: View {
    let insight: OverviewPersonalityInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Insight Icon
                Image(systemName: insight.type.icon)
                    .font(CardDesign.title3)
                    .frame(width: 32, height: 32)
                    .background(insight.type.color.opacity(0.1))
                    .foregroundColor(insight.type.color)
                    .clipShape(Circle())
                
                // Insight Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(CardDesign.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(insight.message)
                        .font(CardDesign.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Type indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(insight.type.color.opacity(0.2))
                    .frame(width: 4, height: 32)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

struct PersonalityInsightsCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                // With insights
                PersonalityInsightsCard(
                    insights: [
                        OverviewPersonalityInsight(
                            title: "Strong Conscientiousness Pattern",
                            message: "Your habits strongly reflect conscientiousness tendencies. Continue leveraging this strength while exploring habits that develop other traits.",
                            type: .pattern
                        ),
                        OverviewPersonalityInsight(
                            title: "Schedule-Based Success",
                            message: "Try structured routines, time-blocking, and milestone tracking for better results.",
                            type: .recommendation
                        ),
                        OverviewPersonalityInsight(
                            title: "Build on Discipline",
                            message: "Your natural discipline is your superpower. Focus on consistency over intensity.",
                            type: .motivation
                        )
                    ],
                    dominantTrait: "Conscientiousness",
                    isDataSufficient: false, // Show warning banner
                    thresholdRequirements: [],
                    onOpenAnalysis: { }
                )
                
                // Insufficient data state
                PersonalityInsightsCard(
                    insights: [],
                    dominantTrait: nil,
                    isDataSufficient: false,
                    thresholdRequirements: [
                        ThresholdRequirement(name: "Active Habits", description: "Track at least 5 active habits", currentValue: 2, requiredValue: 5, category: .habits),
                        ThresholdRequirement(name: "Days Tracked", description: "Log habits for 7 days", currentValue: 3, requiredValue: 7, category: .tracking)
                    ],
                    onOpenAnalysis: { }
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
