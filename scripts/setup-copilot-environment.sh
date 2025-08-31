#!/bin/bash

# GitHub Copilot Environment Setup Helper Script
# This script helps configure environment variables for GitHub Copilot agent

set -e

echo "🚀 GitHub Copilot Environment Setup Helper"
echo "=========================================="
echo ""
echo "This script will guide you through setting up environment variables"
echo "for GitHub Copilot agent to access your Azure OpenAI resources."
echo ""

# Function to validate URL format
validate_endpoint() {
    local endpoint="$1"
    if [[ $endpoint =~ ^https://[a-zA-Z0-9-]+\.openai\.azure\.com$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate API key format (basic check)
validate_api_key() {
    local key="$1"
    if [[ ${#key} -ge 30 && $key =~ ^[A-Za-z0-9+/=]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate deployment name
validate_deployment() {
    local deployment="$1"
    if [[ ${#deployment} -ge 1 && $deployment =~ ^[a-zA-Z0-9-]+$ ]]; then
        return 0
    else
        return 1
    fi
}

echo "📋 Environment Variable Collection"
echo "================================="
echo ""

# Collect Azure OpenAI Endpoint
while true; do
    echo "🔗 Azure OpenAI Endpoint"
    echo "   Example: https://your-resource.openai.azure.com"
    read -p "   Enter your endpoint URL: " ENDPOINT
    
    if validate_endpoint "$ENDPOINT"; then
        echo "   ✅ Valid endpoint format"
        break
    else
        echo "   ❌ Invalid format. Please use: https://your-resource.openai.azure.com"
        echo ""
    fi
done

echo ""

# Collect Azure OpenAI API Key
while true; do
    echo "🔑 Azure OpenAI API Key"
    echo "   This should be your Azure OpenAI service API key"
    read -s -p "   Enter your API key (hidden): " API_KEY
    echo ""  # New line after hidden input
    
    if [ -z "$API_KEY" ]; then
        echo "   ❌ API key cannot be empty"
        echo ""
        continue
    fi
    
    if validate_api_key "$API_KEY"; then
        echo "   ✅ API key format looks valid (length: ${#API_KEY} characters)"
        break
    else
        echo "   ⚠️  API key format may be invalid, but proceeding..."
        break
    fi
done

echo ""

# Collect Azure OpenAI Deployment
while true; do
    echo "🎯 Azure OpenAI Deployment Name"
    echo "   Example: gpt-4o, gpt-4, gpt-35-turbo"
    read -p "   Enter your deployment name: " DEPLOYMENT
    
    if validate_deployment "$DEPLOYMENT"; then
        echo "   ✅ Valid deployment name"
        break
    else
        echo "   ❌ Invalid format. Use only letters, numbers, and hyphens"
        echo ""
    fi
done

echo ""
echo "🎯 Configuration Summary"
echo "======================="
echo "Endpoint:    $ENDPOINT"
echo "Deployment:  $DEPLOYMENT"
echo "API Key:     [${#API_KEY} characters, hidden]"
echo ""

# Ask for confirmation
read -p "Is this configuration correct? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "❌ Setup cancelled"
    exit 1
fi

echo ""
echo "📋 GitHub Repository Setup Instructions"
echo "======================================="
echo ""
echo "To configure these environment variables for GitHub Copilot:"
echo ""
echo "1. Navigate to your repository on GitHub"
echo "2. Go to Settings > Environments"
echo "3. Create or select the 'copilot' environment"
echo "4. Add the following:"
echo ""
echo "   Environment Variables (non-sensitive):"
echo "   ✅ AZURE_OPENAI_ENDPOINT = $ENDPOINT"
echo "   ✅ AZURE_OPENAI_DEPLOYMENT = $DEPLOYMENT"
echo ""
echo "   Environment Secrets (sensitive):"
echo "   🔐 AZURE_OPENAI_API_KEY = [your API key]"
echo ""

# Generate environment file for local testing
echo "💾 Local Environment File"
echo "========================="
echo ""
read -p "Create a local .env file for testing? (y/N): " create_env
if [[ $create_env =~ ^[Yy]$ ]]; then
    cat > .env << EOF
# Azure OpenAI Configuration for Local Testing
# DO NOT COMMIT THIS FILE TO VERSION CONTROL
AZURE_OPENAI_ENDPOINT=$ENDPOINT
AZURE_OPENAI_API_KEY=$API_KEY
AZURE_OPENAI_DEPLOYMENT=$DEPLOYMENT
EOF
    
    # Add to .gitignore if not already there
    if ! grep -q "^\.env$" .gitignore 2>/dev/null; then
        echo ".env" >> .gitignore
        echo "   ✅ Added .env to .gitignore"
    fi
    
    echo "   ✅ Created .env file"
    echo "   ⚠️  Remember: Never commit .env to version control!"
    echo ""
    echo "   To use locally:"
    echo "   source .env && swift test --filter LiveAPITests"
fi

echo ""
echo "🧪 Validation"
echo "============="
echo ""
read -p "Run environment validation now? (y/N): " run_validation
if [[ $run_validation =~ ^[Yy]$ ]]; then
    echo ""
    if [ -f ".env" ]; then
        echo "Loading environment variables from .env..."
        export AZURE_OPENAI_ENDPOINT="$ENDPOINT"
        export AZURE_OPENAI_API_KEY="$API_KEY"
        export AZURE_OPENAI_DEPLOYMENT="$DEPLOYMENT"
    fi
    
    if [ -f "scripts/validate-copilot-environment.sh" ]; then
        ./scripts/validate-copilot-environment.sh
    else
        echo "❌ Validation script not found at scripts/validate-copilot-environment.sh"
    fi
fi

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "Next steps:"
echo "1. Configure the GitHub environment variables as shown above"
echo "2. Ensure .github/workflows/copilot-setup-steps.yml is committed to main branch"
echo "3. GitHub Copilot will now have access to your Azure OpenAI resources"
echo "4. Test with: swift test --filter LiveAPITests (when environment is configured)"
echo ""
echo "📚 For more information, see:"
echo "   - docs/COPILOT_ENVIRONMENT_SETUP.md"
echo "   - LIVE_API_TESTING.md"