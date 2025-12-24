import SwiftUI
import RitualistCore

// MARK: - Accessibility Strings

private enum StreaksAccessibility {
    static let cardTitle = "Current Streaks"
    static func streakCount(_ count: Int) -> String {
        count == 1 ? "1 active streak" : "\(count) active streaks"
    }
    static func streakItem(habitName: String, days: Int, level: String?) -> String {
        var label = "\(habitName), \(days) day streak"
        if let level = level {
            label += ", \(level)"
        }
        return label
    }
    static let streakItemHint = "Double tap for streak details"
    static let emptyStateLabel = "No active streaks. Start completing habits to build your streaks."
    static let loadingLabel = "Loading streaks"
}

struct StreaksCard: View {
    let streaks: [StreakInfo]
    let shouldAnimateBestStreak: Bool
    let onAnimationComplete: () -> Void
    let isLoading: Bool

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var animatingStreakId: String? = nil
    @State private var sheetStreak: StreakInfo? = nil

    // MARK: - Layout Configuration

    /// Height of each streak item
    private let itemHeight: CGFloat = 100

    /// Spacing between rows
    private let rowSpacing: CGFloat = 12

    /// Spacing between items in a row
    private let itemSpacing: CGFloat = 12

    /// Layout context for view logic calculations
    private var layoutContext: StreaksLayoutViewLogic.LayoutContext {
        StreaksLayoutViewLogic.LayoutContext(
            itemCount: streaks.count,
            itemHeight: itemHeight,
            rowSpacing: rowSpacing
        )
    }

    /// Calculate the number of rows needed based on streak count
    /// - For 1-2 streaks: 1 row
    /// - For 3+ streaks: 2 rows
    private var numberOfRows: Int {
        StreaksLayoutViewLogic.numberOfRows(for: streaks.count)
    }

    /// Calculate the dynamic height based on number of rows
    /// - 1 row: itemHeight
    /// - 2 rows: itemHeight * 2 + rowSpacing
    private var gridHeight: CGFloat {
        StreaksLayoutViewLogic.gridHeight(for: layoutContext)
    }

