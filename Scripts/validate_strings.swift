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
    static let formFieldLabel = StringConstraints(name: "Form Field", characterLimit: 30, pixelWidth: 200)
    static let validationMessage = StringConstraints(name: "Validation", characterLimit: 80, pixelWidth: 280)
    static let accessibilityLabel = StringConstraints(name: "Accessibility", characterLimit: 100, pixelWidth: 0)
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
            print("❌ Could not read String Catalog at: \\(path)")
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
        switch {
        case key.hasPrefix("navigation."):
            return .tabBarLabel
        case key.hasPrefix("button."):
            return .buttonLabel
        case key.hasPrefix("form."):
            return .formFieldLabel
        case key.hasPrefix("validation."):
            return .validationMessage
        case key.hasPrefix("accessibility."):
            return .accessibilityLabel
        default:
            return .formFieldLabel // Default constraint
        }
    }
    
    private func validateString(key: String, value: String, constraint: StringConstraints) -> ValidationResult {
        var issues: [String] = []
        
        // Length validation
        if value.count > constraint.characterLimit {
            issues.append("Exceeds \\(constraint.name.lowercased()) limit (\\(value.count)/\\(constraint.characterLimit))")
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
            // Ensure proper format specifier usage
            let formatCount = value.components(separatedBy: "%").count - 1
            if formatCount > 2 {
                issues.append("Too many format specifiers (\\(formatCount))")
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
        Generated: \\(Date())
        
        """
        
        let totalCount = results.count
        let validCount = results.filter { $0.isValid }.count
        let invalidCount = totalCount - validCount
        
        report += """
        📊 Summary:
           Total strings: \\(totalCount)
           ✅ Valid: \\(validCount)
           ❌ Invalid: \\(invalidCount)
           📈 Success rate: \\(Int(Double(validCount) / Double(totalCount) * 100))%
        
        """
        
        // Group by constraint type
        let grouped = Dictionary(grouping: results) { $0.constraint.name }
        
        for (constraintName, constraintResults) in grouped.sorted(by: { $0.key < $1.key }) {
            let constraintValid = constraintResults.filter { $0.isValid }.count
            let constraintTotal = constraintResults.count
            
            report += """
            
            📱 \\(constraintName) Strings (\\(constraintValid)/\\(constraintTotal) valid)
            \\(String(repeating: "-", count: 50))
            
            """
            
            for result in constraintResults.sorted(by: { $0.key < $1.key }) {
                let status = result.isValid ? "✅" : "❌"
                let truncatedValue = result.value.count > 40 ? String(result.value.prefix(40)) + "..." : result.value
                
                report += "\\(status) \\(result.key): \\"\\(truncatedValue)\\"\\n"
                
                if !result.isValid {
                    for issue in result.issues {
                        report += "    ⚠️  \\(issue)\\n"
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
    
    print("🔍 Validating strings in: \\(catalogPath)")
    
    let results = validator.validateStringCatalog(at: catalogPath)
    let report = validator.generateReport(results: results)
    
    print(report)
    
    // Write report to file
    let reportPath = "string_validation_report.txt"
    do {
        try report.write(toFile: reportPath, atomically: true, encoding: .utf8)
        print("📄 Report saved to: \\(reportPath)")
    } catch {
        print("⚠️  Could not save report: \\(error)")
    }
    
    // Exit with error code if validation failed
    let hasErrors = results.contains { !$0.isValid }
    exit(hasErrors ? 1 : 0)
}

main()