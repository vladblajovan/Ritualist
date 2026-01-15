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
struct WeekDateSelector: View {
    let selectedDate: Date
    let timezone: TimeZone
    let canGoToPrevious: Bool
    let canGoToNext: Bool
    let isViewingToday: Bool
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
        onDateSelected: @escaping (Date) -> Void,
        onGoToToday: @escaping () -> Void
    ) {
        self.selectedDate = selectedDate
        self.timezone = timezone
        self.canGoToPrevious = canGoToPrevious
        self.canGoToNext = canGoToNext
        self.isViewingToday = isViewingToday
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
        for (index, week) in weeks.enumerated() {
            if week.contains(where: { isSameDay($0, date) }) {
                return index
            }
        }
        return weeksBuffer // Default to center
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

            // Right side: Return to Today button (only when not viewing today)
            if !isViewingToday {
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
                .accessibilityLabel("Return to today")
                .accessibilityIdentifier(AccessibilityID.Overview.todayButton)
            }
        }
    }

    // MARK: - Week Picker with Animation

    private var weekPicker: some View {
        HStack(spacing: 0) {
            // Left chevron hint
            Image(systemName: "chevron.left")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary.opacity(0.4))
                .frame(width: 16)

            // Week TabView
            TabView(selection: $currentWeekIndex) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                    weekRow(for: week)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 70)

            // Right chevron hint
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary.opacity(0.4))
                .frame(width: 16)
        }
    }

    // MARK: - Week Row

    private func weekRow(for week: [Date]) -> some View {
        HStack(spacing: 0) {
            ForEach(week, id: \.self) { date in
                dayColumn(for: date)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Day Column

    private func dayColumn(for date: Date) -> some View {
        let isSelected = isSameDay(date, selectedDate)
        let isDateToday = isToday(date)
        let canSelect = canSelectDate(date)

        return Button {
            if canSelect {
                onDateSelected(date)
            }
        } label: {
            VStack(spacing: 6) {
                // Day abbreviation
                Text(dayAbbreviation(for: date))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? AppColors.brand : .secondary)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                // Date number with selection indicator
                ZStack {
                    // Selection circle
                    if isSelected {
                        Circle()
                            .fill(AppColors.brand)
                            .frame(width: 36, height: 36)
                    } else if isDateToday {
                        // Today indicator (subtle circle when not selected)
                        Circle()
                            .stroke(AppColors.brand.opacity(0.5), lineWidth: 1.5)
                            .frame(width: 36, height: 36)
                    }

                    // Date number
                    Text(dateNumber(for: date))
                        .font(.system(size: 16, weight: isSelected || isDateToday ? .semibold : .regular, design: .rounded))
                        .foregroundColor(dateNumberColor(isSelected: isSelected, isToday: isDateToday, canSelect: canSelect))
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? AppColors.brand.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(canSelect ? 1.0 : 0.4)
        .accessibilityLabel(accessibilityLabel(for: date, isSelected: isSelected, isToday: isDateToday))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Helper Methods

    /// Check if a date can be selected based on navigation constraints
    private func canSelectDate(_ date: Date) -> Bool {
        var cal = calendar
        cal.timeZone = timezone
        let today = cal.startOfDay(for: Date())
        let targetDay = cal.startOfDay(for: date)

        // Can always select today
        if cal.isDate(date, inSameDayAs: Date()) {
            return true
        }

        // Check future dates
        if targetDay > today {
            return canGoToNext
        }

        // Check past dates
        if targetDay < today {
            return canGoToPrevious
        }

        return true
    }

    private func dateNumberColor(isSelected: Bool, isToday: Bool, canSelect: Bool) -> Color {
        if isSelected {
            return .white
        } else if isToday {
            return AppColors.brand
        } else {
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

    private func accessibilityLabel(for date: Date, isSelected: Bool, isToday: Bool) -> String {
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

        return label
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        // Today selected
        WeekDateSelector(
            selectedDate: Date(),
            timezone: .current,
            canGoToPrevious: true,
            canGoToNext: true,
            isViewingToday: true,
            onDateSelected: { _ in },
            onGoToToday: {}
        )
        .padding()
        .background(CardDesign.cardBackground)
        .cornerRadius(CardDesign.cornerRadius)

        // Different date selected (shows Return to Today)
        WeekDateSelector(
            selectedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            timezone: .current,
            canGoToPrevious: true,
            canGoToNext: true,
            isViewingToday: false,
            onDateSelected: { _ in },
            onGoToToday: {}
        )
        .padding()
        .background(CardDesign.cardBackground)
        .cornerRadius(CardDesign.cornerRadius)
    }
    .padding()
}
