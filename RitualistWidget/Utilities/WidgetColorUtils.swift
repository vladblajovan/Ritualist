//
//  WidgetUtilities.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import SwiftUI
import RitualistCore

// MARK: - Widget Color Utilities

/// Widget-specific color utilities
/// Provides consistent color creation using AppColors.RGB values
extension Color {
    
    /// Creates the brand color using AppColors.RGB.brand values
    static var widgetBrand: Color {
        Color(
            red: AppColors.RGB.brand.red,
            green: AppColors.RGB.brand.green,
            blue: AppColors.RGB.brand.blue
        )
    }
    
    /// Creates brand color with specified opacity
    static func widgetBrand(opacity: Double) -> Color {
        widgetBrand.opacity(opacity)
    }
}

// MARK: - Widget Constants

/// Widget-specific constants using shared BusinessConstants
enum WidgetConstants {
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