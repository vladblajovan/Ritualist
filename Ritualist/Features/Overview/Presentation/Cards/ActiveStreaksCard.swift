import SwiftUI
import RitualistCore

struct ActiveStreaksCard: View {
    let streaks: [StreakInfo]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Text("🔥")
                        .font(.title2)
                    Text("Active Streaks")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            
            if streaks.isEmpty {
                // Empty State
                VStack(spacing: 12) {
                    Text("🎯")
                        .font(.system(size: 32))
                        .opacity(0.6)
                    
                    VStack(spacing: 4) {
                        Text("No Active Streaks")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Complete habits 3+ days in a row to start a streak!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                // Streaks Display
                VStack(spacing: 16) {
                    ForEach(Array(streaks.prefix(5).enumerated()), id: \.element.id) { index, streak in
                        HStack(spacing: 16) {
                            // Habit Emoji
                            Text(streak.emoji)
                                .font(.title2)
                                .frame(width: 32, height: 32)
                                .background(CardDesign.secondaryBackground)
                                .clipShape(Circle())
                            
                            // Habit Info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(streak.habitName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Text("\(streak.currentStreak) days")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Streak Display
                            HStack(spacing: 4) {
                                Text("\(streak.currentStreak)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(streakColor(for: streak.currentStreak))
                                
                                Text(streak.flameEmoji)
                                    .font(.system(size: 16))
                                    .scaleEffect(streak.flameCount > 1 ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.1), value: streak.flameCount)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(streakColor(for: streak.currentStreak).opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(streakColor(for: streak.currentStreak).opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.vertical, 4)
                        
                        if index < streaks.prefix(5).count - 1 {
                            Divider()
                                .opacity(0.3)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
    
    private func streakColor(for days: Int) -> Color {
        if days >= 30 { return Color.purple }
        else if days >= 14 { return Color.orange }
        else if days >= 7 { return Color.green }
        else { return Color.blue }
    }
}

#Preview {
    VStack(spacing: 20) {
        // With Streaks
        ActiveStreaksCard(streaks: [
            StreakInfo(id: "1", habitName: "Morning Workout", emoji: "💪", currentStreak: 21, isActive: true),
            StreakInfo(id: "2", habitName: "Daily Reading", emoji: "📚", currentStreak: 14, isActive: true),
            StreakInfo(id: "3", habitName: "Water Intake", emoji: "💧", currentStreak: 7, isActive: true),
            StreakInfo(id: "4", habitName: "Meditation", emoji: "🧘", currentStreak: 5, isActive: true)
        ])
        
        // Empty State
        ActiveStreaksCard(streaks: [])
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
