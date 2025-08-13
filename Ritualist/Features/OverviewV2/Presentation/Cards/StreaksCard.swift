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
                HStack(spacing: 8) {
                    Text("🔥")
                        .font(.title2)
                    Text("Active Streaks")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
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
        .cardStyle()
        .onAppear {
            if shouldAnimateBestStreak {
                // Find the best streak to animate
                if let bestStreak = streaks.max(by: { $0.currentStreak < $1.currentStreak }) {
                    animatingStreakId = bestStreak.id
                }
            }
        }
        .sheet(item: $sheetStreak) { streak in
            streakDetailSheet(for: streak)
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
                        Text(streakLevelText(for: streak.flameCount))
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
    
    @ViewBuilder
    private func streakDetailSheet(for streak: StreakInfo) -> some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text(streak.emoji)
                            .font(.system(size: 48))
                        
                        Text(streak.habitName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Stats
                    HStack(spacing: 0) {
                        // Current Streak
                        VStack(spacing: 8) {
                            VStack(spacing: 4) {
                                Text("\(streak.currentStreak)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.brand)
                                
                                Text("Current")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 4) {
                                Text(streak.flameEmoji)
                                    .font(.caption)
                                
                                Text(streak.currentStreak == 1 ? "day" : "days")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Divider
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(width: 1, height: 60)
                        
                        // Streak Level
                        VStack(spacing: 8) {
                            VStack(spacing: 4) {
                                Text("\(streak.flameCount)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.brand)
                                
                                Text("Level")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(streak.flameCount > 0 ? .yellow : .secondary)
                                
                                Text(streakLevelText(for: streak.flameCount))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.gray.opacity(0.1))
                    )
                    
                    // Explanation
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About Streaks")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("**Current Streak**: Consecutive days ending with today")
                                .font(.subheadline)
                            
                            Text("**Best Streak**: Your longest consecutive sequence ever")
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(16)
            }
            .padding()
            .navigationTitle("Streak Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        sheetStreak = nil
                    }
                }
            }
        }
        .presentationDetents([.height(500)])
        .presentationDragIndicator(.visible)
    }
    
    private func streakLevelText(for flameCount: Int) -> String {
        switch flameCount {
        case 3: return "Fire Master"
        case 2: return "Strong"
        case 1: return "Building"
        default: return "Starting"
        }
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