    /// Organize streaks into rows for horizontal-first filling
    /// - Row 1: First ceil(count/2) items
    /// - Row 2: Remaining items
    private var streakRows: [[StreakInfo]] {
        StreaksLayoutViewLogic.distributeItems(streaks)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Text("🔥")
                        .font(.title2)
                        .accessibilityHidden(true) // Decorative emoji
                    Text("Current Streaks")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(StreaksAccessibility.cardTitle)

                Spacer()

                Text("\(streaks.count) \(streaks.count == 1 ? "streak" : "streaks")")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(CardDesign.secondaryBackground)
                    )
                    .accessibilityLabel(StreaksAccessibility.streakCount(streaks.count))
            }

            // Only add spacer on iPad for equal-height matching in side-by-side layout
            if horizontalSizeClass == .regular {
                Spacer(minLength: 0)
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel(StreaksAccessibility.loadingLabel)
            } else if streaks.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "flame")
                        .font(.title)
                        .foregroundColor(.secondary.opacity(0.6))
                        .accessibilityHidden(true) // Decorative

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
                .accessibilityElement(children: .combine)
                .accessibilityLabel(StreaksAccessibility.emptyStateLabel)
            } else {
                // Horizontal Scrolling Grid (horizontal-first filling)
                // Use GeometryReader to calculate dynamic item heights
                GeometryReader { geometry in
                    let numRows = numberOfRows
                    let availableHeight = geometry.size.height
                    // Scale to fill space when 2 rows; keep fixed height for 1 row
                    let dynamicItemHeight = numRows > 1
                        ? (availableHeight - CGFloat(numRows - 1) * rowSpacing) / CGFloat(numRows)
                        : itemHeight

                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: rowSpacing) {
                            ForEach(Array(streakRows.enumerated()), id: \.offset) { _, rowStreaks in
                                HStack(spacing: itemSpacing) {
                                    ForEach(rowStreaks) { streak in
                                        streakItem(for: streak, height: dynamicItemHeight)
                                            .frame(width: 140) // Fixed width for consistent sizing
                                    }
                                }
                            }
                        }
                        .padding(.trailing, 16)
                    }
                }
                .frame(minHeight: gridHeight) // Minimum height based on row count, can expand
                // Prevent flash during layout recalculations
                .transaction { $0.animation = nil }
            }

            // Only add spacer on iPad for equal-height matching in side-by-side layout
            if horizontalSizeClass == .regular {
                Spacer(minLength: 0)
            }
        }
        .accessibilityIdentifier("streaks_card")
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
    private func streakItem(for streak: StreakInfo, height: CGFloat) -> some View {
        let streakLevel = streak.flameCount > 0 ? StreakDetailSheet.streakLevelText(for: streak.flameCount) : nil

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
                        .accessibilityHidden(true) // Emoji is decorative, info is in label

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
                            .accessibilityHidden(true) // Decorative flame

                        Text("\(streak.currentStreak)")
                            .font(.body.weight(.bold))
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
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CardDesign.secondaryBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(StreaksAccessibility.streakItem(
            habitName: streak.habitName,
            days: streak.currentStreak,
            level: streakLevel
        ))
        .accessibilityHint(StreaksAccessibility.streakItemHint)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("streak_item_\(streak.id)")
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
    ScrollView {
        VStack(spacing: 20) {
            Text("Horizontal-First Fill Pattern")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            // 1 streak: Row 1 [1]
            StreaksCard(
                streaks: [
                    StreakInfo(id: "1", habitName: "Workout", emoji: "💪", currentStreak: 7, isActive: true)
                ],
                shouldAnimateBestStreak: false,
                onAnimationComplete: {},
                isLoading: false
            )

            // 2 streaks: Row 1 [1, 2]
            StreaksCard(
                streaks: [
                    StreakInfo(id: "1", habitName: "Workout", emoji: "💪", currentStreak: 7, isActive: true),
                    StreakInfo(id: "2", habitName: "Reading", emoji: "📚", currentStreak: 3, isActive: true)
                ],
                shouldAnimateBestStreak: false,
                onAnimationComplete: {},
                isLoading: false
            )

            // 3 streaks: Row 1 [1, 2] Row 2 [3]
            StreaksCard(
                streaks: [
                    StreakInfo(id: "1", habitName: "Workout", emoji: "💪", currentStreak: 7, isActive: true),
                    StreakInfo(id: "2", habitName: "Reading", emoji: "📚", currentStreak: 3, isActive: true),
                    StreakInfo(id: "3", habitName: "Water", emoji: "💧", currentStreak: 12, isActive: true)
                ],
                shouldAnimateBestStreak: false,
                onAnimationComplete: {},
                isLoading: false
            )

            // 4 streaks: Row 1 [1, 2] Row 2 [3, 4]
            StreaksCard(
                streaks: [
                    StreakInfo(id: "1", habitName: "Workout", emoji: "💪", currentStreak: 7, isActive: true),
                    StreakInfo(id: "2", habitName: "Reading", emoji: "📚", currentStreak: 3, isActive: true),
                    StreakInfo(id: "3", habitName: "Water", emoji: "💧", currentStreak: 12, isActive: true),
                    StreakInfo(id: "4", habitName: "Meditation", emoji: "🧘", currentStreak: 5, isActive: true)
                ],
                shouldAnimateBestStreak: false,
                onAnimationComplete: {},
                isLoading: false
            )

            // 5 streaks: Row 1 [1, 2, 3] Row 2 [4, 5]
            StreaksCard(
                streaks: [
                    StreakInfo(id: "1", habitName: "Workout", emoji: "💪", currentStreak: 7, isActive: true),
                    StreakInfo(id: "2", habitName: "Reading", emoji: "📚", currentStreak: 3, isActive: true),
                    StreakInfo(id: "3", habitName: "Water", emoji: "💧", currentStreak: 12, isActive: true),
                    StreakInfo(id: "4", habitName: "Meditation", emoji: "🧘", currentStreak: 5, isActive: true),
                    StreakInfo(id: "5", habitName: "Journaling", emoji: "📝", currentStreak: 9, isActive: true)
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
    }
    .background(Color(.systemGroupedBackground))
}
