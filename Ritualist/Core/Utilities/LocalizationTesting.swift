import SwiftUI
import Foundation

// MARK: - Localization Testing Utilities
public enum LocalizationTesting {
    
    /// Test locales for validating UI layout with different text lengths
    public static let testLocales: [Locale] = [
        Locale(identifier: "en"),     // English - baseline
        Locale(identifier: "de"),     // German - longer compound words
        Locale(identifier: "ar"),     // Arabic - RTL, different character shapes
        Locale(identifier: "zh-CN"),  // Chinese - different character density
        Locale(identifier: "ja")     // Japanese - mixed scripts
    ]
    
    /// Simulate pseudo-localization for testing layout flexibility
    public static func pseudoLocalize(_ text: String) -> String {
        // Add brackets and extend length by ~30% to simulate longer languages
        let extended = text + String(repeating: "x", count: max(1, text.count / 3))
        return "[\(extended)]"
    }
    
    /// Test string lengths that commonly cause layout issues
    public enum TestStrings {
        public static let short = "OK"
        public static let medium = "Create New Habit"
        public static let long = "Daily Morning Meditation Practice with Mindfulness"
        public static let veryLong = "This is an extremely long text that might cause layout issues in constrained spaces and should wrap properly across multiple lines without breaking the interface design"
        
        // German equivalents (typically 30% longer)
        public static let longGerman = "Tägliche Morgenmeditationspraxis mit Achtsamkeitsübungen"
        public static let veryLongGerman = "Dies ist ein extrem langer Text, der Layoutprobleme in begrenzten Räumen verursachen könnte und sollte ordnungsgemäß über mehrere Zeilen umbrochen werden, ohne das Interface-Design zu zerstören"
    }
}

// MARK: - SwiftUI Testing Extensions
extension View {
    /// Preview with multiple locales for layout testing
    public func localizationPreview() -> some View {
        ForEach(LocalizationTesting.testLocales, id: \.identifier) { locale in
            self
                .environment(\.locale, locale)
                .previewDisplayName(locale.identifier)
        }
    }
    
    /// Test view with pseudo-localization
    public func pseudoLocalized() -> some View {
        self.environment(\.locale, Locale(identifier: "en-XA")) // Pseudo-locale
    }
    
