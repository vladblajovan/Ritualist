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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                Button(action: {
                    // TODO: Navigate to full personality analysis
                }) {
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
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(insights.prefix(3)) { insight in
                        InsightRow(insight: insight)
                    }
                    
                    // Show more indicator if there are additional insights
                    if insights.count > 3 {
                        HStack {
                            Text("View \(insights.count - 3) more insights")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                        .onTapGesture {
                            // TODO: Navigate to full personality analysis
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

private struct InsightRow: View {
    let insight: OverviewPersonalityInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.type.icon)
                .font(.body)
                .foregroundColor(insight.type.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(insight.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
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
                    dominantTrait: "Conscientiousness"
                )
                
                // Empty state
                PersonalityInsightsCard(
                    insights: [],
                    dominantTrait: nil
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}