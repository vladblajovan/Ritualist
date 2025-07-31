#!/bin/bash

# Visual Regression Testing Script for Ritualist
# This script runs UI tests across different locales and device sizes
# to catch internationalization layout issues

set -e

# Colors for output
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m' # No Color

echo -e "${BLUE}🌍 Starting Visual Regression Tests for Internationalization${NC}"
echo "============================================================"

# Configuration
PROJECT_NAME="Ritualist"
SCHEME="Ritualist"
SIMULATOR_NAME="iPhone 15"
TEST_CLASS="LocaleScreenshotTests"
OUTPUT_DIR="./VisualRegressionResults"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Test configurations
declare -a LOCALES=("en" "de" "fr" "es" "ja" "ar")
declare -a DEVICE_SIZES=("iPhone 15" "iPhone 15 Plus" "iPad Air (5th generation)")
declare -a DYNAMIC_TYPE_SIZES=("UICTContentSizeCategoryL" "UICTContentSizeCategoryXXL" "UICTContentSizeCategoryAccessibilityM")

echo -e "${YELLOW}📱 Testing Locales:${NC} ${LOCALES[*]}"
echo -e "${YELLOW}📱 Testing Devices:${NC} ${DEVICE_SIZES[*]}"
echo -e "${YELLOW}🔤 Testing Dynamic Type:${NC} ${DYNAMIC_TYPE_SIZES[*]}"

# Function to run tests for a specific configuration
run_test_configuration() {
    local locale="$1"
    local device="$2"
    local dynamic_type="$3"
    local test_name="${locale}_${device// /_}_${dynamic_type}"
    
    echo -e "${BLUE}🧪 Testing: $test_name${NC}"
    
    # Build and test command
    xcodebuild \\
        -project "$PROJECT_NAME.xcodeproj" \\
        -scheme "$SCHEME" \\
        -destination "platform=iOS Simulator,name=$device" \\
        -testClass "$TEST_CLASS" \\
        test \\
        -resultBundlePath "$OUTPUT_DIR/$test_name.xcresult" \\
        OTHER_SWIFT_FLAGS="-D TESTING_LOCALE_$locale -D TESTING_DYNAMIC_TYPE_$dynamic_type" \\
        > "$OUTPUT_DIR/$test_name.log" 2>&1
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✅ $test_name passed${NC}"
        return 0
    else
        echo -e "${RED}❌ $test_name failed${NC}"
        echo -e "${RED}   Check log: $OUTPUT_DIR/$test_name.log${NC}"
        return 1
    fi
}

