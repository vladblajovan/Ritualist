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

    /// Number of weeks to show on each side of the current week
    private let weeksBuffer = 4

    @State private var currentWeekIndex: Int
    @State private var weeks: [[Date]] = []

    private let calendar = Calendar.current

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

        // Initialize at center of weeks array
        self._currentWeekIndex = State(initialValue: 4) // weeksBuffer
    }

    // MARK: - Week Calculations

    /// Get the start of the week for a given date
    private func startOfWeek(for date: Date) -> Date {
        var cal = calendar
        cal.timeZone = timezone
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: components) ?? date
    }

    /// Get all dates for the week starting at weekStart
    private func datesForWeek(startingAt weekStart: Date) -> [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    /// Generate weeks array centered around the selected date
    private func generateWeeks() -> [[Date]] {
        let currentWeekStart = startOfWeek(for: selectedDate)
        var weeksArray: [[Date]] = []

        // Generate weeks before and after current week
        for offset in -weeksBuffer...weeksBuffer {
            if let weekStart = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart) {
                weeksArray.append(datesForWeek(startingAt: weekStart))
            }
        }

        return weeksArray
    }

    /// Check if two dates are the same day
    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        var cal = calendar
        cal.timeZone = timezone
        return cal.isDate(date1, inSameDayAs: date2)
    }

    /// Check if date is today
    private func isToday(_ date: Date) -> Bool {
        var cal = calendar
        cal.timeZone = timezone
        return cal.isDateInToday(date)
    }

    /// Find which week index contains the selected date
    private func weekIndexForDate(_ date: Date) -> Int {
        for (index, week) in weeks.enumerated() where week.contains(where: { isSameDay($0, date) }) {
            return index
        }
        return weeksBuffer
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
            // Regenerate weeks if we've scrolled far from center
            let newIndex = weekIndexForDate(newDate)
            if newIndex != currentWeekIndex {
                // Check if we need to regenerate (approaching edges)
                if newIndex <= 1 || newIndex >= weeks.count - 2 {
                    weeks = generateWeeks()
                    currentWeekIndex = weeksBuffer
                } else {
                    currentWeekIndex = newIndex
                }
            }
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack {
            // Left side: Date display
            HStack(spacing: 4) {
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
        .frame(height: 70)
    }

    // MARK: - Week Row

    private func weekRow(for week: [Date]) -> some View {
        HStack(spacing: 0) {
            ForEach(week, id: \.self) { date in
                dayColumn(for: date)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Day Column

    private func dayColumn(for date: Date) -> some View {
        let isSelected = isSameDay(date, selectedDate)
        let isDateToday = isToday(date)
        let canSelect = canSelectDate(date)
        let isFutureDate = isFuture(date)
        let completion = completionForDate(date)

        return Button {
            if canSelect {
                onDateSelected(date)
            }
        } label: {
            VStack(spacing: 6) {
                // Day abbreviation
                Text(dayAbbreviation(for: date))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(dayAbbreviationColor(isSelected: isSelected, isFuture: isFutureDate))
                    .textCase(.uppercase)

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
                            .fill(dayCircleColor(completion: completion, isToday: isDateToday))
                            .frame(width: 36, height: 36)

                        // Selected state: add brand stroke to indicate selection
                        if isSelected {
                            Circle()
                                .stroke(AppColors.brand, lineWidth: 1.5)
                                .frame(width: 36, height: 36)
                        }
                        // Today (not selected) gets brand stroke ONLY when no completion data
                        else if isDateToday && completion == 0 {
                            Circle()
                                .stroke(AppColors.brand.opacity(0.5), lineWidth: 1.5)
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
                RoundedRectangle(cornerRadius: 10)
                    .fill(dayBackgroundColor(isSelected: isSelected, isFuture: isFutureDate))
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
        var cal = calendar
        cal.timeZone = timezone
        let normalizedDate = cal.startOfDay(for: date)
        return weeklyData[normalizedDate] ?? 0.0
    }

    /// Day circle color based on completion - matches MonthlyCalendarCard colors
    private func dayCircleColor(completion: Double, isToday: Bool) -> Color {
        // Same logic as MonthlyCalendarViewLogic.backgroundColor
        if completion >= 1.0 {
            return CardDesign.progressGreen
        } else if completion >= 0.8 {
            return CardDesign.progressGreen
        } else if completion >= 0.5 {
            return CardDesign.progressOrange
        } else if completion > 0 {
            return CardDesign.progressRed.opacity(0.6)
        } else {
            // No completion data: use subtle grey
            return Color(.systemGray5)
        }
    }

    /// Check if date is in the future relative to today
    private func isFuture(_ date: Date) -> Bool {
        var cal = calendar
        cal.timeZone = timezone
        let today = cal.startOfDay(for: Date())
        let targetDay = cal.startOfDay(for: date)
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
    private func dayBackgroundColor(isSelected: Bool, isFuture: Bool) -> Color {
        if isSelected {
            return AppColors.brand.opacity(0.12)  // Selected: brand highlight
        } else if isFuture {
            return Color(.systemGray6).opacity(0.6)  // Inactive: faded, less prominent
        } else {
            return Color(.systemGray6)  // Active/tappable: full opacity, more visible
        }
    }

    // MARK: - Helper Methods

    /// Check if a date can be selected based on navigation constraints
    /// - Future dates (relative to TODAY): Never selectable - can't log habits for future
    /// - Past dates (relative to TODAY): Controlled by canGoToPrevious (business rule about history limit)
    /// - Today: Always selectable
    private func canSelectDate(_ date: Date) -> Bool {
        var cal = calendar
        cal.timeZone = timezone
        let today = cal.startOfDay(for: Date())
        let targetDay = cal.startOfDay(for: date)

        // Can always select today
        if cal.isDate(date, inSameDayAs: Date()) {
            return true
        }

        // Future dates are NEVER selectable - you can't log habits for tomorrow
        // Note: canGoToNext from parent is for navigation (viewing), not logging
        if targetDay > today {
            return false
        }

        // Past dates are selectable based on business rules (e.g., how far back history goes)
        if targetDay < today {
            return canGoToPrevious
        }

        return true
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

    // MARK: - Date Formatting

    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.dateFormat = "EEE" // Short day name: "Sat"
        return formatter.string(from: date)
    }

    private func monthAndDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.dateFormat = "MMM d" // Month and date: "Dec 20"
        return formatter.string(from: date)
    }

    private func dayAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.dateFormat = "EEE" // "Sun", "Mon", etc.
        return formatter.string(from: date)
    }

    private func dateNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.dateFormat = "d" // Just the day number
        return formatter.string(from: date)
    }

    // MARK: - Accessibility

    private var fullDateAccessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }

    private func accessibilityLabel(for date: Date, isSelected: Bool, isToday: Bool, isFuture: Bool) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.dateStyle = .full
        var label = formatter.string(from: date)

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
            selectedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
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
