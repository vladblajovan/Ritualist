//
//  WidgetConstants.swift
//  RitualistWidget
//
//  Centralized constants for the widget extension.
//

import Foundation
import RitualistCore

// MARK: - Widget Constants

/// Widget-specific constants using shared BusinessConstants
enum WidgetConstants {
    /// Logger subsystem for widget logging
    static let loggerSubsystem = "com.ritualist.widget"

    /// App group identifier for shared data
    static let appGroupIdentifier = "group.com.vladblajovan.Ritualist"

    /// Deep link URL scheme for the main app
    static let urlScheme = "ritualist"

    /// Widget update interval from BusinessConstants
    static let updateInterval = BusinessConstants.widgetUpdateInterval

    /// Default emoji for habits without emoji
    static let defaultHabitEmoji = "📊"

    /// Timeline refresh policy intervals (in hours)
    static let timelineHours = 6

    /// Creates deep link URL for habit (legacy method for backward compatibility)
    static func habitDeepLinkURL(for habitId: UUID) -> URL {
        URL(string: "\(urlScheme)://habit/\(habitId)")!
    }

    /// Creates deep link URL for habit with date context and action parameters
    /// - Parameters:
    ///   - habitId: The habit identifier
    ///   - date: The date context for the habit interaction
    ///   - action: The action type (DeepLinkAction enum)
    /// - Returns: URL with format "ritualist://habit/{habitId}?date={ISO8601}&action={action}"
    static func habitDeepLinkURL(for habitId: UUID, date: Date, action: DeepLinkAction) -> URL {
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: date)

        var components = URLComponents()
        components.scheme = urlScheme
        components.host = "habit"
        components.path = "/\(habitId)"
        components.queryItems = [
            URLQueryItem(name: "date", value: dateString),
            URLQueryItem(name: "action", value: action.queryValue)
        ]

        guard let url = components.url else {
            // Fallback to legacy URL if construction fails
            return habitDeepLinkURL(for: habitId)
        }

        return url
    }

    /// Creates deep link URL for overview
    static func overviewDeepLinkURL() -> URL {
        URL(string: "\(urlScheme)://overview")!
    }
}
