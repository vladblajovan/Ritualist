import SwiftUI

public struct StreakInfoView: View {
    let habit: Habit
    let currentStreak: Int
    let bestStreak: Int
    let isLoading: Bool
    let shouldAnimateBestStreak: Bool
    let onAnimationComplete: () -> Void
    
    @State private var animationTrigger = false
    
    public init(habit: Habit, currentStreak: Int, bestStreak: Int, isLoading: Bool, shouldAnimateBestStreak: Bool, onAnimationComplete: @escaping () -> Void) {
        self.habit = habit
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.isLoading = isLoading
        self.shouldAnimateBestStreak = shouldAnimateBestStreak
        self.onAnimationComplete = onAnimationComplete
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            Text(Strings.Overview.stats)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(Strings.Loading.calculatingStreaks)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
            } else {
                HStack(spacing: Spacing.none) {
                    // Current Streak
                    VStack(spacing: Spacing.small) {
                        VStack(spacing: Spacing.xxsmall) {
                            Text(NumberUtils.formatHabitValue(Double(currentStreak)))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: habit.colorHex) ?? AppColors.brand)
                            
                            Text(Strings.Overview.current)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: Spacing.xxsmall) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(currentStreak > 0 ? .orange : .secondary)
                            
                            Text(String(format: String(localized: "overview.day_plural"), currentStreak))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Divider
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 1, height: 50)
                    
                    // Best Streak with animation
                    VStack(spacing: Spacing.small) {
                        VStack(spacing: Spacing.xxsmall) {
                            Text(NumberUtils.formatHabitValue(Double(bestStreak)))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: habit.colorHex) ?? AppColors.brand)
                            
                            Text(Strings.Overview.best)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: Spacing.xxsmall) {
                            Image(systemName: "trophy.fill")
                                .font(.caption)
                                .foregroundColor(bestStreak > 0 ? .yellow : .secondary)
                            
                            Text(String(format: String(localized: "overview.day_plural"), bestStreak))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .bestStreakAnimation(
                        isTriggered: animationTrigger,
                        config: .bestStreak,
                        onAnimationComplete: {
                            animationTrigger = false
                            onAnimationComplete()
                        }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, 16)
            }
        }
        .onChange(of: shouldAnimateBestStreak) { _, newValue in
            if newValue {
                animationTrigger = true
            }
        }
    }
}