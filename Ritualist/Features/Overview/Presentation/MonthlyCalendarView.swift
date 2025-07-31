import SwiftUI

public struct MonthlyCalendarView: View {
    let selectedHabit: Habit
    let currentMonth: Date
    let fullCalendarDays: [CalendarDay]
    let loggedDates: Set<Date>
    let isLoggingHabit: Bool
    let userFirstDayOfWeek: Int?
    let isViewingCurrentMonth: Bool
    let getHabitValueForDate: (Date) -> Double
    let isDateSchedulable: (Date) -> Bool
    let isWeeklyTargetMet: (Date) -> Bool
    let onMonthChange: (Int) async -> Void
    let onDateTap: (Date) async -> Void
    let onAdjacentDateTap: (Date) async -> Void
    let onTodayTap: () async -> Void
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter
    }()
    
    public var body: some View {
        VStack(spacing: Spacing.large) {
            // Month navigation with Today button
            HStack {
                Button {
                    Task { await onMonthChange(-1) }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(AppColors.brand)
                }
                .accessibilityLabel(Strings.Accessibility.previousMonth)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(dateFormatter.string(from: currentMonth))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityLabel(Strings.Accessibility.monthHeader(dateFormatter.string(from: currentMonth)))
                    
                    if !isViewingCurrentMonth {
                        Button {
                            Task { await onTodayTap() }
                        } label: {
                            Text(Strings.Calendar.today)
                                .font(.caption)
                                .foregroundColor(AppColors.brand)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(AppColors.brand.opacity(0.1))
                                )
                        }
                        .accessibilityLabel(Strings.Accessibility.goToToday)
                    }
                }
                
                Spacer()
                
                Button {
                    Task { await onMonthChange(1) }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(AppColors.brand)
                }
                .accessibilityLabel(Strings.Accessibility.nextMonth)
            }
            .padding(.horizontal, 16)
            
            // Calendar grid
            CalendarGridView(
                habit: selectedHabit,
                fullCalendarDays: fullCalendarDays,
                loggedDates: loggedDates,
                isLoggingHabit: isLoggingHabit,
                getHabitValueForDate: getHabitValueForDate,
                isDateSchedulable: isDateSchedulable,
                isWeeklyTargetMet: isWeeklyTargetMet,
                onDateTap: onDateTap,
                onAdjacentDateTap: onAdjacentDateTap,
                userFirstDayOfWeek: userFirstDayOfWeek
            )
        }
        .padding(.bottom, 16)
    }
}

public struct CalendarGridView: View {
    let habit: Habit
    let fullCalendarDays: [CalendarDay]
    let loggedDates: Set<Date>
    let isLoggingHabit: Bool
    let getHabitValueForDate: (Date) -> Double
    let isDateSchedulable: (Date) -> Bool
    let isWeeklyTargetMet: (Date) -> Bool
    let onDateTap: (Date) async -> Void
    let onAdjacentDateTap: (Date) async -> Void
    let userFirstDayOfWeek: Int?
    
    private var calendar: Calendar {
        DateUtils.userCalendar(firstDayOfWeek: userFirstDayOfWeek)
    }
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    private var weekdayHeaders: [String] {
        DateUtils.orderedWeekdaySymbols(
            firstDayOfWeek: userFirstDayOfWeek ?? calendar.firstWeekday, 
            style: .veryShort
        )
    }
    
    public var body: some View {
        VStack(spacing: Spacing.small) {
            // Weekday headers
            HStack {
                ForEach(Array(weekdayHeaders.enumerated()), id: \.offset) { _, weekday in
                    Text(weekday)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar days - use regular VStack/HStack to ensure all 6 rows show
            VStack(spacing: Spacing.small) {
                ForEach(0..<6, id: \.self) { week in
                    HStack(spacing: Spacing.small) {
                        ForEach(0..<7, id: \.self) { day in
                            let index = week * 7 + day
                            if index < fullCalendarDays.count {
                                let calendarDay = fullCalendarDays[index]
                                CalendarDayView(
                                    date: calendarDay.date,
                                    habit: habit,
                                    isCurrentMonth: calendarDay.isCurrentMonth,
                                    isLogged: loggedDates.contains(calendar.startOfDay(for: calendarDay.date)),
                                    currentValue: getHabitValueForDate(calendarDay.date),
                                    isLoggingHabit: isLoggingHabit,
                                    isSchedulable: isDateSchedulable(calendarDay.date),
                                    isWeeklyTargetMet: isWeeklyTargetMet(calendarDay.date)
                                ) {
                                    if calendarDay.isCurrentMonth {
                                        await onDateTap(calendarDay.date)
                                    } else {
                                        await onAdjacentDateTap(calendarDay.date)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                // Empty placeholder if needed
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 40, height: 40)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}