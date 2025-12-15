import SwiftUI
import RitualistCore

struct PersonalityInsightsCard: View {
    let insights: [OverviewPersonalityInsight]
    let dominantTrait: String?
    let isDataSufficient: Bool
    let thresholdRequirements: [ThresholdRequirement]
    let onOpenAnalysis: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Personality Insights")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let trait = dominantTrait {
                        Text("Based on your \(trait.lowercased()) profile")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Link to full analysis - only this icon opens the sheet
                Button(action: onOpenAnalysis) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .contentShape(Circle())
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
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
        .padding(20)
        // PERFORMANCE: Removed .glassmorphicMaximizedContentStyle() - unnecessary Button wrapper with animation
        // Card is already wrapped in .simpleCard() in OverviewView
        // Only the top-right icon should open the analysis sheet
    }
    
    // MARK: - Content Views
    
    @ViewBuilder
    private var insightsContent: some View {
        let initialInsightsCount = 3

        VStack(spacing: 16) {
            ForEach(Array(insights.prefix(isExpanded ? insights.count : initialInsightsCount).enumerated()), id: \.element.id) { index, insight in
                InsightRow(insight: insight)

                if index < min(insights.count, isExpanded ? insights.count : initialInsightsCount) - 1 {
                    Divider()
                        .opacity(0.3)
                }
            }

            // Show more/less indicator if there are additional insights
            if insights.count > initialInsightsCount {
                HStack {
                    Text(isExpanded ? "Show less" : "View \(insights.count - initialInsightsCount) more insights")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    // Expand/collapse handled by tap on this row only
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    animateIfAllowed(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }
                .accessibilityLabel(isExpanded ? "Show less insights" : "View \(insights.count - 3) more insights")
                .accessibilityHint("Double-tap to \(isExpanded ? "collapse" : "expand") the insights list")
                .accessibilityAddTraits(.isButton)
            }
        }
    }
    
    @ViewBuilder
    private var warningBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(.orange)
            
            Text("These insights are from your previous analysis. Create more habits to unlock new analysis.")
                .font(.caption)
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
            HStack {
                Image(systemName: "chart.bar")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Text("Not enough data for personality analysis")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("Complete these requirements to unlock insights:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                ForEach(thresholdRequirements, id: \.id) { requirement in
                    HStack {
                        Image(systemName: requirement.isMet ? "checkmark.circle.fill" : "circle")
                            .font(.caption)
                            .foregroundColor(requirement.isMet ? .green : .secondary)

                        Text(requirement.name)
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(requirement.currentValue)/\(requirement.requiredValue)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder 
    private var noInsightsContent: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text("Analysis in progress... Check back soon!")
                .font(.subheadline)
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
                    .font(.title3)
                    .frame(width: 32, height: 32)
                    .background(insight.type.color.opacity(0.1))
                    .foregroundColor(insight.type.color)
                    .clipShape(Circle())
                
                // Insight Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(insight.message)
                        .font(.caption)
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
                        ThresholdRequirement(name: "Consistent Tracking", description: "Log habits for 7 days", currentValue: 3, requiredValue: 7, category: .tracking)
                    ],
                    onOpenAnalysis: { }
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
