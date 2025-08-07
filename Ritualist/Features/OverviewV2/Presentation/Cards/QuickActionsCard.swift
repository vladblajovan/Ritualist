import SwiftUI

struct QuickActionsCard: View {
    let incompleteHabits: [Habit]
    let onHabitComplete: (Habit) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("⚡ Quick Log")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text("Stub - Quick Actions for incomplete habits")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .cardStyle()
    }
}

#Preview {
    QuickActionsCard(incompleteHabits: [], onHabitComplete: { _ in })
        .padding()
        .background(Color(.systemGroupedBackground))
}