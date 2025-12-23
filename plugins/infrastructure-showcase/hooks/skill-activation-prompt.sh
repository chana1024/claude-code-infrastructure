#!/bin/bash
set -e

# Support both plugin mode (CLAUDE_PLUGIN_ROOT) and project mode (CLAUDE_PROJECT_DIR)
SCRIPT_DIR="${CLAUDE_PLUGIN_ROOT:-${CLAUDE_PROJECT_DIR:-.}}/hooks"
cd "$SCRIPT_DIR"
cat | npx tsx skill-activation-prompt.ts
