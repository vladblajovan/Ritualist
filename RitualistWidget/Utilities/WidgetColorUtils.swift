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

