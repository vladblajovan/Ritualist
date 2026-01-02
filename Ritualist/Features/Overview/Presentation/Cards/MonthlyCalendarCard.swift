import SwiftUI
import Foundation
import RitualistCore

// MARK: - Layout Constants

/// Named constants for calendar grid layout calculations.
/// Centralized here for maintainability and documentation.
private enum CalendarLayout {
    /// Circle diameter as fraction of column width (75%)
    static let circleSizeRatio: CGFloat = 0.75
    /// Maximum circle size in points for consistent touch targets
    static let maxCellSize: CGFloat = 36
    /// Maximum vertical spacing between rows to prevent excessive gaps in landscape
    static let maxVerticalSpacing: CGFloat = 20
    /// Bottom padding cap for iPhone landscape mode (empirically tuned)
    static let landscapePaddingCap: CGFloat = 10
    /// Default bottom padding cap for portrait and iPad
    static let defaultPaddingCap: CGFloat = 2
    /// Font size as fraction of circle diameter for readability
    static let fontSizeRatio: CGFloat = 0.39
    /// Top buffer to prevent border clipping when today is in first row (border lineWidth/2)
    static let topBuffer: CGFloat = 1
    /// Buffer for border stroke that extends outside circle bounds
    static let borderStrokeBuffer: CGFloat = 2
}

// MARK: - Day Display Data

/// Pre-computed day data - ALL properties calculated ONCE when month changes
private struct DayDisplayData: Identifiable {
    let id: String
    let date: Date
    let dayNumber: Int
    let bgColor: Color
    let textColor: Color
    let hasBorder: Bool
    let opacity: Double
    let isCurrentMonth: Bool
    let row: Int
    let col: Int
}

// PERFORMANCE: Complete rewrite using Canvas for MAXIMUM performance
struct MonthlyCalendarCard: View {
    let monthlyData: [Date: Double]
    let onDateSelect: (Date) -> Void
    /// The timezone used for all date calculations. Should match the timezone used to generate monthlyData keys.
    let timezone: TimeZone

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var currentDate = Date()
    @State private var displayDays: [DayDisplayData] = []
    @State private var canvasSize: CGSize = .zero // Stored geometry for layout calculations

    private var calendar: Calendar {
        CalendarUtils.localCalendar(for: timezone)
    }

    /// Computed layout metrics derived from stored canvas size.
    /// Single source of truth for both Canvas rendering and tap detection.
    private var layout: LayoutMetrics {
        let columnWidth = canvasSize.width / 7
        let cellSize = min(columnWidth * CalendarLayout.circleSizeRatio, CalendarLayout.maxCellSize)
        let verticalSpacing = min(columnWidth - cellSize, CalendarLayout.maxVerticalSpacing)
        let isIPhoneLandscape = horizontalSizeClass == .compact && canvasSize.width > canvasSize.height
        let paddingCap = isIPhoneLandscape ? CalendarLayout.landscapePaddingCap : CalendarLayout.defaultPaddingCap
        let edgePadding = min((columnWidth - cellSize) / 2, paddingCap)
        let maxRow = displayDays.filter { $0.isCurrentMonth }.map { $0.row }.max() ?? 4
        let numRows = maxRow + 1
        let totalHeight = CGFloat(numRows) * cellSize + CGFloat(numRows - 1) * verticalSpacing + CalendarLayout.borderStrokeBuffer + CalendarLayout.topBuffer

        return LayoutMetrics(
            columnWidth: columnWidth,
            cellSize: cellSize,
            verticalSpacing: verticalSpacing,
            edgePadding: edgePadding,
            fontSize: cellSize * CalendarLayout.fontSizeRatio,
            topBuffer: CalendarLayout.topBuffer,
            totalHeight: totalHeight
        )
    }

