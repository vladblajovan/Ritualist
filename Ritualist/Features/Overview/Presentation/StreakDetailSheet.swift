import SwiftUI
import RitualistCore

struct StreakDetailSheet: View {
    let streak: StreakInfo
    @Environment(\.dismiss) private var dismiss

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer()
                    
                    // Header
                    VStack(spacing: 12) {
                        Text(streak.emoji)
                            .font(.system(size: 48)) // Keep fixed for decorative emoji
                            .accessibilityHidden(true)
                        
                        Text(streak.habitName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                    
                    // Stats
                    HStack(spacing: 0) {
                        // Current Streak
                        VStack(spacing: 8) {
                            VStack(spacing: 4) {
                                Text("\(streak.currentStreak)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.brand)
                                
                                Text("Days Active")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 4) {
                                Text(streak.flameEmoji)
                                    .font(.caption)
                                
                                Text("consecutive \(streak.currentStreak == 1 ? "day" : "days")")
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
                                Text(streak.flameEmoji.isEmpty ? "🔥" : streak.flameEmoji)
                                    .font(.title)
                                
                                Text("Achievement")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(streak.flameCount > 0 ? .yellow : .secondary)
                                
                                Text(Self.streakLevelText(for: streak.flameCount))
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
                        Text("How Streaks Work")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("**Days Active**: Your current consecutive streak ending today")
                                .font(.subheadline)
                            
                            Text("**Achievement Levels**: Based on streak length")
                                .font(.subheadline)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("🔥")
                                    Text("7+ days: Building")
                                        .font(.subheadline)
                                }
                                HStack {
                                    Text("🔥🔥")
                                    Text("14+ days: Strong")
                                        .font(.subheadline)
                                }
                                HStack {
                                    Text("🔥🔥🔥")
                                    Text("30+ days: Fire Master")
                                        .font(.subheadline)
                                }
                            }
                            .padding(.leading, 16)
                            .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(16)
                }
                .padding()
            }
            .navigationTitle("Streak Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .presentationDetents(isIPad ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
    }
    
    static func streakLevelText(for flameCount: Int) -> String {
        switch flameCount {
        case 3: return "Fire Master"
        case 2: return "Strong"
        case 1: return "Building"
        default: return "Starting"
        }
    }
}

#Preview {
    StreakDetailSheet(
        streak: StreakInfo(
            id: "1",
            habitName: "Morning Workout",
            emoji: "💪",
            currentStreak: 15,
            isActive: true
        )
    )
}
