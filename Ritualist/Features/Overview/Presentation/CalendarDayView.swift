import SwiftUI
import RitualistCore

public struct CalendarDayView: View {
    let date: Date
    let habit: Habit
    let isCurrentMonth: Bool
    let isLogged: Bool
    let currentValue: Double
    let isLoggingHabit: Bool
    let isSchedulable: Bool
    let isWeeklyTargetMet: Bool
    let onTap: () async -> Void
    let onLongPressToReset: (() async -> Void)?
    let onNumericHabitUpdate: ((Habit, Double) async -> Void)?
    
    @State private var showingResetConfirmation = false
    @State private var showingNumericSheet = false
    
    private let calendar = Calendar.current
    
    /// Helper to check if habit uses weekly-style completion logic
    private var isWeeklyStyleHabit: Bool {
        switch habit.schedule {
        case .timesPerWeek, .daysOfWeek:
            return true
        case .daily:
            return false
        }
    }
    
    /// Helper to check if the habit is completed for this day
    private var isCompleted: Bool {
        // Weekly style habits: check if weekly target is met and has current value
        if isWeeklyStyleHabit {
            return isWeeklyTargetMet && currentValue > 0
        }
        // Binary habits: check if logged
        if habit.kind == .binary {
            return isLogged
        }
        // Numeric habits: check if target reached
        if let target = habit.dailyTarget {
            return currentValue >= target
        }
        return false
    }
    