    private struct LayoutMetrics {
        let columnWidth: CGFloat
        let cellSize: CGFloat
        let verticalSpacing: CGFloat
        let edgePadding: CGFloat
        let fontSize: CGFloat
        let topBuffer: CGFloat
        let totalHeight: CGFloat
    }

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.timeZone = timezone
        return formatter.string(from: currentDate)
    }

    private var isViewingCurrentMonth: Bool {
        let tz = timezone
        let currentComponents = calendar.dateComponents(in: tz, from: currentDate)
        let todayComponents = calendar.dateComponents(in: tz, from: Date())
        return currentComponents.year == todayComponents.year && currentComponents.month == todayComponents.month
    }

    /// Accessibility label summarizing the calendar grid for VoiceOver
    private var calendarAccessibilityLabel: String {
        let completedDays = displayDays.filter { $0.isCurrentMonth && $0.bgColor != .clear && monthlyData[$0.date] ?? 0 > 0 }.count
        let totalDays = displayDays.filter { $0.isCurrentMonth }.count
        return "Calendar for \(monthString). \(completedDays) of \(totalDays) days have activity recorded"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with navigation
            HStack {
                HStack(spacing: 4) {
                    Text(seasonIcon)
                        .font(.title2)
                        .accessibilityHidden(true) // Decorative season emoji
                    Text(monthString)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .accessibilityAddTraits(.isHeader)
                }
                Spacer()

                // Navigation controls
                HStack(spacing: 16) {
                    if !isViewingCurrentMonth {
                        Button {
                            currentDate = Date()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .accessibilityLabel("Return to current month")
                        .accessibilityHint("Go back to \(monthString)")
                        .accessibilityIdentifier("calendar_return_to_today")
                    }

                    Button {
                        changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Previous month")
                    .accessibilityHint("Navigate to the previous month")
                    .accessibilityIdentifier("calendar_previous_month")

                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Next month")
                    .accessibilityHint("Navigate to the next month")
                    .accessibilityIdentifier("calendar_next_month")
                }
            }

            // Weekday headers only
            HStack(spacing: 0) {
                ForEach(weekdayHeaders, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // PERFORMANCE: Use Canvas for GPU-accelerated rendering - SINGLE draw pass
            GeometryReader { geometry in
                let metrics = layout

                Canvas { context, _ in
                    for dayData in displayDays where dayData.isCurrentMonth {
                        let centerX = CGFloat(dayData.col) * metrics.columnWidth + metrics.columnWidth / 2
                        let centerY = metrics.topBuffer + CGFloat(dayData.row) * (metrics.cellSize + metrics.verticalSpacing) + metrics.cellSize / 2
                        let center = CGPoint(x: centerX, y: centerY)
                        let radius = metrics.cellSize / 2

                        let circlePath = Circle().path(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
                        context.fill(circlePath, with: .color(dayData.bgColor.opacity(dayData.opacity)))

                        if dayData.hasBorder {
                            context.stroke(circlePath, with: .color(AppColors.brand), lineWidth: 2)
                        }

                        let text = Text("\(dayData.dayNumber)")
                            .font(.system(size: metrics.fontSize, weight: .medium))
                            .foregroundColor(dayData.textColor.opacity(dayData.opacity))
                        context.draw(text, at: center, anchor: .center)
                    }
                }
                .frame(height: metrics.totalHeight)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    handleTap(at: location)
                }
                .onAppear { canvasSize = geometry.size }
                .onChange(of: geometry.size) { _, newSize in canvasSize = newSize }
            }
            .frame(minHeight: layout.totalHeight + layout.edgePadding)
            // Accessibility: Provide summary for VoiceOver users
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(calendarAccessibilityLabel)
            .accessibilityHint("Double-tap to select a date")
            .accessibilityIdentifier("monthly_calendar_grid")

            // Only add spacer on iPad for equal-height matching in side-by-side layout
            if horizontalSizeClass == .regular {
                Spacer(minLength: 0)
            }
        }
        .onAppear {
            computeDisplayDays()
        }
        .onChange(of: currentDate) { _, _ in
            computeDisplayDays()
        }
        .onChange(of: monthlyData) { _, _ in
            computeDisplayDays()
        }
        .onChange(of: timezone.identifier) { _, _ in
            // Recompute display days when timezone changes
            // This ensures "today" highlighting is correct after timezone change
            // Note: Using timezone.identifier (String) for reliable SwiftUI change detection
            computeDisplayDays()
        }
        // Force view identity change when timezone changes to reset @State
        .id(timezone.identifier)
    }

    private var seasonIcon: String {
        let month = calendar.dateComponents(in: timezone, from: currentDate).month ?? 1
        switch month {
        case 12, 1, 2: return "❄️"
        case 3, 4, 5: return "🌸"
        case 6, 7, 8: return "☀️"
        default: return "🍂"
        }
    }

    private var weekdayHeaders: [String] {
        DateUtils.orderedWeekdaySymbols(style: .veryShort)
    }

    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentDate) {
            currentDate = newDate
        }
    }

    private func getMonthDays(for date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end - 1)
        else { return [] }

        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        return DateUtils.generateDates(inside: dateInterval, matching: DateComponents(hour: 0, minute: 0, second: 0), calendar: calendar)
    }

    // PERFORMANCE: Compute ALL display properties ONCE when month changes
    private func computeDisplayDays() {
        let days = getMonthDays(for: currentDate)
        let currentMonth = calendar.dateComponents(in: timezone, from: currentDate).month ?? 1
        let today = Date()

        displayDays = days.enumerated().map { index, date in
            let dayNumber = calendar.dateComponents(in: timezone, from: date).day ?? 1
            let normalizedDate = CalendarUtils.startOfDayLocal(for: date, timezone: timezone)
            let completion = monthlyData[normalizedDate] ?? 0.0

            // Use ViewLogic for all display calculations
            let context = MonthlyCalendarViewLogic.DayContext(
                date: date,
                completion: completion,
                today: today,
                currentMonth: currentMonth,
                calendar: calendar
            )

            return DayDisplayData(
                id: normalizedDate.timeIntervalSince1970.description,
                date: date,
                dayNumber: dayNumber,
                bgColor: MonthlyCalendarViewLogic.backgroundColor(for: context),
                textColor: MonthlyCalendarViewLogic.textColor(for: context),
                hasBorder: MonthlyCalendarViewLogic.shouldShowBorder(for: context),
                opacity: MonthlyCalendarViewLogic.opacity(for: context),
                isCurrentMonth: context.isCurrentMonth,
                row: index / 7,
                col: index % 7
            )
        }
    }

    private func handleTap(at location: CGPoint) {
        let metrics = layout
        let col = Int(location.x / metrics.columnWidth)
        let row = Int((location.y - metrics.topBuffer) / (metrics.cellSize + metrics.verticalSpacing))

        if let dayData = displayDays.first(where: { $0.row == row && $0.col == col && $0.isCurrentMonth }) {
            onDateSelect(dayData.date)
        }
    }
}

#Preview {
    let sampleData: [Date: Double] = {
        var data: [Date: Double] = [:]
        for index in 1...30 {
            let date = CalendarUtils.addDaysLocal(-index, to: Date(), timezone: .current)
            data[CalendarUtils.startOfDayLocal(for: date, timezone: .current)] = Double.random(in: 0...1)
        }
        return data
    }()

    MonthlyCalendarCard(
        monthlyData: sampleData,
        onDateSelect: { _ in },
        timezone: .current
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
