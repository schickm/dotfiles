#!/bin/bash
# Claude Code PermissionRequest hook
# Uses notify-send actions with mako's fuzzel integration
set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "Unknown"')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}')
SUGGESTION=$(echo "$INPUT" | jq -c '.permission_suggestions[0] // empty')

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

# Build notification actions
ACTIONS=(--action="allow=Allow once" --action="deny=Deny")
if [[ -n "$SUGGESTION" ]]; then
    ACTIONS=(--action="allow=Allow once" --action="always=Allow always" --action="deny=Deny")
fi

# Send notification with actions, wait for response
ACTION=$(notify-send --app-name="Claude Code" \
    "${ACTIONS[@]}" \
    --wait \
    "Permission: $TOOL_NAME" "$DISPLAY")

# Return decision as JSON
case "$ACTION" in
    allow)
        jq -n '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
        ;;
    always)
        jq -n --argjson rule "$SUGGESTION" '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow","ruleToAdd":$rule}}}'
        ;;
    deny)
        jq -n '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"deny"}}}'
        ;;
    *)
        # No decision - fall back to CLI prompt
        exit 0
        ;;
esac
