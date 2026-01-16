//
//  WeekDateSelector.swift
//  Ritualist
//
//  A swipeable week date selector component with animated horizontal scrolling.
//

import SwiftUI
import RitualistCore

/// A horizontal week selector with animated swipe navigation
/// Shows abbreviated day names with date numbers below
/// Day circles show completion status using the same colors as MonthlyCalendarCard
struct WeekDateSelector: View {
    let selectedDate: Date
    let timezone: TimeZone
    let canGoToPrevious: Bool
    let canGoToNext: Bool
    let isViewingToday: Bool
    /// Daily completion data for showing progress colors on day circles
    /// Keys should be normalized to start of day in the display timezone
    let weeklyData: [Date: Double]
    let onDateSelected: (Date) -> Void
    let onGoToToday: () -> Void

    // MARK: - Layout Constants

    /// Number of weeks to show on each side of the current week.
    /// 4 weeks provides smooth scrolling in both directions while keeping memory usage low.
    /// Total weeks in memory: (4 * 2) + 1 = 9 weeks = 63 Date objects (~5KB).
    /// Weeks regenerate when user approaches edges, so this is effectively unlimited scrolling.
    private static let weeksBuffer = 4

    @Environment(\.colorScheme) private var colorScheme
    @State private var currentWeekIndex: Int
    @State private var weeks: [[Date]] = []
    @State private var lastRegenerationTime: Date = .distantPast

    /// Minimum interval between week array regenerations (100ms)
    /// Prevents excessive regenerations during rapid programmatic date changes
    private static let regenerationDebounceInterval: TimeInterval = 0.1

    init(
        selectedDate: Date,
        timezone: TimeZone,
        canGoToPrevious: Bool,
        canGoToNext: Bool,
        isViewingToday: Bool,
        weeklyData: [Date: Double] = [:],
        onDateSelected: @escaping (Date) -> Void,
        onGoToToday: @escaping () -> Void
    ) {
        self.selectedDate = selectedDate
        self.timezone = timezone
        self.canGoToPrevious = canGoToPrevious
        self.canGoToNext = canGoToNext
        self.isViewingToday = isViewingToday
        self.weeklyData = weeklyData
        self.onDateSelected = onDateSelected
        self.onGoToToday = onGoToToday

        // Initialize at center of weeks array (weeksBuffer index)
        self._currentWeekIndex = State(initialValue: Self.weeksBuffer)
    }

    // MARK: - Week Calculations (using CalendarUtils)

    /// Get all dates for the week starting at weekStart
    private func datesForWeek(startingAt weekStart: Date) -> [Date] {
        (0..<7).compactMap { CalendarUtils.addDaysLocal($0, to: weekStart, timezone: timezone) }
    }

    /// Generate weeks array centered around the selected date
    private func generateWeeks() -> [[Date]] {
        let currentWeekStart = CalendarUtils.startOfWeekLocal(for: selectedDate, timezone: timezone)
        var weeksArray: [[Date]] = []

        // Generate weeks before and after current week
        for offset in -Self.weeksBuffer...Self.weeksBuffer {
            let weekStart = CalendarUtils.addWeeksLocal(offset, to: currentWeekStart, timezone: timezone)
            weeksArray.append(datesForWeek(startingAt: weekStart))
        }

        return weeksArray
    }

