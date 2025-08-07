import SwiftUI

struct MonthlyCalendarCard: View {
    @Binding var isExpanded: Bool
    let calendar: [Date: [Habit]]
    let onDateSelect: (Date) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("📆 Calendar")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("expand") {
                    isExpanded.toggle()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Text("Stub - Monthly calendar view")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .cardStyle()
    }
}

#Preview {
    MonthlyCalendarCard(
        isExpanded: .constant(false),
        calendar: [:],
        onDateSelect: { _ in }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}