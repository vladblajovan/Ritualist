//
//  DateFormatter+Extensions.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//


import Foundation

public extension DateFormatter {
    static let errorLogFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    static let mediumDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Relative Date Formatting

public extension Date {
    /// Returns a human-readable relative time string
    /// Examples: "5 minutes ago", "2 hours ago", "yesterday", "last week", "Dec 15, 2024"
    ///
    /// - Parameter style: The formatting style (default: .named for "yesterday", "last week" etc.)
    /// - Returns: A localized relative time string
    func relativeString(style: RelativeDateTimeFormatter.UnitsStyle = .full) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = style
        formatter.dateTimeStyle = .named  // Uses "yesterday", "last week" when appropriate
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Returns a relative string with fallback to absolute date for old dates
    /// - Within 1 week: "5 minutes ago", "yesterday", "3 days ago"
    /// - Older than 1 week: "Dec 15, 2024 at 3:45 PM"
    func relativeOrAbsoluteString() -> String {
        let now = Date()
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now

        if self > oneWeekAgo {
            return relativeString()
        } else {
            return DateFormatter.mediumDateTimeFormatter.string(from: self)
        }
    }
}
