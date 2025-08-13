import SwiftUI
import RitualistCore

struct SmartInsightsCard: View {
    let insights: [SmartInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Text("💡")
                        .font(.title2)
                    Text("Weekly Insights")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if !insights.isEmpty {
                    Text("This Week")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(CardDesign.secondaryBackground)
                        )
                }
            }
            
            if insights.isEmpty {
                // Need More Data State
                VStack(spacing: 12) {
                    Text("📊")
                        .font(.system(size: 32))
                        .opacity(0.6)
                    
                    VStack(spacing: 4) {
                        Text("Gathering Insights")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Complete habits for 2 weeks to unlock personalized insights about your patterns.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                // Insights Display
                VStack(spacing: 16) {
                    ForEach(insights.prefix(3).indices, id: \.self) { index in
                        let insight = insights[index]
                        insightRow(for: insight, index: index)
                        
                        if index < min(insights.count, 3) - 1 {
                            Divider()
                                .opacity(0.3)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
    
    @ViewBuilder
    private func insightRow(for insight: SmartInsight, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Insight Icon
                Text(insightIcon(for: insight.type))
                    .font(.title3)
                    .frame(width: 32, height: 32)
                    .background(insightColor(for: insight.type).opacity(0.1))
                    .foregroundColor(insightColor(for: insight.type))
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
                    .fill(insightColor(for: insight.type).opacity(0.2))
                    .frame(width: 4, height: 32)
            }
        }
        .padding(.vertical, 2)
        .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.1), value: insights.count)
    }
    
    private func insightIcon(for type: SmartInsight.InsightType) -> String {
        switch type {
        case .pattern:
            return "📈"
        case .suggestion:
            return "💡"
        case .celebration:
            return "🎉"
        case .warning:
            return "⚠️"
        }
    }
    
    private func insightColor(for type: SmartInsight.InsightType) -> Color {
        switch type {
        case .pattern:
            return CardDesign.progressGreen
        case .suggestion:
            return AppColors.brand
        case .celebration:
            return CardDesign.progressOrange
        case .warning:
            return CardDesign.progressRed
        }
    }
}

// Sample insights for preview
extension SmartInsight {
    static var sampleInsights: [SmartInsight] {
        [
            SmartInsight(
                title: "You're strongest on Tuesdays",
                message: "87% completion rate vs. 65% average",
                type: .pattern
            ),
            SmartInsight(
                title: "Morning habits stick better",
                message: "3x more likely to complete before 10 AM",
                type: .suggestion
            ),
            SmartInsight(
                title: "Weekend consistency needs work",
                message: "Only 45% completion on weekends",
                type: .warning
            )
        ]
    }
}

#Preview {
    VStack(spacing: 20) {
        // With insights
        SmartInsightsCard(insights: SmartInsight.sampleInsights)
        
        // Empty state
        SmartInsightsCard(insights: [])
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
