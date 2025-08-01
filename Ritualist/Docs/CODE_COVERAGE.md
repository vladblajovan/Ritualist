# Code Coverage Automation

This document describes automated ways to get code coverage percentages for the Ritualist iOS project.

## Quick Coverage Check

Use the provided script for a quick coverage overview:

```bash
./scripts/quick-coverage.sh
```

## Automated Coverage Methods

### Method 1: Command Line with xcodebuild

Run tests with coverage enabled:

```bash
xcodebuild test \
    -scheme Ritualist \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -enableCodeCoverage YES
```

Extract coverage report:

```bash
# Find the most recent test result
XCRESULT=$(find ~/Library/Developer/Xcode/DerivedData/Ritualist-*/Logs/Test -name "*.xcresult" | sort -r | head -1)

# Generate coverage report
xcrun xccov view --report "$XCRESULT"

# Get specific file coverage
xcrun xccov view --report "$XCRESULT" | grep -A 10 "DateUtils.swift"

# JSON output for programmatic use
xcrun xccov view --report --json "$XCRESULT"
```

### Method 2: Xcode IDE

1. Open Xcode
2. Go to **Product** → **Scheme** → **Edit Scheme**
3. Select **Test** tab
4. Check **Code Coverage**
5. Run tests (⌘+U)
6. View coverage in **Report Navigator** → **Coverage** tab

### Method 3: CI/CD Integration

For GitHub Actions or similar:

```yaml
- name: Run Tests with Coverage
  run: |
    xcodebuild test \
      -scheme Ritualist \
      -destination 'platform=iOS Simulator,name=iPhone 16' \
      -enableCodeCoverage YES \
      -resultBundlePath TestResults.xcresult

- name: Generate Coverage Report
  run: |
    xcrun xccov view --report TestResults.xcresult > coverage-report.txt
    
    # Extract overall percentage
    COVERAGE=$(xcrun xccov view --report TestResults.xcresult | grep "Ritualist.app" | awk '{print $2}')
    echo "Overall Coverage: $COVERAGE"
```

## Current Coverage Results

As of August 1, 2025:

### DateUtils.swift: **94.95%** ✅
- **Target**: 90%+ coverage
- **Result**: Exceeds target by 4.95%
- **Lines covered**: 94/99

### NumberUtils Functions: **100%** ✅
- `habitValueFormatter()`: 100%
- `formatHabitValue()`: 100%  
- `formatHabitValueWithUnit()`: 100%
- `parseHabitValue()`: 100%
- `percentageFormatter()`: 100%
- `formatPercentage()`: 100%

### Overall App: **6.81%**
- **Lines covered**: 1,372/20,150
- **Note**: This is expected for a new project with comprehensive utility testing

## Coverage Analysis Tools

### Built-in Xcode Tools
- **Coverage Report**: Shows line-by-line coverage
- **Coverage Data**: Highlight uncovered lines in source editor
- **Coverage Timeline**: Track coverage changes over time

### Third-party Tools
- **Codecov**: Cloud coverage reporting
- **SonarQube**: Code quality and coverage analysis
- **Slather**: Coverage reports for iOS

## Coverage Targets

| Component | Target | Current | Status |
|-----------|--------|---------|--------|
| DateUtils | 90%+ | 94.95% | ✅ Met |
| NumberUtils | 90%+ | 100% | ✅ Met |
| Core Utilities | 80%+ | TBD | 🎯 Goal |
| Overall App | 70%+ | 6.81% | 🚧 In Progress |

## Best Practices

1. **Run coverage regularly**: After each significant change
2. **Focus on critical paths**: Prioritize business logic and utilities
3. **Set realistic targets**: 90% for utilities, 70% for UI code
4. **Use coverage gaps**: As a guide for writing new tests
5. **Monitor trends**: Track coverage changes over time

## Troubleshooting

### Common Issues

1. **"No coverage data found"**
   - Ensure `-enableCodeCoverage YES` flag is used
   - Check that tests actually run and pass

2. **"Old coverage data"**
   - Clean derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/Ritualist-*`
   - Run fresh test suite

3. **"Coverage report empty"**
   - Verify test target includes the files you want to measure
   - Check scheme settings for code coverage

### Script Debugging

Enable verbose output:
```bash
# Debug the coverage script
bash -x ./scripts/quick-coverage.sh
```