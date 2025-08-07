import SwiftUI

struct WeeklyOverviewCard: View {
    let progress: WeeklyProgress?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("📅 This Week")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text("Stub - Weekly overview with mini calendar")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .cardStyle()
    }
}

#Preview {
    WeeklyOverviewCard(progress: nil)
        .padding()
        .background(Color(.systemGroupedBackground))
}