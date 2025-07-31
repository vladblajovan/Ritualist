import SwiftUI

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
    
    public var body: some View {
        Button {
            if !isFutureDate && isSchedulable && (!isTargetReached || habit.kind == .numeric) {
                Task { await onTap() }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(circleBackgroundColor)
                    .frame(width: 40, height: 40)
                
                // Handle different schedule types and display logic
                if case .timesPerWeek = habit.schedule {
                    // Times per week: show checkmark when weekly target met, otherwise just day number
                    if isWeeklyTargetMet && currentValue > 0 {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(dayTextColor)
                    }
                } else if case .daysOfWeek = habit.schedule {
                    // Specific days habit: show checkmark when weekly target met, otherwise just day number
                    if isWeeklyTargetMet && currentValue > 0 {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(dayTextColor)
                    }
                } else if habit.kind == .binary && !isWeeklyStyleHabit {
                    // Daily binary habit: show checkmark when completed
                    if isLogged {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(dayTextColor)
                    }
                } else {
                    // Count habit: show based on target achievement
                    if let target = habit.dailyTarget, currentValue >= target {
                        // Target achieved: show checkmark like binary habit
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        // Working toward target: show count and day number
                        VStack(spacing: 1) {
                            if currentValue > 0 {
                                Text("\(Int(currentValue))")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(countTextColor)
                            }
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: currentValue > 0 ? 11 : 16, weight: .medium))
                                .foregroundColor(dayTextColor)
                        }
                    }
                }
                
                // Loading indicator with better visual feedback
                if isLoggingHabit {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 40, height: 40)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.6)
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brand))
                        )
                        .animation(.easeInOut(duration: 0.3), value: isLoggingHabit)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoggingHabit || isFutureDate || !isSchedulable || (isTargetReached && habit.kind != .numeric))
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(isLogged ? [.isSelected, .isButton] : .isButton)
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
                return Color(hex: habit.colorHex) ?? AppColors.brand
            } else if currentValue > 0 {
                return (Color(hex: habit.colorHex) ?? AppColors.brand).opacity(0.3)
            }
            return Color.clear
        }
        
        // Binary habits
        if habit.kind == .binary {
            return isLogged ? Color(hex: habit.colorHex) ?? AppColors.brand : Color.clear
        } else {
            // Count habit: show progress-based background
            if currentValue > 0 {
                if let target = habit.dailyTarget, currentValue >= target {
                    // Target reached: full color
                    return Color(hex: habit.colorHex) ?? AppColors.brand
                } else {
                    // Progress made: light background
                    return (Color(hex: habit.colorHex) ?? AppColors.brand).opacity(0.3)
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
            return Color(hex: habit.colorHex) ?? AppColors.brand
        }
    }
}