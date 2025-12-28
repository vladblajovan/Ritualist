//
//  DebugMenuTimezoneDiagnosticsSection.swift
//  Ritualist
//

import SwiftUI
import RitualistCore

#if DEBUG
struct DebugMenuTimezoneDiagnosticsSection: View {
    @Bindable var vm: SettingsViewModel

    var body: some View {
        Section("Timezone Diagnostics") {
            VStack(alignment: .leading, spacing: 12) {
                deviceTimezoneInfo
                Divider()
                currentDateTimeInfo
                Divider()
                dayBoundariesInfo
                Divider()
                weekdayInfo
                Divider()
                displaySettingsInfo
            }
            .padding(.vertical, 4)

            Text("Use this information to diagnose timezone-related issues with habit schedules and logging.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var deviceTimezoneInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Device Timezone")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Identifier:")
                    Spacer()
                    Text(TimeZone.current.identifier)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }

                HStack {
                    Text("Abbreviation:")
                    Spacer()
                    Text(TimeZone.current.abbreviation() ?? "N/A")
                        .fontWeight(.medium)
                }

                HStack {
                    Text("UTC Offset:")
                    Spacer()
                    Text(formatUTCOffset(TimeZone.current.secondsFromGMT()))
                        .fontWeight(.medium)
                }
            }
            .font(.subheadline)
        }
    }

    private var currentDateTimeInfo: some View {
        let now = Date()
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Current Date/Time")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Local Time:")
                    Spacer()
                    Text(formatDateTime(now, timezone: .current))
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }

                HStack {
                    Text("UTC Time:")
                    Spacer()
                    Text(formatDateTime(now, timezone: TimeZone(abbreviation: "UTC")!))
                        .fontWeight(.medium)
                }

                HStack {
                    Text("UTC Timestamp:")
                    Spacer()
                    Text(String(format: "%.0f", now.timeIntervalSince1970))
                        .fontWeight(.medium)
                        .font(.caption)
                }
            }
            .font(.subheadline)
        }
    }

    private var dayBoundariesInfo: some View {
        let now = Date()
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Day Boundaries")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Today (Local):")
                    Spacer()
                    Text(formatDate(CalendarUtils.startOfDayLocal(for: now)))
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }

                HStack {
                    Text("Today (UTC):")
                    Spacer()
                    Text(formatDate(startOfDayUTCForDebug(now)))
                        .fontWeight(.medium)
                }

                if !areSameDayUTCForDebug(now, CalendarUtils.startOfDayLocal(for: now)) {
                    Text("Warning: Local and UTC days are different!")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 2)
                }
            }
            .font(.subheadline)
        }
    }

    private var weekdayInfo: some View {
        let now = Date()
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Weekday")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Calendar (Local):")
                    Spacer()
                    Text("\(CalendarUtils.weekdayComponentLocal(from: now)) (\(weekdayName(CalendarUtils.weekdayComponentLocal(from: now))))")
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }

                HStack {
                    Text("Calendar (UTC):")
                    Spacer()
                    Text("\(CalendarUtils.weekdayComponentUTC(from: now)) (\(weekdayName(CalendarUtils.weekdayComponentUTC(from: now))))")
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Habit (Local):")
                    Spacer()
                    let habitWeekday = CalendarUtils.calendarWeekdayToHabitWeekday(CalendarUtils.weekdayComponentLocal(from: now))
                    Text("\(habitWeekday) (\(habitWeekdayName(habitWeekday)))")
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }

                Text("Note: Calendar uses 1=Sunday, Habit uses 1=Monday")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
            .font(.subheadline)
        }
    }

    private var displaySettingsInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Display Settings")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Display Mode:")
                    Spacer()
                    Text(vm.profile.displayTimezoneMode.toLegacyString())
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                }

                HStack {
                    Text("Home Timezone:")
                    Spacer()
                    Text(vm.profile.homeTimezoneIdentifier)
                        .fontWeight(.medium)
                }
            }
            .font(.subheadline)
        }
    }

    // MARK: - Helper Functions

    private func formatUTCOffset(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = abs(seconds % 3600) / 60
        return String(format: "%+03d:%02d", hours, minutes)
    }

    private func formatDateTime(_ date: Date, timezone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.timeZone = timezone
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func weekdayName(_ calendarWeekday: Int) -> String {
        let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let index = (calendarWeekday - 1) % 7
        return names[index]
    }

    private func habitWeekdayName(_ habitWeekday: Int) -> String {
        let names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let index = (habitWeekday - 1) % 7
        return names[index]
    }

    @available(*, deprecated, message: "Debug-only wrapper for deprecated UTC method")
    private func startOfDayUTCForDebug(_ date: Date) -> Date {
        CalendarUtils.startOfDayUTC(for: date)
    }

    @available(*, deprecated, message: "Debug-only wrapper for deprecated UTC method")
    private func areSameDayUTCForDebug(_ date1: Date, _ date2: Date) -> Bool {
        CalendarUtils.areSameDayUTC(date1, date2)
    }
}
#endif