    public var body: some View {
        Button {
            // Allow tap only if: not future, schedulable, and not completed
            // This prevents accidental taps on completed habits (they need long press)
            if !isFutureDate && isSchedulable && !isCompleted {
                if habit.kind == .numeric {
                    showingNumericSheet = true
                } else {
                    Task { await onTap() }
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(circleBackgroundColor)
                    .frame(width: ComponentSize.calendarDay, height: ComponentSize.calendarDay)
                
                // Handle different schedule types and display logic
                if case .timesPerWeek = habit.schedule {
                    // Times per week: show checkmark when weekly target met, otherwise just day number
                    if isWeeklyTargetMet && currentValue > 0 {
                        Image(systemName: "checkmark")
                            .font(.system(size: Typography.calendarDaySmall, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: Typography.calendarDayNumber, weight: .medium))
                            .foregroundColor(dayTextColor)
                    }
                } else if case .daysOfWeek = habit.schedule {
                    // Specific days habit: show checkmark when weekly target met, otherwise just day number
                    if isWeeklyTargetMet && currentValue > 0 {
                        Image(systemName: "checkmark")
                            .font(.system(size: Typography.calendarDaySmall, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: Typography.calendarDayNumber, weight: .medium))
                            .foregroundColor(dayTextColor)
                    }
                } else if habit.kind == .binary && !isWeeklyStyleHabit {
                    // Daily binary habit: show checkmark when completed
                    if isLogged {
                        Image(systemName: "checkmark")
                            .font(.system(size: Typography.calendarDaySmall, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: Typography.calendarDayNumber, weight: .medium))
                            .foregroundColor(dayTextColor)
                    }
                } else {
                    // Count habit: show based on target achievement
                    if let target = habit.dailyTarget, currentValue >= target {
                        // Target achieved: show checkmark like binary habit
                        Image(systemName: "checkmark")
                            .font(.system(size: Typography.calendarDaySmall, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        // Working toward target: show count and day number
                        VStack(spacing: 1) {
                            if currentValue > 0 {
                                Text("\(Int(currentValue))")
                                    .font(.system(size: Typography.calendarTiny, weight: .bold))
                                    .foregroundColor(countTextColor)
                            }
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: currentValue > 0 ? Typography.calendarProgress : Typography.calendarDayNumber, weight: .medium))
                                .foregroundColor(dayTextColor)
                        }
                    }
                }
                
                // Loading indicator with better visual feedback
                if isLoggingHabit {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: ComponentSize.calendarDay, height: ComponentSize.calendarDay)
                        .overlay(
                            ProgressView()
                                .scaleEffect(ScaleFactors.tiny)
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brand))
                        )
                        .animation(.easeInOut(duration: 0.3), value: isLoggingHabit)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoggingHabit || isFutureDate || !isSchedulable || isCompleted)
        .onLongPressGesture(minimumDuration: 0.6) {
            // Only allow long press on completed habits that are not in future and are schedulable
            if isCompleted && !isFutureDate && isSchedulable {
                showingResetConfirmation = true
            }
        }
        .confirmationDialog(
            "Reset Completed Habit",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                Task { await onLongPressToReset?() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will mark the habit as incomplete for this day.")
        }
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(isLogged ? [.isSelected, .isButton] : .isButton)
        .sheet(isPresented: $showingNumericSheet) {
            if habit.kind == .numeric {
                NumericHabitLogSheet(
                    habit: habit,
                    currentValue: currentValue,
                    onSave: { newValue in
                        Task {
                            await onNumericHabitUpdate?(habit, newValue)
                        }
                    },
                    onCancel: {
                        // Sheet dismisses automatically
                    }
                )
            }
        }
    }
    
    private var accessibilityDescription: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.locale = Locale.current
        let fullDate = dateFormatter.string(from: date)
        
        if !isSchedulable {
            return "\(fullDate), not scheduled for this habit"
        }
        
        if isFutureDate {
            return "\(fullDate), future date, logging disabled"
        }
        
        if case .timesPerWeek = habit.schedule {
            let countText = currentValue > 0 ? "\(Int(currentValue)) logged" : "not logged"
            if isWeeklyTargetMet {
                return "\(fullDate), weekly target met, \(countText)"
            } else {
                return "\(fullDate), \(countText), working toward weekly target"
            }
        }
        
        if case .daysOfWeek = habit.schedule {
            let countText = currentValue > 0 ? "logged" : "not logged"
            if isWeeklyTargetMet {
                return "\(fullDate), all specific days completed this week, \(countText)"
            } else {
                return "\(fullDate), \(countText), working toward completing all specific days this week"
            }
        }
        
        if habit.kind == .binary {
            return isLogged 
                ? Strings.Accessibility.habitLogged(fullDate)
                : Strings.Accessibility.habitNotLogged(fullDate)
        } else {
            let countText = currentValue > 0 ? "\(Int(currentValue)) count" : "no count"
            if let target = habit.dailyTarget {
                if currentValue >= target {
                    return "\(fullDate), target achieved, \(Int(currentValue)) of \(Int(target)), tap to reset"
                } else {
                    return "\(fullDate), \(countText) of \(Int(target)) target"
                }
            } else {
                return "\(fullDate), \(countText)"
            }
        }
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var isFutureDate: Bool {
        let today = calendar.startOfDay(for: Date())
        let dateToCheck = calendar.startOfDay(for: date)
        return dateToCheck > today
    }
    
    private var isTargetReached: Bool {
        guard habit.kind == .numeric, let target = habit.dailyTarget else { return false }
        return currentValue >= target
    }
    
    private var circleBackgroundColor: Color {
        // Non-schedulable days: always clear background
        if !isSchedulable {
            return Color.clear
        }
        
        // Weekly habits and specific days: full color if target met and this day has value, otherwise check progress
        if isWeeklyStyleHabit {
            if isWeeklyTargetMet && currentValue > 0 {
                return AppColors.brand
            } else if currentValue > 0 {
                return (AppColors.brand).opacity(0.3)
            }
            return Color.clear
        }
        
        // Binary habits
        if habit.kind == .binary {
            return isLogged ? AppColors.brand : Color.clear
        } else {
            // Count habit: show progress-based background
            if currentValue > 0 {
                if let target = habit.dailyTarget, currentValue >= target {
                    // Target reached: full color
                    return AppColors.brand
                } else {
                    // Progress made: light background
                    return (AppColors.brand).opacity(0.3)
                }
            }
            return Color.clear
        }
    }
    
    private var dayTextColor: Color {
        if !isCurrentMonth {
            return .secondary.opacity(0.6)
        } else if !isSchedulable {
            return .secondary.opacity(0.3) // Non-schedulable days are more faded
        } else if isFutureDate {
            return .secondary.opacity(0.4)
        } else if isToday {
            return AppColors.brand
        } else if habit.kind == .numeric && isLogged {
            // Count habit at target: white text
            return .white
        } else if isWeeklyStyleHabit && isWeeklyTargetMet && currentValue > 0 {
            // Weekly habit or specific days with target met: white text
            return .white
        } else {
            return .primary
        }
    }
    
    private var countTextColor: Color {
        if !isSchedulable {
            return .secondary.opacity(0.3)
        } else if isFutureDate {
            return .secondary.opacity(0.4)
        } else if let target = habit.dailyTarget, currentValue >= target {
            return .white
        } else if isWeeklyStyleHabit && isWeeklyTargetMet {
            return .white
        } else {
            return AppColors.brand
        }
    }
}
