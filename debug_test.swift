import Foundation
@testable import Ritualist
@testable import RitualistCore

// Debug script to understand the failing test
let calendar = Calendar.current

// Create the same habit as in the test
let habit = HabitBuilder.workoutHabit()
    .forDaysOfWeek([1, 3, 5]) // Mon, Wed, Fri
    .startingDaysAgo(21) // Ensure habit started well before test period
    .build()

let endDate = Date()
let startDate = calendar.date(byAdding: .day, value: -13, to: endDate)! // 2-week period

print("=== Test Setup ===")
print("Habit: \(habit.name)")
print("Schedule: \(habit.schedule)")
print("Start Date: \(startDate)")
print("End Date: \(endDate)")
print("Date Range Days: \(calendar.dateComponents([.day], from: startDate, to: endDate).day! + 1)")

// Create perfect logs and see what gets generated
let perfectLogs = HabitLogBuilder.createMonthlyLogs(for: habit, pattern: .perfect)

print("\n=== Perfect Logs Analysis ===")
print("Total perfect logs created: \(perfectLogs.count)")

// Print first 10 logs to see pattern
print("\nFirst 10 logs:")
for (index, log) in perfectLogs.prefix(10).enumerated() {
    let weekday = calendar.component(.weekday, from: log.date)
    let habitWeekday = weekday == 1 ? 7 : weekday - 1 // Convert to habit weekday
    print("  \(index + 1): \(log.date) - Calendar weekday: \(weekday), Habit weekday: \(habitWeekday)")
}

// Filter to test date range 
let scheduledLogsInRange = perfectLogs.filter { log in
    log.date >= startDate && log.date <= endDate
}.sorted { $0.date < $1.date }

print("\n=== Logs in Range Analysis ===")
print("Logs in range: \(scheduledLogsInRange.count)")

for (index, log) in scheduledLogsInRange.enumerated() {
    let weekday = calendar.component(.weekday, from: log.date)
    let habitWeekday = weekday == 1 ? 7 : weekday - 1 // Convert to habit weekday
    let isScheduled = [1, 3, 5].contains(habitWeekday)
    print("  \(index + 1): \(log.date) - Weekday: \(habitWeekday) - Scheduled: \(isScheduled)")
}

// Take first 4 as the test does
let logs = Array(scheduledLogsInRange.prefix(4))

print("\n=== Test Logs (First 4) ===")
print("Selected logs count: \(logs.count)")
for (index, log) in logs.enumerated() {
    let weekday = calendar.component(.weekday, from: log.date)
    let habitWeekday = weekday == 1 ? 7 : weekday - 1
    let isScheduled = [1, 3, 5].contains(habitWeekday)
    print("  \(index + 1): \(log.date) - Weekday: \(habitWeekday) - Scheduled: \(isScheduled)")
}

// Now test with the service
let service = DefaultHabitCompletionService(calendar: calendar)

let progress = service.calculateProgress(habit: habit, logs: logs, from: startDate, to: endDate)
let expectedCompletions = service.getExpectedCompletions(habit: habit, from: startDate, to: endDate)

print("\n=== Service Results ===")
print("Expected completions: \(expectedCompletions)")
print("Actual progress: \(progress)")
print("Expected progress: \(4.0 / 6.0)")

// Let's also manually check scheduled days in the range
print("\n=== Manual Scheduled Days Check ===")
var scheduledDaysCount = 0
var currentDate = calendar.startOfDay(for: startDate)
let endOfRange = calendar.startOfDay(for: endDate)

while currentDate <= endOfRange {
    let weekday = calendar.component(.weekday, from: currentDate)
    let habitWeekday = weekday == 1 ? 7 : weekday - 1
    let isScheduled = [1, 3, 5].contains(habitWeekday)
    
    if isScheduled {
        scheduledDaysCount += 1
        print("  Scheduled day \(scheduledDaysCount): \(currentDate) - Weekday: \(habitWeekday)")
    }
    
    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
}

print("Total scheduled days in range: \(scheduledDaysCount)")