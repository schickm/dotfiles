#!/bin/bash
# Claude Code PermissionRequest hook
# Uses notify-send actions with mako's fuzzel integration
set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "Unknown"')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}')

# Format display based on tool type
case "$TOOL_NAME" in
    Bash)
        DISPLAY=$(echo "$TOOL_INPUT" | jq -r '.command // "N/A"' | head -c 200)
        ;;
    Write|Edit|Read)
        DISPLAY=$(echo "$TOOL_INPUT" | jq -r '.file_path // "N/A"')
        ;;
    *)
        DISPLAY=$(echo "$TOOL_INPUT" | jq -c '.' | head -c 200)
        ;;
esac

# Send notification with actions, wait for response
# Right-click notification to select via fuzzel (mako config)
ACTION=$(notify-send --app-name="Claude Code" \
    --action="allow=Allow" \
    --action="deny=Deny" \
    --wait \
    "Permission: $TOOL_NAME" "$DISPLAY")

# Return decision as JSON
case "$ACTION" in
    allow)
        jq -n '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
        ;;
    deny)
        jq -n '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"deny"}}}'
        ;;
    *)
        # No decision - fall back to CLI prompt
        exit 0
        ;;
esac
