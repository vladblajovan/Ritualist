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
    
    /// Creates deep link URL for habit
    static func habitDeepLinkURL(for habitId: UUID) -> URL {
        URL(string: "\(urlScheme)://habit/\(habitId)")!
    }
    
    /// Creates deep link URL for overview
    static func overviewDeepLinkURL() -> URL {
        URL(string: "\(urlScheme)://overview")!
    }
}