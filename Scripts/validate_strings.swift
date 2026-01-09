#!/usr/bin/env swift

import Foundation

// MARK: - String Validation Script
// This script validates all localized strings for length and format constraints
// Run with: swift Scripts/validate_strings.swift

struct StringConstraints {
    let name: String
    let characterLimit: Int
    let pixelWidth: CGFloat

    static let tabBarLabel = StringConstraints(name: "Tab Bar", characterLimit: 12, pixelWidth: 80)
    static let buttonLabel = StringConstraints(name: "Button", characterLimit: 15, pixelWidth: 120)
    static let formFieldLabel = StringConstraints(name: "Form Field", characterLimit: 40, pixelWidth: 200)
    static let validationMessage = StringConstraints(name: "Validation", characterLimit: 85, pixelWidth: 280)
    static let accessibilityLabel = StringConstraints(name: "Accessibility", characterLimit: 100, pixelWidth: 0)
    // For detailed descriptions, empty states, and explanatory text that needs more space
    static let longDescription = StringConstraints(name: "Long Description", characterLimit: 150, pixelWidth: 350)
    // For legal text, terms, and multi-sentence content
    static let legalText = StringConstraints(name: "Legal Text", characterLimit: 500, pixelWidth: 0)
}

struct ValidationResult {
    let key: String
    let value: String
    let constraint: StringConstraints
    let isValid: Bool
    let issues: [String]
}

class StringValidator {
    
    func validateStringCatalog(at path: String) -> [ValidationResult] {
        guard let data = FileManager.default.contents(atPath: path),
              let catalog = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let strings = catalog["strings"] as? [String: Any] else {
            print("❌ Could not read String Catalog at: \(path)")
            return []
        }
        
        var results: [ValidationResult] = []
        
        for (key, stringData) in strings {
            guard let stringInfo = stringData as? [String: Any],
                  let localizations = stringInfo["localizations"] as? [String: Any],
                  let englishLoc = localizations["en"] as? [String: Any] else {
                continue
            }
            
            let value: String
            
            // Handle both regular strings and plural variations
            if let stringUnit = englishLoc["stringUnit"] as? [String: Any],
               let stringValue = stringUnit["value"] as? String {
                value = stringValue
            } else if let variations = englishLoc["variations"] as? [String: Any],
                      let plural = variations["plural"] as? [String: Any],
                      let other = plural["other"] as? [String: Any],
                      let stringUnit = other["stringUnit"] as? [String: Any],
                      let stringValue = stringUnit["value"] as? String {
                value = stringValue
            } else {
                continue
            }
            
            let constraint = determineConstraint(for: key)
            let result = validateString(key: key, value: value, constraint: constraint)
            results.append(result)
        }
        
        return results
    }
    
