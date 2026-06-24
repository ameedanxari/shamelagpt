#!/usr/bin/env bash

# Setup AI Prompt Library integration for this project.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Setting up AI Prompt Library..."

echo ""
echo "[1/4] Initializing .ai-prompts submodule"
if git -C .ai-prompts rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo ".ai-prompts already initialized"
else
  git submodule update --init --recursive .ai-prompts
fi

echo ""
echo "[2/4] Installing prompt-library dependencies"
if [ -f ".ai-prompts/package-lock.json" ]; then
  npm --prefix .ai-prompts ci
else
  npm --prefix .ai-prompts install
fi

echo ""
echo "[3/4] Bootstrapping project steering"
if [ -f "AGENTS.md" ] && grep -q "AI Prompt Library Steering (Auto-Managed)" AGENTS.md; then
  echo "Project steering block already present"
  mkdir -p prompts/outputs/current prompts/working_copy prompts/archive
else
  bash .ai-prompts/scripts/bootstrap-project-integration.sh
fi

echo ""
echo "[4/4] Validating integration"
./validate-integration.sh

echo ""
echo "AI Prompt Library setup complete."
echo ""
echo "Current entry points:"
echo "- .ai-prompts/prompts/AGENTS.md"
echo "- .ai-prompts/prompts/orchestrators/ai-agent-entry-point.md"
echo "- .ai-prompts/prompts/orchestrators/drill-down-engine.md"
echo "- .ai-prompts/prompts/orchestrators/audit-and-remediate.md"
