#!/bin/bash

# Coverage Report Script for Ritualist
# Usage: ./scripts/coverage-report.sh [--json] [--file <specific_file>]

set -e

PROJECT_DIR="$(dirname "$0")/.."
cd "$PROJECT_DIR"

# Default values
OUTPUT_FORMAT="text"
SPECIFIC_FILE=""
SCHEME="Ritualist"
DESTINATION="platform=iOS Simulator,name=iPhone 16"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            OUTPUT_FORMAT="json"
            shift
            ;;
        --file)
            SPECIFIC_FILE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--json] [--file <specific_file>]"
            echo "  --json       Output coverage data in JSON format"
            echo "  --file FILE  Show coverage for specific file"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "🧪 Running tests with code coverage..."

# Run tests with coverage enabled
xcodebuild test \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -enableCodeCoverage YES \
    -quiet

# Find the most recent test result bundle
XCRESULT_PATH=$(find ~/Library/Developer/Xcode/DerivedData/Ritualist-*/Logs/Test -name "*.xcresult" | sort -r | head -1)

if [[ -z "$XCRESULT_PATH" ]]; then
    echo "❌ No test results found. Make sure tests ran successfully."
    exit 1
fi

echo "📊 Generating coverage report from: $(basename "$XCRESULT_PATH")"

if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    # JSON output for programmatic use
    if [[ -n "$SPECIFIC_FILE" ]]; then
        xcrun xccov view --report --json "$XCRESULT_PATH" | jq --arg file "$SPECIFIC_FILE" '.targets[] | select(.name == "Ritualist.app") | .files[] | select(.path | contains($file))'
    else
        xcrun xccov view --report --json "$XCRESULT_PATH"
    fi
else
    # Human-readable text output
    if [[ -n "$SPECIFIC_FILE" ]]; then
        echo "📄 Coverage for files containing '$SPECIFIC_FILE':"
        xcrun xccov view --report "$XCRESULT_PATH" | grep -A 50 -B 5 "$SPECIFIC_FILE" || echo "File not found in coverage report"
    else
        echo "📈 Overall Coverage Summary:"
        xcrun xccov view --report "$XCRESULT_PATH" | head -20
        
        echo ""
        echo "🎯 Coverage by Target:"
        xcrun xccov view --report "$XCRESULT_PATH" | grep -E "(\.app|\.framework)" | head -10
        
        # Extract overall percentage for main app
        OVERALL_COVERAGE=$(xcrun xccov view --report "$XCRESULT_PATH" | grep "Ritualist.app" | head -1 | awk '{print $2}')
        echo ""
        echo "🏆 Main App Coverage: $OVERALL_COVERAGE"
        
        # Check if we meet the 90% target for DateUtils
        echo ""
        echo "🧮 DateUtils Coverage Check:"
        DATEUTILS_COVERAGE=$(xcrun xccov view --report "$XCRESULT_PATH" | grep "DateUtils.swift" | awk '{print $2}' | head -1)
        if [[ -n "$DATEUTILS_COVERAGE" ]]; then
            echo "   DateUtils.swift: $DATEUTILS_COVERAGE"
            # Extract percentage number for comparison
            PERCENTAGE=$(echo "$DATEUTILS_COVERAGE" | sed 's/%.*$//')
            if (( $(echo "$PERCENTAGE >= 90" | bc -l) )); then
                echo "   ✅ DateUtils meets 90% coverage target!"
            else
                echo "   ⚠️  DateUtils below 90% target (current: $DATEUTILS_COVERAGE)"
            fi
        else
            echo "   ❓ DateUtils not found in coverage report"
        fi
    fi
fi

echo ""
echo "✅ Coverage report complete!"
echo "💡 To view detailed coverage in Xcode:"
echo "   xed '$XCRESULT_PATH'"