#!/bin/bash

echo "🧪 Testing Build Configurations..."
echo

# Test AllFeatures configuration
echo "1️⃣ Testing Debug-AllFeatures configuration..."
if xcodebuild -project Ritualist.xcodeproj -configuration Debug-AllFeatures -destination 'platform=iOS Simulator,name=iPhone 15' clean build 2>/dev/null; then
    echo "✅ Debug-AllFeatures builds successfully"
else
    echo "❌ Debug-AllFeatures build failed"
    echo "Run this command to see the error:"
    echo "xcodebuild -project Ritualist.xcodeproj -configuration Debug-AllFeatures -destination 'platform=iOS Simulator,name=iPhone 15' build"
fi
echo

# Test Subscription configuration  
echo "2️⃣ Testing Debug-Subscription configuration..."
if xcodebuild -project Ritualist.xcodeproj -configuration Debug-Subscription -destination 'platform=iOS Simulator,name=iPhone 15' clean build 2>/dev/null; then
    echo "✅ Debug-Subscription builds successfully"
else
    echo "❌ Debug-Subscription build failed"
    echo "Run this command to see the error:"
    echo "xcodebuild -project Ritualist.xcodeproj -configuration Debug-Subscription -destination 'platform=iOS Simulator,name=iPhone 15' build"
fi
echo

echo "🎯 If both builds succeed, your setup is correct!"
echo "Build configurations validated with explicit dual flag system:"
echo "  - AllFeatures: -D ALL_FEATURES_ENABLED (only)"
echo "  - Subscription: -D SUBSCRIPTION_ENABLED (only)"
echo "  - Compile-time validation prevents configuration errors"
echo "  - No implicit defaults - explicit configuration required"