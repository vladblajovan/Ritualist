import Foundation

// Simulate the test scenario exactly
let testCalendar = Calendar(identifier: .gregorian)
let monday = testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 4))!
let tuesday = testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 5))!
let wednesday = testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 6))!
let thursday = testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 7))!
let friday = testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 8))!

// Simulate the weekday conversion logic
func calendarWeekdayToHabitWeekday(_ calendarWeekday: Int) -> Int {
    return calendarWeekday == 1 ? 7 : calendarWeekday - 1
}

func getHabitWeekday(from date: Date) -> Int {
    let calendarWeekday = testCalendar.component(.weekday, from: date)
    return calendarWeekdayToHabitWeekday(calendarWeekday)
}

// Test the daysOfWeek schedule [1, 3, 5] (Mon, Wed, Fri)
let scheduledDays: Set<Int> = [1, 3, 5]

print("=== Verifying Test Scenario ===")
print("Scheduled days: [1, 3, 5] (Monday, Wednesday, Friday)")
print()

let testDates = [
    ("Monday", monday),
    ("Tuesday", tuesday),
    ("Wednesday", wednesday),
    ("Thursday", thursday),
    ("Friday", friday)
]

for (name, date) in testDates {
    let habitWeekday = getHabitWeekday(from: date)
    let isScheduled = scheduledDays.contains(habitWeekday)
    print("\(name): Habit weekday=\(habitWeekday), Is scheduled=\(isScheduled)")
}

print()
print("=== Simulating Streak Calculation (working backwards from Friday) ===")

// Simulate calculateDaysOfWeekCurrentStreak logic
func simulateStreakCalculation(asOf: Date, logs: [Date]) -> Int {
    var streak = 0
    var currentDate = testCalendar.startOfDay(for: asOf)
    
    print("Starting from: \(currentDate)")
    
    // Simulate going back day by day
    for i in 0..<10 { // Limit to prevent infinite loop
        let habitWeekday = getHabitWeekday(from: currentDate)
        let isScheduled = scheduledDays.contains(habitWeekday)
        
        print("Day \(i): \(currentDate), weekday=\(habitWeekday), scheduled=\(isScheduled)")
        
        if isScheduled {
            let hasLog = logs.contains { testCalendar.isDate($0, inSameDayAs: currentDate) }
            print("  Has log: \(hasLog)")
            
            if hasLog {
                streak += 1
                print("  Streak increased to: \(streak)")
            } else {
                print("  Missing log, breaking streak")
                break
            }
        } else {
            print("  Not scheduled, skipping")
        }
        
        guard let previousDay = testCalendar.date(byAdding: .day, value: -1, to: currentDate) else { 
            print("  Cannot go back further")
            break 
        }
        currentDate = previousDay
    }
    
    return streak
}

// The test scenario logs
let logDates = [monday, wednesday, friday] // Only scheduled days
print()
print("Logs provided: Monday, Wednesday, Friday")
print()

let calculatedStreak = simulateStreakCalculation(asOf: friday, logs: logDates)
print()
print("=== RESULT ===")
print("Calculated streak: \(calculatedStreak)")
print("Expected streak: 3")
print("Match: \(calculatedStreak == 3 ? "✅" : "❌")")