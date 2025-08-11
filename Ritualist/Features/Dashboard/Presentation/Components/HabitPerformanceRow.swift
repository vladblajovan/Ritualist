import SwiftUI

public struct HabitPerformanceRow: View {
    let name: String
    let completionRate: Double
    let emoji: String
    
    public init(name: String, completionRate: Double, emoji: String) {
        self.name = name
        self.completionRate = completionRate
        self.emoji = emoji
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // Emoji
            Text(emoji)
                .font(.title2)
                .frame(width: 32, height: 32)
                .background(CardDesign.secondaryBackground)
                .cornerRadius(8)
            
            // Habit name
            Text(name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
            
            // Progress bar and percentage
            HStack(spacing: 8) {
                // Progress bar
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: 60 * completionRate, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: completionRate)
                }
                
                // Percentage
                Text("\(Int(completionRate * 100))%")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(progressColor)
                    .frame(width: 35, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var progressColor: Color {
        switch completionRate {
        case 0.8...1.0:
            return .green
        case 0.5..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        HabitPerformanceRow(
            name: "Morning Exercise",
            completionRate: 0.92,
            emoji: "🏃‍♂️"
        )
        
        HabitPerformanceRow(
            name: "Read 30 Minutes",
            completionRate: 0.65,
            emoji: "📚"
        )
        
        HabitPerformanceRow(
            name: "Drink Water",
            completionRate: 0.35,
            emoji: "💧"
        )
        
        HabitPerformanceRow(
            name: "Very Long Habit Name That Should Truncate",
            completionRate: 0.78,
            emoji: "✅"
        )
    }
    .padding()
    .background(Color(.systemBackground))
}