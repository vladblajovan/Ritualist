//
//  TimeOfDay.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//


import Foundation

public enum TimeOfDay: CaseIterable {
    case morning    // Until 11:00
    case noon       // Between 11:00 and 16:00
    case evening    // After 16:00
    
    /// Get the current time of day based on current time
    public static func current() -> TimeOfDay {
        return timeOfDay(for: Date())
    }
    
    /// Get the time of day for a specific date
    private static func timeOfDay(for date: Date) -> TimeOfDay {
        let hour = CalendarUtils.hourComponentUTC(from: date)
        
        switch hour {
        case 0..<11:
            return .morning
        case 11..<16:
            return .noon
        default:
            return .evening
        }
    }
}