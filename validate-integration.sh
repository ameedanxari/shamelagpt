#!/usr/bin/env bash
set -euo pipefail

if [ ! -x ".ai-prompts/scripts/validate-project-integration.sh" ]; then
  echo "❌ Missing .ai-prompts/scripts/validate-project-integration.sh"
  echo "Run setup again or update the AI Prompt Library."
  exit 1
fi

# Bootstrap has already been applied for this project. Keep the wrapper in
# verification mode so repeated local validation does not rewrite steering.
exec ./.ai-prompts/scripts/validate-project-integration.sh --no-fix "$@"
