#!/bin/bash

# Quick Coverage Report for Ritualist
# Uses most recent xcresult bundle to show coverage

set -e

# Find the most recent test result bundle
XCRESULT_PATH=$(find ~/Library/Developer/Xcode/DerivedData/Ritualist-*/Logs/Test -name "*.xcresult" | sort -r | head -1)

if [[ -z "$XCRESULT_PATH" ]]; then
    echo "❌ No test results found. Run tests first with: xcodebuild test -scheme Ritualist -enableCodeCoverage YES"
    exit 1
fi

echo "📊 Coverage Report from: $(basename "$XCRESULT_PATH")"
echo "==========================================="

# Overall app coverage
echo "🏆 Overall App Coverage:"
xcrun xccov view --report "$XCRESULT_PATH" | grep "Ritualist.app" | head -1

echo ""
echo "🎯 Key Files Coverage:"

# DateUtils coverage
DATEUTILS_LINE=$(xcrun xccov view --report "$XCRESULT_PATH" | grep "DateUtils.swift" | head -1)
if [[ -n "$DATEUTILS_LINE" ]]; then
    echo "   📅 DateUtils.swift: $(echo "$DATEUTILS_LINE" | awk '{print $2}')"
    PERCENTAGE=$(echo "$DATEUTILS_LINE" | awk '{print $2}' | sed 's/%.*$//')
    if (( $(echo "$PERCENTAGE >= 90" | bc -l) )); then
        echo "      ✅ Meets 90% target!"
    else
        echo "      ⚠️  Below 90% target"
    fi
else
    echo "   ❓ DateUtils.swift: Not found"
fi

# NumberUtils coverage (it's part of DateUtils.swift)
echo ""
echo "🔢 NumberUtils Functions Coverage:"
xcrun xccov view --report "$XCRESULT_PATH" | grep -A 8 "static NumberUtils" | grep "100.00%" | wc -l | xargs echo "   Functions with 100% coverage:"

echo ""
echo "📈 Top 5 Best Covered Files:"
xcrun xccov view --report "$XCRESULT_PATH" | grep "\.swift" | grep -v "0.00%" | sort -k2 -nr | head -5

echo ""
echo "⚠️  Bottom 5 Files Needing Coverage:"
xcrun xccov view --report "$XCRESULT_PATH" | grep "\.swift" | grep "0.00%" | head -5

echo ""
echo "💡 To see detailed coverage for a specific file:"
echo "   xcrun xccov view --report '$XCRESULT_PATH' | grep -A 20 'YourFile.swift'"