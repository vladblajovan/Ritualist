import Foundation

/// View logic for numeric habit log sheet calculations
/// Separated for testability and reusability across the app
public enum NumericHabitLogViewLogic {

    // MARK: - Target Calculation

    /// Returns the effective daily target, ensuring a minimum of 1.0
    /// - Parameter habitTarget: The habit's configured daily target (nil if not set)
    /// - Returns: The daily target, minimum 1.0
    public static func effectiveDailyTarget(from habitTarget: Double?) -> Double {
        max(habitTarget ?? 1.0, 1.0)
    }

    // MARK: - Progress Calculation

    /// Calculates progress percentage (0.0 to 1.0) towards the daily target
    /// - Parameters:
    ///   - value: Current progress value
    ///   - dailyTarget: The daily target to measure against
    /// - Returns: Progress percentage clamped between 0.0 and 1.0
    public static func progressPercentage(value: Double, dailyTarget: Double) -> Double {
        guard dailyTarget > 0 else { return 0 }
        return min(max(value / dailyTarget, 0.0), 1.0)
    }

    /// Checks if the current value meets or exceeds the daily target
    /// - Parameters:
    ///   - value: Current progress value
    ///   - dailyTarget: The daily target
    /// - Returns: True if value >= dailyTarget
    public static func isCompleted(value: Double, dailyTarget: Double) -> Bool {
        value >= dailyTarget
    }

    // MARK: - Maximum Value Calculation

    /// Calculates the maximum allowed value for a habit
    ///
    /// Business rules:
    /// - Allow 10% over target OR at least 50 over target (whichever is larger)
    /// - Cap at 2x target to prevent unreasonable entries
    ///
    /// - Parameter dailyTarget: The daily target
    /// - Returns: Maximum allowed value
    ///
    /// Examples:
    /// - Target 100: max(50, 10) = 50, so 100 + 50 = 150, capped at min(150, 200) = 150
    /// - Target 1000: max(50, 100) = 100, so 1000 + 100 = 1100, capped at min(1100, 2000) = 1100
    /// - Target 10: max(50, 1) = 50, so 10 + 50 = 60, capped at min(60, 20) = 20
    public static func maxAllowedValue(for dailyTarget: Double) -> Double {
        let tenPercentOver = dailyTarget * 0.1
        let minimumOverage = 50.0
        let calculated = dailyTarget + max(minimumOverage, tenPercentOver)
        let doubleTarget = dailyTarget * 2.0
        return min(calculated, doubleTarget)
    }

    // MARK: - Validation

    /// Checks if a value is within valid bounds
    /// - Parameters:
    ///   - value: The value to validate
    ///   - dailyTarget: The daily target (used to calculate max)
    /// - Returns: True if value is between 0 and maxAllowedValue
    public static func isValidValue(_ value: Double, dailyTarget: Double) -> Bool {
        let maxValue = maxAllowedValue(for: dailyTarget)
        return value >= 0 && value <= maxValue
    }

    /// Checks if the value can be decremented (value > 0)
    public static func canDecrement(value: Double) -> Bool {
        value > 0
    }

    /// Checks if the value can be incremented (value < maxAllowedValue)
    public static func canIncrement(value: Double, dailyTarget: Double) -> Bool {
        value < maxAllowedValue(for: dailyTarget)
    }

    // MARK: - Remaining Calculations

    /// Calculates the remaining amount to reach the target
    /// - Parameters:
    ///   - value: Current progress value
    ///   - dailyTarget: The daily target
    /// - Returns: Remaining amount (0 if target met or exceeded)
    public static func remaining(value: Double, dailyTarget: Double) -> Double {
        max(dailyTarget - value, 0)
    }

    /// Calculates the remaining amount to reach the maximum allowed value
    /// - Parameters:
    ///   - value: Current progress value
    ///   - dailyTarget: The daily target (used to calculate max)
    /// - Returns: Remaining amount to max
    public static func remainingToMax(value: Double, dailyTarget: Double) -> Double {
        let maxValue = maxAllowedValue(for: dailyTarget)
        return max(maxValue - value, 0)
    }

    // MARK: - Quick Increment Amounts

    /// Calculates adaptive quick increment button values based on remaining progress
    ///
    /// Before target: computed against remaining to target
    /// After target: computed against remaining to max
    ///
    /// - Parameters:
    ///   - value: Current progress value
    ///   - dailyTarget: The daily target
    /// - Returns: Array of increment amounts (0-2 values), empty if very close to goal
    public static func quickIncrementAmounts(value: Double, dailyTarget: Double) -> [Int] {
        let completed = isCompleted(value: value, dailyTarget: dailyTarget)
        let rem: Int

        if completed {
            rem = Int(remainingToMax(value: value, dailyTarget: dailyTarget))
        } else {
            rem = Int(remaining(value: value, dailyTarget: dailyTarget))
        }

        switch rem {
        case ..<5:
            return []  // No quick buttons when very close
        case 5..<20:
            return [2, 5]
        case 20..<100:
            return [5, 10]
        case 100..<500:
            return [10, 50]
        case 500..<2000:
            return [100, 500]
        case 2000..<10000:
            return [500, 1000]
        case 10000..<50000:
            return [1000, 5000]
        default:
            return [5000, 10000]
        }
    }

    // MARK: - Number Formatting

    /// Formats large numbers with K suffix for readability
    /// - Parameter amount: The amount to format
    /// - Returns: Formatted string (e.g., "500", "1K", "2.5K")
    public static func formatAmount(_ amount: Int) -> String {
        if amount >= 1000 {
            let thousands = Double(amount) / 1000.0
            if thousands == Double(Int(thousands)) {
                return "\(Int(thousands))K"
            }
            return String(format: "%.1fK", thousands)
        }
        return "\(amount)"
    }

    // MARK: - Unit Label

    /// Returns the unit label to display, with a fallback to "units"
    /// - Parameter habitUnitLabel: The habit's configured unit label (may be nil or empty)
    /// - Returns: The unit label or "units" as fallback
    public static func unitLabel(from habitUnitLabel: String?) -> String {
        if let label = habitUnitLabel?.trimmingCharacters(in: .whitespacesAndNewlines),
           !label.isEmpty {
            return label
        }
        return "units"
    }
}
