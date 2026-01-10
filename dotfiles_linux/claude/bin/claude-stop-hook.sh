#!/bin/bash
# Claude Code Stop hook - notify when waiting for input
set -euo pipefail

INPUT=$(cat)

SESSION_NAME=$(echo "$INPUT" | jq -r '.session_id // "Claude"')

notify-send --app-name="Claude Code" "Waiting for input" "$SESSION_NAME"
