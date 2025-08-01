//
//  NumberUtils.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public enum NumberUtils {
    /// Locale-aware number formatter for habit values
    public static func habitValueFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter
    }
    
    /// Format a habit value with proper locale formatting
    public static func formatHabitValue(_ value: Double) -> String {
        habitValueFormatter().string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    /// Format a habit value with unit label
    public static func formatHabitValueWithUnit(_ value: Double, unit: String) -> String {
        let formattedValue = formatHabitValue(value)
        return "\(formattedValue) \(unit)"
    }
    
    /// Parse user input respecting locale
    public static func parseHabitValue(_ input: String) -> Double? {
        habitValueFormatter().number(from: input)?.doubleValue
    }
    
    /// Locale-aware percentage formatter
    public static func percentageFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }
    
    /// Format percentage value
    public static func formatPercentage(_ value: Double) -> String {
        percentageFormatter().string(from: NSNumber(value: value)) ?? "\(Int(value * 100))%"
    }
}
