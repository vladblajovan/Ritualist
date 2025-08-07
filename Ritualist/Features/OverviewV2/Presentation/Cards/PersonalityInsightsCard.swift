import SwiftUI

public struct OverviewPersonalityInsight: Identifiable, Hashable {
    public let id = UUID()
    public let title: String
    public let message: String
    public let type: OverviewPersonalityInsightType
    
    public init(title: String, message: String, type: OverviewPersonalityInsightType) {
        self.title = title
        self.message = message
        self.type = type
    }
}

public enum OverviewPersonalityInsightType: CaseIterable {
    case pattern
    case recommendation  
    case motivation
    
    public var icon: String {
        switch self {
        case .pattern:
            return "brain.head.profile"
        case .recommendation:
            return "lightbulb"
        case .motivation:
            return "heart"
        }
    }
    
    public var color: Color {
        switch self {
        case .pattern:
            return .purple
        case .recommendation:
            return .orange
        case .motivation:
            return .pink
        }
    }
}

struct PersonalityInsightsCard: View {
    let insights: [OverviewPersonalityInsight]
    let dominantTrait: String?
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
                
                // Link to full analysis
                Button(action: onOpenAnalysis) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Insights List
            if insights.isEmpty {
                // Empty state (should rarely happen due to auto-generation)
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("Personality insights will appear here once your analysis is complete")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 16) {
                    ForEach(Array(insights.prefix(isExpanded ? insights.count : 3).enumerated()), id: \.element.id) { index, insight in
                        InsightRow(insight: insight)
                        
                        if index < min(insights.count, isExpanded ? insights.count : 3) - 1 {
                            Divider()
                                .opacity(0.3)
                        }
                    }
                    
                    // Show more/less indicator if there are additional insights
                    if insights.count > 3 {
                        HStack {
                            Text(isExpanded ? "Show less" : "View \(insights.count - 3) more insights")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isExpanded.toggle()
                                }
                            } label: {
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .cardStyle()
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
                        .font(.system(size: 15, weight: .medium))
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
                    onOpenAnalysis: { }
                )
                
                // Empty state
                PersonalityInsightsCard(
                    insights: [],
                    dominantTrait: nil,
                    onOpenAnalysis: { }
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}