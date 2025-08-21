import Foundation

// Debug script to understand the date range and weekday logic
let calendar = Calendar.current

let endDate = Date()
let startDate = calendar.date(byAdding: .day, value: -13, to: endDate)! // 2-week period

print("=== Date Range Analysis ===")
print("Start Date: \(startDate)")
print("End Date: \(endDate)")
print("Total days in range: \(calendar.dateComponents([.day], from: startDate, to: endDate).day! + 1)")

// Simulate what createMonthlyLogs with .perfect pattern does
print("\n=== Monthly Logs Pattern Analysis ===")

// The pattern creates logs for -29...0 days
var logsCreated = 0
var logsInRange = 0

for dayOffset in -29...0 {
    let logDate = calendar.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
    let weekday = calendar.component(.weekday, from: logDate)
    let habitWeekday = weekday == 1 ? 7 : weekday - 1 // Convert to habit weekday (1=Mon, 7=Sun)
    
    // Perfect pattern creates log for every day
    let shouldCreateLog = true // pattern .perfect always returns true
    
    if shouldCreateLog {
        logsCreated += 1
        
        // Check if this log is in our test range
        if logDate >= startDate && logDate <= endDate {
            logsInRange += 1
            
            // Check if it's a scheduled day for Mon, Wed, Fri (1, 3, 5)
            let isScheduled = [1, 3, 5].contains(habitWeekday)
            
            print("  Day \(dayOffset): \(logDate) - Weekday: \(habitWeekday) - Scheduled: \(isScheduled)")
        }
    }
}

print("\nTotal logs created by pattern: \(logsCreated)")
print("Logs in test range: \(logsInRange)")

// Now manually check what scheduled days exist in the range
print("\n=== Scheduled Days in Range ===")
var scheduledDaysCount = 0
var currentDate = calendar.startOfDay(for: startDate)
let endOfRange = calendar.startOfDay(for: endDate)

while currentDate <= endOfRange {
    let weekday = calendar.component(.weekday, from: currentDate)
    let habitWeekday = weekday == 1 ? 7 : weekday - 1
    let isScheduled = [1, 3, 5].contains(habitWeekday)
    
    if isScheduled {
        scheduledDaysCount += 1
        let dayName = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][habitWeekday]
        print("  Scheduled day \(scheduledDaysCount): \(currentDate) (\(dayName))")
    }
    
    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
}

print("\nTotal scheduled days in range: \(scheduledDaysCount)")
print("Expected: 6 scheduled days (2 weeks × 3 days per week)")
print("Test expects 4 out of 6 = 66.7% completion")

// Let's also check the first 4 scheduled days specifically
print("\n=== First 4 Scheduled Days ===")
var foundScheduled = 0
currentDate = calendar.startOfDay(for: startDate)

while currentDate <= endOfRange && foundScheduled < 4 {
    let weekday = calendar.component(.weekday, from: currentDate)
    let habitWeekday = weekday == 1 ? 7 : weekday - 1
    let isScheduled = [1, 3, 5].contains(habitWeekday)
    
    if isScheduled {
        foundScheduled += 1
        let dayName = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][habitWeekday]
        print("  \(foundScheduled): \(currentDate) (\(dayName))")
    }
    
    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
}