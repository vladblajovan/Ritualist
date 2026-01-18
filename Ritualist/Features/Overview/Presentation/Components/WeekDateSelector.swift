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

    @Environment(\.colorScheme) var colorScheme
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
        HapticFeedbackService.shared.trigger(.light)
    }

    /// Whether the currently visible week contains today
    /// Used to show "Return to Today" button when user swipes to a different week
    private var isCurrentWeekContainingToday: Bool {
        guard !weeks.isEmpty, currentWeekIndex < weeks.count else { return false }
        let currentWeek = weeks[currentWeekIndex]
        return currentWeek.contains { CalendarUtils.isTodayLocal($0, timezone: timezone) }
    }

    /// Whether to show the "Return to Today" button
    /// Show when: viewing a different week OR selected date is not today
    private var shouldShowReturnToToday: Bool {
        !isCurrentWeekContainingToday || !isViewingToday
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
            HStack(spacing: 4) {
                if isViewingToday {
                    Text("Today,")
                        .font(CardDesign.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                Text(dayName(for: selectedDate))
                    .font(CardDesign.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(monthAndDate(for: selectedDate))
                    .font(CardDesign.title3)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(fullDateAccessibilityLabel)
            Spacer()
            returnToTodayButton
        }
    }

    private var returnToTodayButton: some View {
        Button {
            HapticFeedbackService.shared.trigger(.light)
            let todayIndex = weekIndexForDate(Date())
            if currentWeekIndex != todayIndex {
                currentWeekIndex = todayIndex
            }
            onGoToToday()
        } label: {
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
        .opacity(shouldShowReturnToToday ? 1 : 0)
        .disabled(!shouldShowReturnToToday)
        .accessibilityLabel("Return to today")
        .accessibilityHidden(!shouldShowReturnToToday)
        .accessibilityIdentifier(AccessibilityID.Overview.todayButton)
    }

    // MARK: - Week Picker

    private var weekPicker: some View {
        TabView(selection: $currentWeekIndex) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                weekRow(for: week)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 85)
        .padding(.horizontal, -Spacing.large)
        .onChange(of: currentWeekIndex) { _, _ in
            HapticFeedbackService.shared.trigger(.selection)
        }
    }

    // MARK: - Week Row & Day Column

    private func weekRow(for week: [Date]) -> some View {
        HStack(spacing: 0) {
            ForEach(week, id: \.self) { date in
                dayColumn(for: date)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
    }

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
                Circle()
                    .fill(isDateToday ? AppColors.brand : Color.clear)
                    .frame(width: 5, height: 5)
                Text(dayAbbreviation(for: date))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(dayAbbreviationColor(isSelected: isSelected, isFuture: isFutureDate))
                dayCircleIndicator(
                    isSelected: isSelected,
                    isDateToday: isDateToday,
                    isFutureDate: isFutureDate,
                    completion: completion,
                    date: date
                )
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

    @ViewBuilder
    private func dayCircleIndicator(
        isSelected: Bool,
        isDateToday: Bool,
        isFutureDate: Bool,
        completion: Double,
        date: Date
    ) -> some View {
        ZStack {
            if isFutureDate {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 36)
            } else {
                Circle()
                    .fill(dayCircleColor(completion: completion))
                    .frame(width: 36, height: 36)
                if isSelected {
                    Circle()
                        .stroke(AppColors.brand, lineWidth: 1.5)
                        .frame(width: 36, height: 36)
                }
            }
            Text(dateNumber(for: date))
                .font(.system(size: 16, weight: isSelected || isDateToday ? .semibold : .regular, design: .rounded))
                .foregroundColor(dateNumberColor(isSelected: isSelected, isToday: isDateToday, isFuture: isFutureDate, completion: completion))
        }
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
