import SwiftUI

struct SmartInsightsCard: View {
    let insights: [SmartInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("💡 Smart Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text("Stub - Smart insights and patterns")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .cardStyle()
    }
}

#Preview {
    SmartInsightsCard(insights: [])
        .padding()
        .background(Color(.systemGroupedBackground))
}