    /// Trigger haptic feedback for date selection
    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Find which week index contains the selected date
    /// Returns a bounds-safe index (clamped to valid array range)
    private func weekIndexForDate(_ date: Date) -> Int {
        for (index, week) in weeks.enumerated() where week.contains(where: { CalendarUtils.areSameDayLocal($0, date, timezone: timezone) }) {
            return index
        }
        // Fallback to center, clamped to valid bounds
        let fallback = Self.weeksBuffer
        return weeks.isEmpty ? 0 : min(fallback, weeks.count - 1)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Header with formatted date and return to today
            dateHeader

            // Animated week picker
            weekPicker
        }
        .onAppear {
            weeks = generateWeeks()
            currentWeekIndex = weekIndexForDate(selectedDate)
        }
        .onChange(of: selectedDate) { _, newDate in
            // Regenerate weeks when approaching edges to enable infinite scrolling.
            // Performance note: Regeneration creates 9 weeks (63 Date objects, ~5KB).
            // Debouncing prevents excessive regenerations during rapid programmatic date changes.
            let newIndex = weekIndexForDate(newDate)
            if newIndex != currentWeekIndex {
                // Check if we need to regenerate (within 2 weeks of either edge)
                if newIndex <= 1 || newIndex >= weeks.count - 2 {
                    // Debounce regeneration to prevent excessive allocations
                    let now = Date()
                    if now.timeIntervalSince(lastRegenerationTime) >= Self.regenerationDebounceInterval {
                        weeks = generateWeeks()
                        lastRegenerationTime = now
                        // Recalculate index after regeneration to avoid mismatch
                        currentWeekIndex = weekIndexForDate(newDate)
                    } else {
                        // Skip regeneration but still update index if valid (bounds-safe)
                        currentWeekIndex = min(max(newIndex, 0), weeks.count - 1)
                    }
                } else {
                    // Not at edge, safe to update index (bounds-safe for defensive coding)
                    currentWeekIndex = min(max(newIndex, 0), weeks.count - 1)
                }
            }
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack {
            // Left side: Date display
            HStack(spacing: 4) {
                // "Today, " prefix when viewing today
                if isViewingToday {
                    Text("Today,")
                        .font(CardDesign.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }

                // Day name (bold, primary)
                Text(dayName(for: selectedDate))
                    .font(CardDesign.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                // Month and date (secondary)
                Text(monthAndDate(for: selectedDate))
                    .font(CardDesign.title3)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(fullDateAccessibilityLabel)

            Spacer()

            // Right side: Return to Today button
            // Always rendered to prevent layout jump, but hidden when viewing today
            Button(action: onGoToToday) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                    Text("Today")
                        .font(CardDesign.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(AppColors.brand)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppColors.brand.opacity(0.12))
                .cornerRadius(CardDesign.innerCornerRadius)
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(isViewingToday ? 0 : 1)
            .disabled(isViewingToday)
            .accessibilityLabel("Return to today")
            .accessibilityHidden(isViewingToday)
            .accessibilityIdentifier(AccessibilityID.Overview.todayButton)
        }
    }

    // MARK: - Week Picker with Animation

    private var weekPicker: some View {
        TabView(selection: $currentWeekIndex) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                weekRow(for: week)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 85) // Increased to accommodate today dot
        .padding(.horizontal, -Spacing.large) // Negative padding for full width
    }

    // MARK: - Week Row

    private func weekRow(for week: [Date]) -> some View {
        HStack(spacing: 0) {
            ForEach(week, id: \.self) { date in
                dayColumn(for: date)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Day Column

    private func dayColumn(for date: Date) -> some View {
        let isSelected = CalendarUtils.areSameDayLocal(date, selectedDate, timezone: timezone)
        let isDateToday = CalendarUtils.isTodayLocal(date, timezone: timezone)
        let canSelect = canSelectDate(date)
        let isFutureDate = isFuture(date)
        let completion = completionForDate(date)

        return Button {
            if canSelect {
                triggerHapticFeedback()
                onDateSelected(date)
            }
        } label: {
            VStack(spacing: 4) {
                // Today indicator dot
                Circle()
                    .fill(isDateToday ? AppColors.brand : Color.clear)
                    .frame(width: 5, height: 5)

                // Day abbreviation
                Text(dayAbbreviation(for: date))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(dayAbbreviationColor(isSelected: isSelected, isFuture: isFutureDate))

                // Date number with selection indicator
                ZStack {
                    // Circle indicator - ALL dates have a circle
                    if isFutureDate {
                        // Future dates: grey filled circle (inactive appearance)
                        Circle()
                            .fill(Color(.systemGray4))
                            .frame(width: 36, height: 36)
                    } else {
                        // Past dates & today: completion-based color (matches MonthlyCalendarCard)
                        Circle()
                            .fill(dayCircleColor(completion: completion))
                            .frame(width: 36, height: 36)

                        // Selected state: add brand stroke to indicate selection
                        if isSelected {
                            Circle()
                                .stroke(AppColors.brand, lineWidth: 1.5)
                                .frame(width: 36, height: 36)
                        }
                    }

                    // Date number
                    Text(dateNumber(for: date))
                        .font(.system(size: 16, weight: isSelected || isDateToday ? .semibold : .regular, design: .rounded))
                        .foregroundColor(dateNumberColor(isSelected: isSelected, isToday: isDateToday, isFuture: isFutureDate, completion: completion))
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(dayBackgroundColor(isSelected: isSelected, isFuture: isFutureDate))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(AppColors.brand.opacity(0.2), lineWidth: isSelected ? 1 : 0)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!canSelect)
        .accessibilityLabel(accessibilityLabel(for: date, isSelected: isSelected, isToday: isDateToday, isFuture: isFutureDate))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isFutureDate ? "Future date, not available" : (canSelect ? "Double tap to select" : "Not available"))
    }

    /// Get completion value for a date from weeklyData
    private func completionForDate(_ date: Date) -> Double {
        let normalizedDate = CalendarUtils.startOfDayLocal(for: date, timezone: timezone)
        return weeklyData[normalizedDate] ?? 0.0
    }

    /// Day circle color based on completion - uses CardDesign.progressColor
    private func dayCircleColor(completion: Double) -> Color {
        CardDesign.progressColor(for: completion, noProgressColor: Color(.systemGray5))
    }

    /// Check if date is in the future relative to today
    private func isFuture(_ date: Date) -> Bool {
        let today = CalendarUtils.startOfDayLocal(for: Date(), timezone: timezone)
        let targetDay = CalendarUtils.startOfDayLocal(for: date, timezone: timezone)
        return targetDay > today
    }

    /// Day abbreviation color - adapts to selection and future state
    private func dayAbbreviationColor(isSelected: Bool, isFuture: Bool) -> Color {
        if isSelected {
            return AppColors.brand
        } else if isFuture {
            return Color(.systemGray3)
        } else {
            return .secondary
        }
    }

    /// Day background color - ALL days have rounded rectangle backgrounds
    /// Active/tappable days are MORE visible than inactive future days
    /// Uses systemGray6 in light mode, systemGray5 in dark mode for optimal contrast
    private func dayBackgroundColor(isSelected: Bool, isFuture: Bool) -> Color {
        // systemGray6 is lightest in light mode but darkest in dark mode (iOS inverts)
        // So we use systemGray5 in dark mode for better visibility
        let baseGray = colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)

        if isSelected {
            // Higher opacity in dark mode for better visibility
            let selectedOpacity = colorScheme == .dark ? 0.25 : 0.12
            return AppColors.brand.opacity(selectedOpacity)
        } else if isFuture {
            return baseGray.opacity(0.6)  // Inactive: faded, less prominent
        } else {
            return baseGray  // Active/tappable: full visibility
        }
    }

    // MARK: - Helper Methods

    /// Check if a date can be selected based on navigation constraints
    /// - Future dates (relative to TODAY): Never selectable - can't log habits for future
    /// - Past dates (relative to TODAY): Controlled by canGoToPrevious (business rule about history limit)
    /// - Today: Always selectable
    private func canSelectDate(_ date: Date) -> Bool {
        let today = CalendarUtils.startOfDayLocal(for: Date(), timezone: timezone)
        let targetDay = CalendarUtils.startOfDayLocal(for: date, timezone: timezone)

        // Can always select today
        if CalendarUtils.isTodayLocal(date, timezone: timezone) {
            return true
        }

        // Future dates are NEVER selectable - you can't log habits for tomorrow
        if targetDay > today {
            return false
        }

        // Past dates are selectable based on business rules (e.g., how far back history goes)
        return canGoToPrevious
    }

    /// Date number color - ensures WCAG contrast in light/dark modes
    /// For completion-colored circles, uses white text for better contrast
    private func dateNumberColor(isSelected: Bool, isToday: Bool, isFuture: Bool, completion: Double) -> Color {
        if isFuture {
            // Darker grey for contrast on grey circle background
            return Color(.systemGray2)
        } else if completion > 0 {
            // Has completion data: white text on colored background
            return .white
        } else if isToday {
            // Today without completion: brand color on grey background
            return AppColors.brand
        } else {
            // Past dates without completion: primary adapts to light/dark mode
            return .primary
        }
    }

    // MARK: - Date Formatting (using CalendarUtils)

    private func dayName(for date: Date) -> String {
        CalendarUtils.formatDayAbbreviation(date, timezone: timezone)
    }

    private func monthAndDate(for date: Date) -> String {
        CalendarUtils.formatMonthAndDay(date, timezone: timezone)
    }

    private func dayAbbreviation(for date: Date) -> String {
        CalendarUtils.formatDayAbbreviation(date, timezone: timezone)
    }

    private func dateNumber(for date: Date) -> String {
        CalendarUtils.formatDayNumber(date, timezone: timezone)
    }

    // MARK: - Accessibility

    private var fullDateAccessibilityLabel: String {
        CalendarUtils.formatForDisplay(selectedDate, style: .full, timezone: timezone)
    }

    private func accessibilityLabel(for date: Date, isSelected: Bool, isToday: Bool, isFuture: Bool) -> String {
        var label = CalendarUtils.formatForDisplay(date, style: .full, timezone: timezone)

        if isToday {
            label += ", today"
        }
        if isSelected {
            label += ", selected"
        }
        if isFuture {
            label += ", future date, not available for logging"
        }

        return label
    }
}

// MARK: - Preview

#Preview {
    // Generate sample weekly completion data
    let sampleWeeklyData: [Date: Double] = {
        var data: [Date: Double] = [:]
        let calendar = Calendar.current
        // Past days with varying completion
        for dayOffset in -7 ... -1 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) {
                let normalized = calendar.startOfDay(for: date)
                // Vary completion: full, high, medium, low, none
                switch dayOffset {
                case -1: data[normalized] = 1.0   // Yesterday: 100%
                case -2: data[normalized] = 0.85  // 2 days ago: 85%
                case -3: data[normalized] = 0.6   // 3 days ago: 60%
                case -4: data[normalized] = 0.3   // 4 days ago: 30%
                case -5: data[normalized] = 0.0   // 5 days ago: 0%
                case -6: data[normalized] = 1.0   // 6 days ago: 100%
                case -7: data[normalized] = 0.9   // 7 days ago: 90%
                default: data[normalized] = 0.5
                }
            }
        }
        return data
    }()

    VStack(spacing: 32) {
        // Today selected with completion colors
        WeekDateSelector(
            selectedDate: Date(),
            timezone: .current,
            canGoToPrevious: true,
            canGoToNext: true,
            isViewingToday: true,
            weeklyData: sampleWeeklyData,
            onDateSelected: { _ in },
            onGoToToday: {}
        )
        .padding()
        .background(CardDesign.cardBackground)
        .cornerRadius(CardDesign.cornerRadius)

        // Past date selected (shows Return to Today + completion colors)
        WeekDateSelector(
            selectedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            timezone: .current,
            canGoToPrevious: true,
            canGoToNext: true,
            isViewingToday: false,
            weeklyData: sampleWeeklyData,
            onDateSelected: { _ in },
            onGoToToday: {}
        )
        .padding()
        .background(CardDesign.cardBackground)
        .cornerRadius(CardDesign.cornerRadius)
    }
    .padding()
}
