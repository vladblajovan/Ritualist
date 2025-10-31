import SwiftUI
import RitualistCore

struct StreaksCard: View {
    let streaks: [StreakInfo]
    let shouldAnimateBestStreak: Bool
    let onAnimationComplete: () -> Void
    let isLoading: Bool
    
    @State private var animatingStreakId: String? = nil
    @State private var sheetStreak: StreakInfo? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("🔥")
                            .font(.title2)
                        Text("Current Streaks")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    Text("Active as of today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(streaks.count) \(streaks.count == 1 ? "streak" : "streaks")")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(CardDesign.secondaryBackground)
                    )
            }
            
            if isLoading {
                // Loading state
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    
                    Text("Loading streaks...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if streaks.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "flame")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.6))
                    
                    Text("No Active Streaks")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("Start completing habits to build your streaks!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Horizontal Scrolling 2x2 Grid
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(streaks) { streak in
                            streakItem(for: streak)
                                .frame(width: 140) // Fixed width for consistent sizing
                        }
                    }
                    .padding(.trailing, 16)
                }
                .frame(height: 220) // Fixed height for 2 rows
            }
        }
        .padding(20)
        // PERFORMANCE: Removed .glassmorphicMaximizedContentStyle() - unnecessary Button wrapper with animation
        // Card is already wrapped in .simpleCard() in OverviewView
        .onAppear {
            if shouldAnimateBestStreak {
                // Find the best streak to animate
                if let bestStreak = streaks.max(by: { $0.currentStreak < $1.currentStreak }) {
                    animatingStreakId = bestStreak.id
                }
            }
        }
        .sheet(item: $sheetStreak) { streak in
            StreakDetailSheet(streak: streak)
        }
    }
    
    @ViewBuilder
    private func streakItem(for streak: StreakInfo) -> some View {
        Button {
            // Ensure we have valid streak data before showing sheet
            guard !isLoading, 
                  !streak.habitName.isEmpty,
                  streak.currentStreak >= 0 else { 
                return 
            }
            sheetStreak = streak
        } label: {
            VStack(spacing: 8) {
                // Habit emoji and name
                VStack(spacing: 4) {
                    Text(streak.emoji)
                        .font(.title2)
                    
                    Text(streak.habitName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                // Streak stats
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Text(streak.flameEmoji)
                            .font(.caption2)
                        
                        Text("\(streak.currentStreak)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(streak.currentStreak == 1 ? "day" : "days")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Show streak level based on flameCount
                    if streak.flameCount > 0 {
                        Text(StreakDetailSheet.streakLevelText(for: streak.flameCount))
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CardDesign.secondaryBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .celebrationAnimation(
            isTriggered: animatingStreakId == streak.id,
            config: .bestStreak,
            onAnimationComplete: {
                animatingStreakId = nil
                onAnimationComplete()
            }
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        StreaksCard(
            streaks: [
                StreakInfo(
                    id: "1",
                    habitName: "Morning Workout",
                    emoji: "💪",
                    currentStreak: 7,
                    isActive: true
                ),
                StreakInfo(
                    id: "2",
                    habitName: "Reading",
                    emoji: "📚",
                    currentStreak: 3,
                    isActive: true
                ),
                StreakInfo(
                    id: "3",
                    habitName: "Water Intake",
                    emoji: "💧",
                    currentStreak: 12,
                    isActive: true
                )
            ],
            shouldAnimateBestStreak: false,
            onAnimationComplete: {},
            isLoading: false
        )
        
        // Loading state
        StreaksCard(
            streaks: [],
            shouldAnimateBestStreak: false,
            onAnimationComplete: {},
            isLoading: true
        )
        
        // Empty state
        StreaksCard(
            streaks: [],
            shouldAnimateBestStreak: false,
            onAnimationComplete: {},
            isLoading: false
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
