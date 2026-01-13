#!/bin/bash
# Claude Code Stop hook - notify when waiting for input
set -euo pipefail

INPUT=$(cat)

SESSION_NAME=$(echo "$INPUT" | jq -r '.session_id // "Claude"')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')

# Extract the last assistant message from the transcript file (JSONL format)
LAST_MESSAGE=""
if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
    LAST_MESSAGE=$(tac "$TRANSCRIPT_PATH" | while read -r line; do
        msg_type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)
        if [[ "$msg_type" == "assistant" ]]; then
            echo "$line" | jq -r '.message.content // [] | map(select(.type == "text") | .text) | join("\n")' 2>/dev/null
            break
        fi
    done | head -c 500 || true)
fi

if [[ -z "$LAST_MESSAGE" ]]; then
    LAST_MESSAGE="(no message)"
fi

notify-send --app-name="Claude Code" "Waiting for input" "$LAST_MESSAGE"
