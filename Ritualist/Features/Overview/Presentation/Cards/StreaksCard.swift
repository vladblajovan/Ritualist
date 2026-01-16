import SwiftUI
import RitualistCore

// MARK: - Accessibility Strings

private enum StreaksAccessibility {
    static let cardTitle = "Streaks"
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
    @State private var animatingStreakId: String?
    @State private var sheetStreak: StreakInfo?

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

    /// Whether to use single row layout (iPhone with <=2 streaks)
    private var useSingleRowLayout: Bool {
        StreaksLayoutViewLogic.useSingleRowLayout(
            isCompactWidth: horizontalSizeClass == .compact,
            itemCount: streaks.count
        )
    }

    /// Number of rows per column based on device
    private var rowsPerColumn: Int {
        horizontalSizeClass == .regular ? 3 : 2
    }

    /// Grid view for streaks - adapts between single row and multi-row layouts
    @ViewBuilder
    private var streaksGrid: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width

            if useSingleRowLayout {
                // Single row layout for iPhone with 1-2 streaks
                HStack(spacing: itemSpacing) {
                    ForEach(streaks) { streak in
                        streakItem(for: streak, height: itemHeight)
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
                // Multi-row layout with horizontal scroll (2 rows on iPhone, 3 on iPad)
                let rows = rowsPerColumn
                let columnCount = (streaks.count + rows - 1) / rows // Ceiling division
                let needsScroll = columnCount > 2
                let peekWidth: CGFloat = needsScroll ? (horizontalSizeClass == .regular ? 70 : 30) : 0
                // Calculate item width: 2 columns + spacing + peek (if scrolling)
                let calculatedWidth = (availableWidth - itemSpacing - peekWidth) / 2
                let itemWidth = max(calculatedWidth, 120) // Minimum width

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: itemSpacing) {
                        // Group streaks into vertical columns
                        ForEach(Array(stride(from: 0, to: streaks.count, by: rows)), id: \.self) { index in
                            VStack(spacing: rowSpacing) {
                                ForEach(0..<rows, id: \.self) { rowOffset in
                                    if index + rowOffset < streaks.count {
                                        streakItem(for: streaks[index + rowOffset], height: itemHeight)
                                    } else {
                                        // Empty placeholder to maintain layout
                                        Color.clear.frame(height: itemHeight)
                                    }
                                }
                            }
                            .frame(width: itemWidth)
                        }
                    }
                }
            }
        }
        .frame(height: useSingleRowLayout ? itemHeight : itemHeight * CGFloat(rowsPerColumn) + rowSpacing * CGFloat(rowsPerColumn - 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Text("🔥")
                        .font(CardDesign.title2)
                        .accessibilityHidden(true) // Decorative emoji
                    Text(Strings.Overview.streaks)
                        .font(CardDesign.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(StreaksAccessibility.cardTitle)

                Spacer()

                Text("\(streaks.count)")
                    .font(CardDesign.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(CardDesign.secondaryBackground)
                    )
                    .accessibilityLabel(StreaksAccessibility.streakCount(streaks.count))
            }

            if isLoading {
                // Loading state
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)

                    Text(Strings.Overview.loadingStreaks)
                        .font(CardDesign.subheadline)
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
                        .font(CardDesign.title)
                        .foregroundColor(.secondary.opacity(0.6))
                        .accessibilityHidden(true) // Decorative

                    Text(Strings.Overview.noActiveStreaks)
                        .font(CardDesign.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text(Strings.Overview.startCompletingHabits)
                        .font(CardDesign.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(StreaksAccessibility.emptyStateLabel)
            } else {
                // iPhone with <=2 streaks: single row layout
                // iPad or 3+ streaks: 2 rows with horizontal scroll
                streaksGrid
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
            guard !isLoading, !streak.habitName.isEmpty, streak.currentStreak >= 0 else { return }
            sheetStreak = streak
        } label: {
            streakItemContent(for: streak, height: height)
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

    @ViewBuilder
    private func streakItemContent(for streak: StreakInfo, height: CGFloat) -> some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                Text(streak.emoji)
                    .font(CardDesign.title2)
                    .accessibilityHidden(true)

                Text(streak.habitName)
                    .font(CardDesign.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(streak.currentStreak)")
                        .font(CardDesign.body.weight(.bold))
                        .foregroundColor(.primary)

                    Text(streak.flameEmoji)
                        .font(CardDesign.caption2)
                        .accessibilityHidden(true)

                    Text(streak.currentStreak == 1 ? "day" : "days")
                        .font(CardDesign.caption2)
                        .foregroundColor(.secondary)
                }

                if streak.flameCount > 0 {
                    Text(StreakDetailSheet.streakLevelText(for: streak.flameCount))
                        .font(CardDesign.caption2)
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
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Text("Horizontal-First Fill Pattern")
                .font(CardDesign.headline)
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
