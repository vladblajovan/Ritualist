//
//  WeekDateSelector+Helpers.swift
//  Ritualist
//
//  Helper methods for WeekDateSelector date formatting and color calculations.
//

import SwiftUI
import RitualistCore

// MARK: - Helper Methods

extension WeekDateSelector {

    // MARK: - Data Helpers

    func completionForDate(_ date: Date) -> Double {
        weeklyData[CalendarUtils.startOfDayLocal(for: date, timezone: timezone)] ?? 0.0
    }

    func isFuture(_ date: Date) -> Bool {
        let dateStart = CalendarUtils.startOfDayLocal(for: date, timezone: timezone)
        let todayStart = CalendarUtils.startOfDayLocal(for: Date(), timezone: timezone)
        return dateStart > todayStart
    }

    func canSelectDate(_ date: Date) -> Bool {
        if CalendarUtils.isTodayLocal(date, timezone: timezone) {
            return true
        }
        return !isFuture(date) && canGoToPrevious
    }

    // MARK: - Color Helpers

    func dayCircleColor(completion: Double) -> Color {
        CardDesign.progressColor(for: completion, noProgressColor: Color(.systemGray5))
    }

    func dayAbbreviationColor(isSelected: Bool, isFuture: Bool) -> Color {
        if isSelected {
            return AppColors.brand
        }
        return isFuture ? Color(.systemGray3) : .secondary
    }

    func dateNumberColor(isSelected: Bool, isToday: Bool, isFuture: Bool, completion: Double) -> Color {
        if isFuture {
            return Color(.systemGray2)
        }
        if completion > 0 {
            return .white
        }
        if isToday {
            return AppColors.brand
        }
        return .primary
    }

    func dayBackgroundColor(isSelected: Bool, isFuture: Bool) -> Color {
        let base = colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)
        if isSelected {
            return AppColors.brand.opacity(colorScheme == .dark ? 0.25 : 0.12)
        }
        return isFuture ? base.opacity(0.6) : base
    }

    // MARK: - Formatting Helpers

    func dayName(for date: Date) -> String {
        CalendarUtils.formatDayAbbreviation(date, timezone: timezone)
    }

    func monthAndDate(for date: Date) -> String {
        CalendarUtils.formatMonthAndDay(date, timezone: timezone)
    }

    func dayAbbreviation(for date: Date) -> String {
        CalendarUtils.formatDayAbbreviation(date, timezone: timezone)
    }

    func dateNumber(for date: Date) -> String {
        CalendarUtils.formatDayNumber(date, timezone: timezone)
    }

    var fullDateAccessibilityLabel: String {
        CalendarUtils.formatForDisplay(selectedDate, style: .full, timezone: timezone)
    }

    func accessibilityLabel(for date: Date, isSelected: Bool, isToday: Bool, isFuture: Bool) -> String {
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
