import SwiftUI

struct ActiveStreaksCard: View {
    let streaks: [StreakInfo]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🔥 Active Streaks")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text("Stub - Active streaks display")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .cardStyle()
    }
}

#Preview {
    ActiveStreaksCard(streaks: [])
        .padding()
        .background(Color(.systemGroupedBackground))
}