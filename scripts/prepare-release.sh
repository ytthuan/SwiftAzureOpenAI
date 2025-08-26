#!/bin/bash

# SwiftAzureOpenAI Release Preparation Script
# This script validates the package is ready for release

set -e

echo "🚀 SwiftAzureOpenAI Release Preparation"
echo "======================================="

# 1. Verify Swift version
echo "1. Checking Swift version..."
SWIFT_VERSION=$(swift --version | head -n1)
echo "   ✅ $SWIFT_VERSION"

# 2. Package validation
echo -e "\n2. Validating package structure..."
swift package describe > /dev/null
echo "   ✅ Package structure is valid"

# 3. Check for external dependencies
echo -e "\n3. Checking dependencies..."
DEPS=$(swift package show-dependencies)
if [[ "$DEPS" == "No external dependencies found" ]]; then
    echo "   ✅ No external dependencies (as expected)"
else
    echo "   ❌ Unexpected external dependencies found:"
    echo "$DEPS"
    exit 1
fi

# 4. Clean build
echo -e "\n4. Performing clean build..."
swift package clean
swift build --configuration release > /dev/null
echo "   ✅ Release build successful"

# 5. Run comprehensive tests
echo -e "\n5. Running comprehensive test suite..."
TEST_OUTPUT=$(swift test --configuration release 2>&1)
if echo "$TEST_OUTPUT" | grep -q "Test Suite 'All tests' passed"; then
    TEST_COUNT=$(echo "$TEST_OUTPUT" | grep "Executed.*tests" | tail -1 | awk '{print $2}')
    echo "   ✅ All $TEST_COUNT tests passed"
else
    echo "   ❌ Some tests failed:"
    echo "$TEST_OUTPUT"
    exit 1
fi

# 6. Check for warnings
echo -e "\n6. Checking for build warnings..."
BUILD_OUTPUT=$(swift build 2>&1)
if echo "$BUILD_OUTPUT" | grep -i "warning"; then
    echo "   ❌ Build warnings found:"
    echo "$BUILD_OUTPUT" | grep -i "warning"
    exit 1
else
    echo "   ✅ No build warnings"
fi

# 7. Validate README examples
echo -e "\n7. Validating package information..."
if [[ -f "README.md" ]]; then
    echo "   ✅ README.md exists"
else
    echo "   ❌ README.md not found"
    exit 1
fi

if [[ -f "LICENSE" ]]; then
    echo "   ✅ LICENSE file exists"
else
    echo "   ❌ LICENSE file not found"
    exit 1
fi

# 8. Package summary
echo -e "\n8. Package Summary:"
echo "   • Name: SwiftAzureOpenAI"
echo "   • Swift Tools Version: 6.0"
echo "   • Dependencies: None"
echo "   • Test Coverage: $TEST_COUNT tests"
echo "   • Platforms: iOS 13.0+, macOS 10.15+, watchOS 6.0+, tvOS 13.0+"

echo -e "\n🎉 Package is ready for release!"
echo -e "\nTo create a release:"
echo "1. Create and push a version tag: git tag v1.0.0 && git push origin v1.0.0"
echo "2. GitHub Actions will automatically create a release"
echo "3. Users can add the package via: https://github.com/ytthuan/SwiftAzureOpenAI"

echo -e "\nPackage URL for Swift Package Manager:"
echo "https://github.com/ytthuan/SwiftAzureOpenAI"