# Function to extract screenshots from test results
extract_screenshots() {
    echo -e "${BLUE}📸 Extracting screenshots...${NC}"
    
    for xcresult in "$OUTPUT_DIR"/*.xcresult; do
        if [ -d "$xcresult" ]; then
            local base_name=$(basename "$xcresult" .xcresult)
            local screenshot_dir="$OUTPUT_DIR/Screenshots/$base_name"
            mkdir -p "$screenshot_dir"
            
            # Extract screenshots using xcparse (if available) or custom extraction
            if command -v xcparse &> /dev/null; then
                xcparse screenshots "$xcresult" "$screenshot_dir"
            else
                echo -e "${YELLOW}⚠️  xcparse not found. Install with: brew install chargepoint/xcparse/xcparse${NC}"
            fi
        fi
    done
}

# Function to generate comparison report
generate_report() {
    echo -e "${BLUE}📊 Generating visual regression report...${NC}"
    
    local report_file="$OUTPUT_DIR/visual_regression_report.html"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Ritualist Visual Regression Test Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 40px; }
        .header { background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
        .test-group { margin: 30px 0; border: 1px solid #e9ecef; border-radius: 8px; }
        .test-group h3 { background: #e9ecef; margin: 0; padding: 15px; border-radius: 8px 8px 0 0; }
        .screenshot-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; padding: 20px; }
        .screenshot-item { text-align: center; }
        .screenshot-item img { max-width: 100%; height: auto; border: 1px solid #dee2e6; border-radius: 4px; }
        .status-pass { color: #28a745; }
        .status-fail { color: #dc3545; }
        .locale-badge { background: #007bff; color: white; padding: 2px 8px; border-radius: 12px; font-size: 0.8em; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🌍 Ritualist Visual Regression Test Report</h1>
        <p>Generated on: $(date)</p>
        <p>This report shows UI screenshots across different locales and device configurations to identify internationalization issues.</p>
    </div>
EOF

    # Add test results to report
    for locale in "${LOCALES[@]}"; do
        echo "    <div class=\"test-group\">" >> "$report_file"
        echo "        <h3><span class=\"locale-badge\">$locale</span> Locale Screenshots</h3>" >> "$report_file"
        echo "        <div class=\"screenshot-grid\">" >> "$report_file"
        
        # Find screenshots for this locale
        find "$OUTPUT_DIR/Screenshots" -name "*${locale}*" -type f -name "*.png" | head -10 | while read screenshot; do
            local screenshot_name=$(basename "$screenshot" .png)
            echo "            <div class=\"screenshot-item\">" >> "$report_file"
            echo "                <img src=\"Screenshots/$(basename "$(dirname "$screenshot")")/$(basename "$screenshot")\" alt=\"$screenshot_name\">" >> "$report_file"
            echo "                <p>$screenshot_name</p>" >> "$report_file"
            echo "            </div>" >> "$report_file"
        done
        
        echo "        </div>" >> "$report_file"
        echo "    </div>" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF
    <div class="test-group">
        <h3>📈 Test Summary</h3>
        <p>Review screenshots for:</p>
        <ul>
            <li>Text truncation or overflow</li>
            <li>Button and UI element alignment</li>
            <li>Proper RTL layout (Arabic)</li>
            <li>Dynamic Type scaling</li>
            <li>Cultural appropriateness of icons and colors</li>
        </ul>
    </div>
</body>
</html>
EOF

    echo -e "${GREEN}📄 Report generated: $report_file${NC}"
}

# Main execution
main() {
    local failed_tests=0
    local total_tests=0
    
    # Quick smoke test with English locale
    echo -e "${BLUE}🚀 Running smoke test...${NC}"
    if run_test_configuration "en" "$SIMULATOR_NAME" "UICTContentSizeCategoryL"; then
        echo -e "${GREEN}✅ Smoke test passed${NC}"
    else
        echo -e "${RED}❌ Smoke test failed - aborting full test suite${NC}"
        exit 1
    fi
    
    # Run comprehensive tests
    echo -e "${BLUE}🔄 Running comprehensive visual regression tests...${NC}"
    
    for locale in "${LOCALES[@]}"; do
        for device in "${DEVICE_SIZES[@]}"; do
            for dynamic_type in "${DYNAMIC_TYPE_SIZES[@]}"; do
                total_tests=$((total_tests + 1))
                
                if ! run_test_configuration "$locale" "$device" "$dynamic_type"; then
                    failed_tests=$((failed_tests + 1))
                fi
            done
        done
    done
    
    # Extract screenshots and generate report
    extract_screenshots
    generate_report
    
    # Summary
    echo ""
    echo -e "${BLUE}📊 Test Summary${NC}"
    echo "=============="
    echo -e "Total tests: $total_tests"
    echo -e "${GREEN}Passed: $((total_tests - failed_tests))${NC}"
    echo -e "${RED}Failed: $failed_tests${NC}"
    
    if [ $failed_tests -eq 0 ]; then
        echo -e "${GREEN}🎉 All visual regression tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}⚠️  Some tests failed. Check the logs and screenshots.${NC}"
        exit 1
    fi
}

# Check dependencies
check_dependencies() {
    if ! command -v xcodebuild &> /dev/null; then
        echo -e "${RED}❌ xcodebuild not found. Please install Xcode.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Dependencies check passed${NC}"
}

# Run the script
check_dependencies
main "$@"