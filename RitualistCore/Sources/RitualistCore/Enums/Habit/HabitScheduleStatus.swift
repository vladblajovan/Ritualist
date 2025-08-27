//
//  HabitScheduleStatus.swift
//  RitualistCore
//
//  Created by Claude on 16.08.2025.
//

import Foundation
import SwiftUI

/// Represents the schedule status of a habit for a specific date
public enum HabitScheduleStatus {
    /// Habit is scheduled for the current date and can be logged
    case scheduledToday
    /// Habit is not scheduled for the current date
    case notScheduledToday
    /// Habit is always available (daily or times per week with flexible scheduling)
    case alwaysScheduled
    
    public var isAvailable: Bool {
        switch self {
        case .scheduledToday, .alwaysScheduled:
            return true
        case .notScheduledToday:
            return false
        }
    }
    
    public var displayText: String {
        switch self {
        case .scheduledToday:
            return "Today"
        case .notScheduledToday:
            return "Not Scheduled"
        case .alwaysScheduled:
            return "Available"
        }
    }
    
    public var iconName: String {
        switch self {
        case .scheduledToday:
            return "calendar.circle.fill"
        case .notScheduledToday:
            return "calendar.circle"
        case .alwaysScheduled:
            return "infinity.circle.fill"
        }
    }
    
    @available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
    public var color: Color {
        switch self {
        case .scheduledToday:
            return .green
        case .notScheduledToday:
            return .orange
        case .alwaysScheduled:
            return .blue
        }
    }
    
    public var accessibilityLabel: String {
        switch self {
        case .scheduledToday:
            return "Scheduled for today"
        case .notScheduledToday:
            return "Not scheduled for today"
        case .alwaysScheduled:
            return "Always available"
        }
    }
}

// MARK: - Factory Methods

public extension HabitScheduleStatus {
    /// Determines the schedule status for a habit on a specific date
    static func forHabit(_ habit: Habit, date: Date, isScheduledDay: IsScheduledDayUseCase) -> HabitScheduleStatus {
        let isScheduled = isScheduledDay.execute(habit: habit, date: date)
        
        // Check if it's always available (daily or flexible weekly)
        switch habit.schedule {
        case .daily:
            return .alwaysScheduled
        case .timesPerWeek:
            return .alwaysScheduled
        case .daysOfWeek:
            return isScheduled ? .scheduledToday : .notScheduledToday
        }
    }
}