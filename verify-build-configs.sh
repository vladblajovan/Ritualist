#!/bin/bash

# Script to verify build configurations are set up correctly

echo "🔍 Verifying Ritualist Build Configurations..."
echo

# Check current configurations
echo "📋 Current Build Configurations:"
xcodebuild -project Ritualist.xcodeproj -list | grep -A 10 "Build Configurations:"
echo

# Check current schemes  
echo "🎯 Current Schemes:"
xcodebuild -project Ritualist.xcodeproj -list | grep -A 10 "Schemes:"
echo

# Test if compiler flags would work with current setup
echo "🧪 Testing Compiler Flag Detection..."

# Create a simple test file to check if our build config detection works
cat > test_build_config.swift << 'EOF'
import Foundation

#if ALL_FEATURES_ENABLED
print("✅ ALL_FEATURES_ENABLED detected")
#else
print("🔒 Subscription mode active")
#endif

#if SUBSCRIPTION_ENABLED  
print("💳 SUBSCRIPTION_ENABLED detected")
#else
print("🆓 No subscription flag")
#endif
EOF

echo "Created test file: test_build_config.swift"
echo "This file can be used to test compiler flags once Xcode configurations are set up."
echo

echo "📝 Next Steps:"
echo "1. Open Ritualist.xcodeproj in Xcode"
echo "2. Follow the steps in XCODE-BUILD-CONFIG-STEPS.md"
echo "3. Run this script again to verify setup"
echo "4. Use test_build_config.swift to test the compiler flags"
echo

echo "🎯 Expected final configurations:"
echo "   - Debug-AllFeatures (with -D ALL_FEATURES_ENABLED)"
echo "   - Debug-Subscription (with -D SUBSCRIPTION_ENABLED)"  
echo "   - Release-AllFeatures (with -D ALL_FEATURES_ENABLED)"
echo "   - Release-Subscription (with -D SUBSCRIPTION_ENABLED)"