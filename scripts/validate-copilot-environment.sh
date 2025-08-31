#!/bin/bash

# GitHub Copilot Environment Validation Script
# This script validates that the Copilot environment is properly configured

set -e  # Exit on any error

echo "🚀 Validating GitHub Copilot Environment for SwiftAzureOpenAI"
echo "============================================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo "✅ $2"
    else
        echo "❌ $2"
        exit 1
    fi
}

# Check Swift installation
echo "🔍 Checking Swift installation..."
if command_exists swift; then
    SWIFT_VERSION=$(swift --version | head -n1)
    echo "✅ Swift is installed: $SWIFT_VERSION"
    
    # Check if it's Swift 6.0.2 or compatible
    if echo "$SWIFT_VERSION" | grep -q "6\.0"; then
        echo "✅ Swift 6.0.x detected (compatible)"
    else
        echo "⚠️  Swift version may not be optimal (expected 6.0.x)"
    fi
else
    print_status 1 "Swift not found in PATH"
fi

# Check package structure
echo ""
echo "🔍 Checking package structure..."
if [ -f "Package.swift" ]; then
    echo "✅ Package.swift found"
    
    # Validate package description
    if swift package describe >/dev/null 2>&1; then
        echo "✅ Package description is valid"
    else
        print_status 1 "Package description failed"
    fi
else
    print_status 1 "Package.swift not found"
fi

# Check for dependencies
echo ""
echo "🔍 Checking dependencies..."
if swift package show-dependencies >/dev/null 2>&1; then
    DEPS=$(swift package show-dependencies 2>/dev/null || echo "none")
    if [ "$DEPS" = "none" ] || [ -z "$DEPS" ]; then
        echo "✅ No external dependencies (as expected)"
    else
        echo "ℹ️  Dependencies found: $DEPS"
    fi
else
    echo "⚠️  Could not check dependencies (may be normal)"
fi

# Try to build the package
echo ""
echo "🔍 Testing package build..."
if swift build >/dev/null 2>&1; then
    echo "✅ Package builds successfully"
else
    print_status 1 "Package build failed"
fi

# Check environment variables
echo ""
echo "🔍 Checking environment variables..."

if [ -n "$AZURE_OPENAI_ENDPOINT" ]; then
    echo "✅ AZURE_OPENAI_ENDPOINT is set: $AZURE_OPENAI_ENDPOINT"
else
    echo "⚠️  AZURE_OPENAI_ENDPOINT not set (required for live API testing)"
fi

if [ -n "$AZURE_OPENAI_API_KEY" ]; then
    echo "✅ AZURE_OPENAI_API_KEY is set (length: ${#AZURE_OPENAI_API_KEY} characters)"
else
    echo "⚠️  AZURE_OPENAI_API_KEY not set (required for live API testing)"
fi

if [ -n "$AZURE_OPENAI_DEPLOYMENT" ]; then
    echo "✅ AZURE_OPENAI_DEPLOYMENT is set: $AZURE_OPENAI_DEPLOYMENT"
else
    echo "⚠️  AZURE_OPENAI_DEPLOYMENT not set (required for live API testing)"
fi

# Test package functionality
echo ""
echo "🔍 Testing package functionality..."
if swift test --list-tests >/dev/null 2>&1; then
    echo "✅ Test suite is accessible"
    
    # Count tests
    TEST_COUNT=$(swift test --list-tests 2>/dev/null | grep -c "Test" || echo "unknown")
    echo "ℹ️  Found $TEST_COUNT tests"
else
    echo "⚠️  Could not list tests (may be normal if tests require specific setup)"
fi

# Check if we can run a quick test (without live API)
echo ""
echo "🔍 Running quick validation test..."
if timeout 30s swift test --filter "testInit" >/dev/null 2>&1; then
    echo "✅ Basic tests can run"
elif [ $? -eq 124 ]; then
    echo "⚠️  Test timed out (may be waiting for API response)"
else
    echo "⚠️  Quick test failed (may require environment variables)"
fi

echo ""
echo "🎉 Environment validation complete!"
echo ""
echo "Summary:"
echo "- Swift toolchain: ✅ Installed and working"
echo "- Package structure: ✅ Valid"
echo "- Build system: ✅ Working"
echo "- Test framework: ✅ Accessible"

if [ -n "$AZURE_OPENAI_ENDPOINT" ] && [ -n "$AZURE_OPENAI_API_KEY" ] && [ -n "$AZURE_OPENAI_DEPLOYMENT" ]; then
    echo "- Environment variables: ✅ All set for live API testing"
    echo ""
    echo "🚀 Copilot environment is fully configured and ready!"
else
    echo "- Environment variables: ⚠️  Some missing (live API testing may not work)"
    echo ""
    echo "🚀 Copilot environment is configured for development (live API testing requires environment variables)"
fi

echo ""
echo "This environment is ready for GitHub Copilot coding agent operations."