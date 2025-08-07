import SwiftUI

public struct StreakInfoView: View {
    let habit: Habit
    let currentStreak: Int
    let bestStreak: Int
    let isLoading: Bool
    let shouldAnimateBestStreak: Bool
    let onAnimationComplete: () -> Void
    
    @State private var animationTrigger = false
    @State private var showingCurrentStreakInfo = false
    @State private var showingBestStreakInfo = false
    
    public init(habit: Habit, currentStreak: Int, bestStreak: Int, isLoading: Bool, shouldAnimateBestStreak: Bool, onAnimationComplete: @escaping () -> Void) {
        self.habit = habit
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.isLoading = isLoading
        self.shouldAnimateBestStreak = shouldAnimateBestStreak
        self.onAnimationComplete = onAnimationComplete
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(Strings.Overview.stats)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, Spacing.large)
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(ScaleFactors.smallMedium)
                    Text(Strings.Loading.calculatingStreaks)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, Spacing.large)
            } else {
                HStack(spacing: Spacing.none) {
                    // Current Streak
                    VStack(spacing: Spacing.small) {
                        VStack(spacing: Spacing.xxsmall) {
                            Text(NumberUtils.formatHabitValue(Double(currentStreak)))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.brand)
                            
                            HStack(spacing: Spacing.xxsmall) {
                                Text(Strings.Overview.current)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Image(systemName: "info.circle")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack(spacing: Spacing.xxsmall) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(currentStreak > 0 ? .orange : .secondary)
                            
                            Text(Strings.Overview.dayPlural(currentStreak))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingCurrentStreakInfo = true
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: ComponentSize.separatorThin, height: ComponentSize.avatarMedium + Spacing.xxsmall)
                    
                    // Best Streak with animation
                    VStack(spacing: Spacing.small) {
                        VStack(spacing: Spacing.xxsmall) {
                            Text(NumberUtils.formatHabitValue(Double(bestStreak)))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.brand)
                            
                            HStack(spacing: Spacing.xxsmall) {
                                Text(Strings.Overview.best)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Image(systemName: "info.circle")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack(spacing: Spacing.xxsmall) {
                            Image(systemName: "trophy.fill")
                                .font(.caption)
                                .foregroundColor(bestStreak > 0 ? .yellow : .secondary)
                            
                            Text(Strings.Overview.dayPlural(bestStreak))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingBestStreakInfo = true
                    }
                    .bestStreakAnimation(
                        isTriggered: animationTrigger,
                        config: .bestStreak,
                        onAnimationComplete: {
                            animationTrigger = false
                            onAnimationComplete()
                        }
                    )
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.xlarge)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, Spacing.large)
            }
        }
        .onChange(of: shouldAnimateBestStreak) { _, newValue in
            if newValue {
                animationTrigger = true
            }
        }
        .sheet(isPresented: $showingCurrentStreakInfo) {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.large) {
                        VStack(alignment: .leading, spacing: Spacing.medium) {
                            Text("Current Streak")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Consecutive days ending with today (counting backwards until first gap)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: Spacing.small) {
                            Text("How it works:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            VStack(alignment: .leading, spacing: Spacing.small) {
                                Text("• Starts from today and counts backwards")
                                Text("• Stops at the first day you missed the habit")
                                Text("• Resets to 0 if you miss today")
                                Text("• Only includes days you've completed the habit")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        
                        Text("Example: If you completed your habit today, yesterday, and 3 days ago (but missed 2 days ago), your current streak is 1 day.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding()
                }
                .navigationTitle("Current Streak")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingCurrentStreakInfo = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingBestStreakInfo) {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.large) {
                        VStack(alignment: .leading, spacing: Spacing.medium) {
                            Text("Best Streak")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Longest consecutive sequence in the entire habit history (could be from any time period)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: Spacing.small) {
                            Text("How it works:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            VStack(alignment: .leading, spacing: Spacing.small) {
                                Text("• Looks at your entire habit history")
                                Text("• Finds the longest unbroken chain of consecutive days")
                                Text("• Can be from any time period (past or present)")
                                Text("• Never decreases - it's your personal record")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        
                        Text("Example: If you had a 10-day streak last month and your current streak is 3 days, your best streak remains 10 days.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding()
                }
                .navigationTitle("Best Streak")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingBestStreakInfo = false
                        }
                    }
                }
            }
        }
    }
}