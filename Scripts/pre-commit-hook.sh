#!/bin/bash
# Pre-commit hook to validate strings before allowing commit
#
# Installation:
#   cp Scripts/pre-commit-hook.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit

# Only run if Localizable.xcstrings was modified
if git diff --cached --name-only | grep -q "Localizable.xcstrings"; then
    echo "🔍 Validating strings before commit..."

    # Run the validation script
    if swift Scripts/validate_strings.swift > /tmp/string_validation.log 2>&1; then
        echo "✅ String validation passed!"
        rm /tmp/string_validation.log
    else
        echo "❌ String validation FAILED!"
        echo ""
        cat /tmp/string_validation.log
        echo ""
        echo "Fix the validation errors before committing."
        echo "Run: swift Scripts/validate_strings.swift"
        rm /tmp/string_validation.log
        exit 1
    fi
fi

exit 0
