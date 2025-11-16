#!/bin/bash

# Setup AI Prompt Library Integration
# This script initializes the .ai-prompts submodule and installs its dependencies

set -e

echo "🚀 Setting up AI Prompt Library..."
echo ""

# Step 1: Initialize git submodule
echo "📦 Step 1: Initializing git submodule..."
if [ ! -f ".ai-prompts/.git" ]; then
    git submodule init
    git submodule update --remote
    echo "✓ Submodule initialized"
else
    echo "✓ Submodule already initialized"
fi

# Step 2: Verify submodule is cloned
echo ""
echo "📂 Step 2: Verifying submodule clone..."
if [ ! -d ".ai-prompts/node_modules" ]; then
    echo "   Installing npm dependencies in .ai-prompts..."
    cd .ai-prompts
    npm install
    cd ..
    echo "✓ Dependencies installed"
else
    echo "✓ Dependencies already installed"
fi

# Step 3: Verify critical files
echo ""
echo "🔍 Step 3: Verifying library structure..."
required_files=(
    ".ai-prompts/package.json"
    ".ai-prompts/prompts/orchestrators/execution-orchestrator.md"
    ".ai-prompts/PREVENTION_CHECKLIST.md"
    ".ai-prompts/COMMIT_GUIDELINES.md"
)

all_present=true
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✓ $file"
    else
        echo "   ✗ MISSING: $file"
        all_present=false
    fi
done

if [ "$all_present" = false ]; then
    echo ""
    echo "⚠️  Some library files are missing. Try:"
    echo "   git submodule update --remote"
    echo "   git submodule update --init --recursive"
    exit 1
fi

# Step 4: Setup hooks
echo ""
echo "⚙️  Step 4: Setting up git hooks..."
if [ -f ".ai-prompts/.husky" ]; then
    echo "   Linking husky hooks from ai-prompt-library..."
    # Note: husky manages hooks automatically during npm install
    echo "✓ Hooks configured"
else
    echo "   ℹ️  No husky configuration found"
fi

echo ""
echo "✨ AI Prompt Library setup complete!"
echo ""
echo "Next steps:"
echo "1. Read the PREVENTION_CHECKLIST.md before making changes"
echo "2. Invoke the Execution Orchestrator:"
echo "   prompts/orchestrators/execution-orchestrator.md"
echo "3. Use the Task Prompt Template for code generation:"
echo "   .ai-prompts/prompts/templates/task-prompt-template.md"
echo ""
echo "📖 Documentation:"
echo "   .ai-prompts/README.md         - Library overview"
echo "   .ai-prompts/CONTRIBUTING.md   - Development guidelines"
echo "   .ai-prompts/docs/SAFEGUARDS.md - Protection framework"