    /// Add debug border to identify layout constraints
    public func debugLayout() -> some View {
        self.overlay(
            Rectangle()
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Dynamic Type Testing
extension View {
    /// Test with different Dynamic Type sizes
    public func dynamicTypePreview() -> some View {
        ForEach(ContentSizeCategory.allCases.filter { !$0.isAccessibilityCategory }, id: \.self) { category in
            self
                .environment(\.sizeCategory, category)
                .previewDisplayName("Dynamic Type: \(category)")
        }
    }
    
    /// Test with accessibility sizes
    public func accessibilityPreview() -> some View {
        ForEach([ContentSizeCategory.accessibilityMedium, .accessibilityExtraExtraExtraLarge], id: \.self) { category in
            self
                .environment(\.sizeCategory, category)
                .previewDisplayName("Accessibility: \(category)")
        }
    }
}

// MARK: - Layout Validation
public struct LayoutValidator {
    
    // Standard UI component constraints
    public enum ComponentConstraints {
        public static let tabBarLabel: CGFloat = 80    // Tab bar item width
        public static let buttonLabel: CGFloat = 120   // Standard button width
        public static let formLabel: CGFloat = 200     // Form field label width
        public static let cardTitle: CGFloat = 250     // Card or cell title width
        public static let alertMessage: CGFloat = 280  // Alert dialog width
        public static let accessibilityLabel: Int = 100 // VoiceOver character limit
    }
    
    /// String length constraints for different UI components
    public enum StringConstraints {
        case tabBarLabel        // Very short labels (Overview, Habits)
        case buttonLabel        // Action buttons (Save, Cancel)
        case formFieldLabel     // Form field names (Basic Information)
        case validationMessage  // Error messages
        case accessibilityLabel // VoiceOver descriptions
        case cardTitle          // List item titles
        case alertMessage       // Dialog messages
        
        public var characterLimit: Int {
            switch self {
            case .tabBarLabel: return 12
            case .buttonLabel: return 15
            case .formFieldLabel: return 30
            case .validationMessage: return 80
            case .accessibilityLabel: return 100
            case .cardTitle: return 40
            case .alertMessage: return 200
            }
        }
        
        public var pixelWidth: CGFloat {
            switch self {
            case .tabBarLabel: return ComponentConstraints.tabBarLabel
            case .buttonLabel: return ComponentConstraints.buttonLabel
            case .formFieldLabel: return ComponentConstraints.formLabel
            case .validationMessage: return ComponentConstraints.alertMessage
            case .accessibilityLabel: return 0 // Character-based only
            case .cardTitle: return ComponentConstraints.cardTitle
            case .alertMessage: return ComponentConstraints.alertMessage
            }
        }
    }
    
    /// Validate string against component constraints
    public static func validateString(_ text: String, for component: StringConstraints) -> ValidationResult {
        var issues: [String] = []
        
        // Character length validation
        if text.count > component.characterLimit {
            issues.append("Exceeds character limit (\(text.count)/\(component.characterLimit))")
        }
        
        // Line break validation (should be single line for most components)
        if text.contains("\n") && component != .alertMessage {
            issues.append("Contains line breaks (not recommended for \(component))")
        }
        
        // Leading/trailing whitespace
        if text != text.trimmingCharacters(in: .whitespacesAndNewlines) {
            issues.append("Contains leading or trailing whitespace")
        }
        
        // Empty string check
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append("String is empty or only whitespace")
        }
        
        return ValidationResult(
            text: text,
            component: component,
            isValid: issues.isEmpty,
            issues: issues
        )
    }
    
    /// Check if text fits within given pixel constraints
    public static func validateTextFits(_ text: String, maxWidth: CGFloat, font: UIFont) -> Bool {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let size = (text as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        ).size
        
        return size.width <= maxWidth
    }
    
    /// Validate all strings in String Catalog against their intended usage
    public static func validateAllStrings() -> [ValidationResult] {
        var results: [ValidationResult] = []
        
        // Define string mappings to their component types
        let stringMappings: [(String, StringConstraints)] = [
            // Navigation
            ("Overview", .tabBarLabel),
            ("Habits", .tabBarLabel),
            ("Settings", .tabBarLabel),
            
            // Buttons
            ("Save", .buttonLabel),
            ("Cancel", .buttonLabel),
            ("Delete", .buttonLabel),
            
            // Form fields
            ("Basic Information", .formFieldLabel),
            ("Daily Target", .formFieldLabel),
            ("Habit name", .formFieldLabel),
            
            // Validation messages
            ("Name is required", .validationMessage),
            ("Unit label is required for numeric habits", .validationMessage),
            ("Target must be greater than 0", .validationMessage),
            
            // Accessibility
            ("Previous month", .accessibilityLabel),
            ("Add new habit", .accessibilityLabel),
            ("Habit completed on January 15, 2024", .accessibilityLabel)
        ]
        
        for (text, component) in stringMappings {
            results.append(validateString(text, for: component))
        }
        
        return results
    }
    
    /// Generate comprehensive validation report
    public static func generateValidationReport() -> String {
        let results = validateAllStrings()
        var report = "🌍 Internationalization String Validation Report\n"
        report += "================================================\n\n"
        
        let passedCount = results.filter { $0.isValid }.count
        let totalCount = results.count
        
        report += "Summary: \(passedCount)/\(totalCount) strings passed validation\n\n"
        
        // Group by component type
        let groupedResults = Dictionary(grouping: results) { $0.component }
        
        for (component, componentResults) in groupedResults.sorted(by: { $0.key.characterLimit < $1.key.characterLimit }) {
            report += "\n📱 \(component) (limit: \(component.characterLimit) chars)\n"
            report += String(repeating: "-", count: 40) + "\n"
            
            for result in componentResults {
                let status = result.isValid ? "✅" : "❌"
                let truncatedText = result.text.count > 30 ? String(result.text.prefix(30)) + "..." : result.text
                report += "\(status) \"\(truncatedText)\"\n"
                
                if !result.isValid {
                    for issue in result.issues {
                        report += "   ⚠️  \(issue)\n"
                    }
                }
            }
        }
        
        return report
    }
}

// MARK: - Validation Result
public struct ValidationResult {
    public let text: String
    public let component: LayoutValidator.StringConstraints
    public let isValid: Bool
    public let issues: [String]
    
    public var severity: Severity {
        if isValid { return .pass }
        if issues.contains(where: { $0.contains("empty") }) { return .error }
        if issues.contains(where: { $0.contains("Exceeds") }) { return .warning }
        return .info
    }
    
    public enum Severity {
        case pass, info, warning, error
        
        public var emoji: String {
            switch self {
            case .pass: return "✅"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            }
        }
    }
}
