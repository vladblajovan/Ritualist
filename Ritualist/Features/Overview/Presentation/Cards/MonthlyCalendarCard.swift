import SwiftUI
import Foundation
import RitualistCore

// Type aliases for cleaner code
private typealias LayoutConstants = MonthlyCalendarViewLogic.LayoutConstants
private typealias LayoutMetrics = MonthlyCalendarViewLogic.LayoutMetrics
private typealias LayoutContext = MonthlyCalendarViewLogic.LayoutContext

// MARK: - Day Display Data

/// Pre-computed day data - ALL properties calculated ONCE when month changes
private struct DayDisplayData: Identifiable {
    let id: String
    let date: Date
    let dayNumber: Int
    let bgColor: Color
    let textColor: Color
    let isToday: Bool
    let isSelected: Bool
    let opacity: Double
    let isCurrentMonth: Bool
    let isFuture: Bool
    let row: Int
    let col: Int
}

// PERFORMANCE: Complete rewrite using Canvas for MAXIMUM performance
struct MonthlyCalendarCard: View {
    let monthlyData: [Date: Double]
    let onDateSelect: (Date) -> Void
    /// The timezone used for all date calculations. Should match the timezone used to generate monthlyData keys.
    let timezone: TimeZone
    /// The currently selected/viewing date (shown in TodaysSummary). Highlighted with blue border.
    var selectedDate: Date?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var currentDate = Date()
    @State private var displayDays: [DayDisplayData] = []
    /// Maximum row index for current month days, cached to avoid repeated filtering in layout
    @State private var maxRowIndex: Int = 4
    /// Stored canvas geometry for layout calculations.
    /// Updated via onChange(of: geometry.size) to ensure layout and tap detection stay synchronized.
    /// Note: During rapid orientation changes, there may be a brief moment where canvasSize
    /// is updating. SwiftUI's animation system naturally debounces these transitions.
    @State private var canvasSize: CGSize = .zero

    /// Minimum height for the calendar grid, calculated independently of GeometryReader.
    /// This ensures proper sizing in EqualHeightRow on iPad where intrinsic size is needed.
    private var minimumGridHeight: CGFloat {
        let rowCount = maxRowIndex + 1
        let cellSize = horizontalSizeClass == .compact
            ? LayoutConstants.maxCellSizeCompact
            : LayoutConstants.maxCellSizeRegular
        let spacing = min(cellSize * LayoutConstants.verticalSpacingRatio, LayoutConstants.maxVerticalSpacing)
        let buffer = LayoutConstants.borderBuffer
        return buffer + CGFloat(rowCount) * cellSize + CGFloat(rowCount - 1) * spacing + buffer
    }

    private var calendar: Calendar {
        CalendarUtils.localCalendar(for: timezone)
    }

    /// Computes all layout metrics from the stored canvas size.
    /// Delegates to MonthlyCalendarViewLogic for testability.
    /// On iPad, passes available height for dynamic sizing to fill EqualHeightRow.
    private var layout: LayoutMetrics {
        let isCompact = horizontalSizeClass == .compact
        let context = LayoutContext(
            canvasSize: canvasSize,
            maxRowIndex: maxRowIndex,
            isCompactWidth: isCompact,
            availableHeight: isCompact ? nil : canvasSize.height
        )
        return MonthlyCalendarViewLogic.computeLayout(for: context)
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
                        .font(CardDesign.title2)
                        .accessibilityHidden(true) // Decorative season emoji
                    Text(monthString)
                        .font(CardDesign.headline)
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
                        .font(CardDesign.caption)
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
                        // Use symmetric borderBuffer for consistent top/bottom spacing
                        let centerY = metrics.borderBuffer + CGFloat(dayData.row) * (metrics.cellSize + metrics.verticalSpacing) + metrics.cellSize / 2
                        let center = CGPoint(x: centerX, y: centerY)
                        let radius = metrics.cellSize / 2

                        let circlePath = Circle().path(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))

                        // Fill the day circle
                        context.fill(circlePath, with: .color(dayData.bgColor.opacity(dayData.opacity)))

                        // Selected date gets blue border (matches WeekDateSelector stroke width)
                        if dayData.isSelected {
                            context.stroke(circlePath, with: .color(AppColors.brand), lineWidth: 1.5)
                        }

                        // Today uses bold font to differentiate
                        let fontWeight: Font.Weight = dayData.isToday ? .bold : .medium
                        let text = Text("\(dayData.dayNumber)")
                            .font(.system(size: metrics.fontSize, weight: fontWeight))
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
            .frame(minHeight: horizontalSizeClass == .regular ? minimumGridHeight : layout.totalHeight)
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
        .onChange(of: selectedDate) { _, _ in
            // Recompute display days when selected date changes
            // This updates the blue highlight ring on the selected date
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

        // Normalize selectedDate for comparison
        let normalizedSelectedDate: Date? = selectedDate.map {
            CalendarUtils.startOfDayLocal(for: $0, timezone: timezone)
        }

        var computedMaxRow = 0
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

            let row = index / 7
            if context.isCurrentMonth {
                computedMaxRow = max(computedMaxRow, row)
            }

            // Check if this date is the selected/viewing date
            let isSelected = normalizedSelectedDate == normalizedDate

            return DayDisplayData(
                id: normalizedDate.timeIntervalSince1970.description,
                date: date,
                dayNumber: dayNumber,
                bgColor: MonthlyCalendarViewLogic.backgroundColor(for: context),
                textColor: MonthlyCalendarViewLogic.textColor(for: context),
                isToday: context.isToday,
                isSelected: isSelected,
                opacity: MonthlyCalendarViewLogic.opacity(for: context),
                isCurrentMonth: context.isCurrentMonth,
                isFuture: context.isFuture,
                row: row,
                col: index % 7
            )
        }
        maxRowIndex = computedMaxRow
    }

    /// Handles tap gestures on the calendar grid.
    /// Delegates grid position calculation to MonthlyCalendarViewLogic for testability.
    ///
    /// - Parameter location: The tap location in Canvas coordinate space
    private func handleTap(at location: CGPoint) {
        // Guard against invalid state during rapid orientation changes
        guard canvasSize.width > 0, canvasSize.height > 0 else { return }

        let metrics = layout

        // Use extracted logic for grid position calculation (includes bounds validation)
        guard let position = MonthlyCalendarViewLogic.gridPosition(
            for: location,
            metrics: metrics,
            maxRowIndex: maxRowIndex
        ) else { return }

        // Find the tapped day - must be current month and not a future date
        if let dayData = displayDays.first(where: { $0.row == position.row && $0.col == position.col && $0.isCurrentMonth && !$0.isFuture }) {
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
        timezone: .current,
        selectedDate: Date()
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