    private func determineConstraint(for key: String) -> StringConstraints {
        let lowercaseKey = key.lowercased()

        switch key {
        case _ where key.hasPrefix("navigation.") || key.hasPrefix("navigation"):
            return .tabBarLabel
        case _ where key.hasPrefix("button.") || key.hasPrefix("button"):
            return .buttonLabel
        case _ where key.hasPrefix("form.") || key.hasPrefix("form"):
            return .formFieldLabel
        case _ where key.hasPrefix("validation.") || key.hasPrefix("validation"):
            return .validationMessage
        case _ where key.hasPrefix("accessibility.") || key.hasPrefix("accessibility"):
            return .accessibilityLabel
        // Onboarding and habits assistant strings are descriptive text, not form fields
        case _ where key.hasPrefix("onboarding.") || key.hasPrefix("habits_assistant."):
            return .validationMessage
        // Location footers, instructions, and trigger descriptions are descriptive text
        case _ where key.hasPrefix("location.") && (lowercaseKey.contains("footer") ||
                                                     lowercaseKey.contains("instruction") ||
                                                     lowercaseKey.contains("description") ||
                                                     lowercaseKey.contains("when_to_notify")):
            return .validationMessage
        // Data management footers are descriptive text
        case _ where key.hasPrefix("data_management.") && lowercaseKey.contains("footer"):
            return .validationMessage
        // Recognize message/warning/error patterns as validation strings
        case _ where lowercaseKey.contains("message") ||
                     lowercaseKey.contains("warning") ||
                     lowercaseKey.contains("error") ||
                     lowercaseKey.contains("restriction") ||
                     key.contains("This will remove"):  // Confirmation dialogs
            return .validationMessage

        // ===== SPECIFIC LONG/LEGAL PATTERNS (must come before generic patterns) =====

        // Legal text - subscription terms, privacy text (very long, 500 chars)
        case _ where lowercaseKey.contains("subscriptionterms") ||
                     lowercaseKey.contains("privacypolicy") ||
                     lowercaseKey.contains("legaltext"):
            return .legalText
        // Category deactivate confirmations are longer (explain consequences)
        case _ where key.hasPrefix("category.deactivate.confirm"):
            return .longDescription
        // Long descriptions - empty states, detailed explanations
        case _ where lowercaseKey.contains("nocategoryhabits") ||
                     lowercaseKey.contains("emptystate") ||
                     key == "icloud.description" ||
                     key == "components.habitIconsDescription":
            return .longDescription

        // ===== GENERIC PATTERNS =====

        // Descriptive text patterns - footers, descriptions, explanations, info, intros
        case _ where lowercaseKey.contains("footer") ||
                     lowercaseKey.contains("description") ||
                     lowercaseKey.contains("explanation") ||
                     lowercaseKey.contains("intro") ||
                     lowercaseKey.hasSuffix(".desc") ||
                     lowercaseKey.hasSuffix("info") ||
                     lowercaseKey.contains("subtitle") ||
                     lowercaseKey.contains("detail"):
            return .validationMessage
        // Confirmation dialogs
        case _ where lowercaseKey.contains("confirm") ||
                     lowercaseKey.contains("dialog"):
            return .validationMessage
        // Paywall and subscription descriptive text
        case _ where (key.hasPrefix("paywall.") || key.hasPrefix("subscription.")) &&
                     (lowercaseKey.contains("terms") ||
                      lowercaseKey.contains("trial") ||
                      lowercaseKey.contains("header")):
            return .validationMessage
        // Timezone descriptive text
        case _ where key.hasPrefix("timezone") &&
                     (lowercaseKey.contains("footer") ||
                      lowercaseKey.contains("explanation") ||
                      lowercaseKey.contains("intro")):
            return .validationMessage
        // iCloud sync descriptions (not the main description, which is long)
        case _ where key.hasPrefix("icloud.") &&
                     (lowercaseKey.contains("footer") ||
                      lowercaseKey.contains("syncs")):
            return .validationMessage
        // Stats info and examples
        case _ where key.hasPrefix("stats.") &&
                     (lowercaseKey.contains("info") ||
                      lowercaseKey.contains("example") ||
                      lowercaseKey.contains("consider")):
            return .validationMessage
        // Components descriptions (not habitIconsDescription, which is long)
        case _ where key.hasPrefix("components.") &&
                     lowercaseKey.contains("desc") &&
                     !lowercaseKey.contains("iconsdescription"):
            return .validationMessage
        // Overview descriptive text
        case _ where key.hasPrefix("overview.") &&
                     (lowercaseKey.contains("description") ||
                      lowercaseKey.contains("explanation")):
            return .validationMessage
        // Habits descriptive text (not noCategoryHabitsDescription, which is long)
        case _ where key.hasPrefix("habits.") &&
                     (lowercaseKey.contains("accessibility") ||
                      lowercaseKey.contains("footer") ||
                      lowercaseKey.contains("startdate")):
            return .validationMessage
        case _ where key.hasPrefix("habits.") &&
                     lowercaseKey.contains("description") &&
                     !lowercaseKey.contains("nocategoryhabits"):
            return .validationMessage
        // Category confirmations and failures (not deactivate.confirm, which is long)
        case _ where key.hasPrefix("category.") &&
                     (lowercaseKey.contains("failed") ||
                      lowercaseKey.contains("subtitle")):
            return .validationMessage
        case _ where key.hasPrefix("category.") &&
                     lowercaseKey.contains("confirm") &&
                     !key.hasPrefix("category.deactivate.confirm"):
            return .validationMessage
        // Settings descriptions and hints
        case _ where (key.hasPrefix("settings") || key.hasPrefix("Settings")) &&
                     (lowercaseKey.contains("description") ||
                      lowercaseKey.contains("hint") ||
                      lowercaseKey.contains("intro")):
            return .validationMessage
        default:
            return .formFieldLabel // Default constraint
        }
    }
    
    private func validateString(key: String, value: String, constraint: StringConstraints) -> ValidationResult {
        var issues: [String] = []
        
        // Length validation
        if value.count > constraint.characterLimit {
            issues.append("Exceeds \(constraint.name.lowercased()) limit (\(value.count)/\(constraint.characterLimit))")
        }
        
        // Whitespace validation
        if value != value.trimmingCharacters(in: .whitespacesAndNewlines) {
            issues.append("Contains leading/trailing whitespace")
        }
        
        // Empty string validation
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append("String is empty")
        }
        
        // Line break validation (except for messages)
        if value.contains("\\n") && constraint.name != "Validation" {
            issues.append("Contains line breaks")
        }
        
        // Special format string validation
        if value.contains("%@") || value.contains("%lld") {
            // Count actual format specifiers (excluding escaped %%)
            // Match format specifiers like %@, %lld, %d, %ld, %s, %f, etc.
            // But NOT escaped %% (which is a literal percent sign)
            let pattern = "%(@|lld|ld|d|s|f|\\$\\d+\\$@|\\$\\d+\\$lld)"
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(value.startIndex..., in: value)
            let formatCount = regex?.numberOfMatches(in: value, range: range) ?? 0

            if formatCount > 4 {
                issues.append("Too many format specifiers (\(formatCount))")
            }
        }
        
        return ValidationResult(
            key: key,
            value: value,
            constraint: constraint,
            isValid: issues.isEmpty,
            issues: issues
        )
    }
    
    func generateReport(results: [ValidationResult]) -> String {
        var report = """
        🌍 Ritualist String Validation Report
        =====================================
        Generated: \(Date())
        
        """
        
        let totalCount = results.count
        let validCount = results.filter { $0.isValid }.count
        let invalidCount = totalCount - validCount
        
        report += """
        📊 Summary:
           Total strings: \(totalCount)
           ✅ Valid: \(validCount)
           ❌ Invalid: \(invalidCount)
           📈 Success rate: \(Int(Double(validCount) / Double(totalCount) * 100))%
        
        """
        
        // Group by constraint type
        let grouped = Dictionary(grouping: results) { $0.constraint.name }
        
        for (constraintName, constraintResults) in grouped.sorted(by: { $0.key < $1.key }) {
            let constraintValid = constraintResults.filter { $0.isValid }.count
            let constraintTotal = constraintResults.count
            
            report += """
            
            📱 \(constraintName) Strings (\(constraintValid)/\(constraintTotal) valid)
            \(String(repeating: "-", count: 50))
            
            """
            
            for result in constraintResults.sorted(by: { $0.key < $1.key }) {
                let status = result.isValid ? "✅" : "❌"
                let truncatedValue = result.value.count > 40 ? String(result.value.prefix(40)) + "..." : result.value
                
                report += "\(status) \(result.key): \"\(truncatedValue)\"\n"
                
                if !result.isValid {
                    for issue in result.issues {
                        report += "    ⚠️  \(issue)\n"
                    }
                }
            }
        }
        
        if invalidCount > 0 {
            report += """
            
            🔧 Recommended Actions:
            • Review strings marked with ❌ 
            • Consider shortening text for better UX
            • Test UI layouts with longer translations
            • Update String Catalog comments for context
            
            """
        } else {
            report += """
            
            🎉 All strings passed validation!
            Your localization is ready for translation.
            
            """
        }
        
        return report
    }
}

// MARK: - Main Execution
func main() {
    let validator = StringValidator()
    let catalogPath = "Ritualist/Resources/Localizable.xcstrings"
    
    print("🔍 Validating strings in: \(catalogPath)")
    
    let results = validator.validateStringCatalog(at: catalogPath)
    let report = validator.generateReport(results: results)
    
    print(report)
    
    // Write report to file
    let reportPath = "string_validation_report.txt"
    do {
        try report.write(toFile: reportPath, atomically: true, encoding: .utf8)
        print("📄 Report saved to: \(reportPath)")
    } catch {
        print("⚠️  Could not save report: \(error)")
    }
    
    // Exit with error code if validation failed
    let hasErrors = results.contains { !$0.isValid }
    exit(hasErrors ? 1 : 0)
}

main()