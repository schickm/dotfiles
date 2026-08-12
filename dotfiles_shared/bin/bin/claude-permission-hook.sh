#!/bin/bash
# Claude Code PermissionRequest hook
# Uses notify-send actions with mako's fuzzel integration
set -euo pipefail

INPUT=$(cat)

# --- Flag the workspace "needs attention" while a permission prompt is up ---
# (whether it ends up as the CLI prompt or our notification). The focused/CLI
# path can't observe the answer; workspace-activity's PreToolUse/Stop events
# naturally clear the flag once the tool runs or the turn ends.
[[ -x "$HOME/bin/workspace-activity" ]] && \
    printf '%s' "$INPUT" | "$HOME/bin/workspace-activity" hook permission-start || true

# --- Skip if Claude's Kitty window currently has keyboard focus ---
# Exiting 0 with no output defers to the normal CLI permission prompt.
[[ -x "$HOME/bin/claude-window-focused.sh" ]] && "$HOME/bin/claude-window-focused.sh" && exit 0

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

# --- Workspace context (sets WS_WINDOW_ID / WS_NAME / WS_COLOR / WS_TAG) ---
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
source "$(dirname "$(readlink -f "$0")")/workspace-lib.sh"
resolve_workspace_context "$CWD"

SUMMARY="Permission: $TOOL_NAME"
BODY=$(pango_escape "$DISPLAY")
[[ -n "$WS_TAG" ]] && BODY="$WS_TAG"$'\n'"$BODY"

# Build notification actions
ACTIONS=(--action="allow=Allow once" --action="deny=Deny")
if [[ -n "$SUGGESTION" ]]; then
    ACTIONS=(--action="allow=Allow once" --action="always=Allow always" --action="deny=Deny")
fi
[[ -n "$WS_NAME" ]] && ACTIONS+=(--category="ws-$WS_NAME")

# Send notification with actions, wait for response.
#
# `-p` prints the notification id immediately and `--wait` prints the invoked
# action when it closes, so read them off the same pipe in turn instead of
# capturing everything at the end — the id is only useful while the
# notification is still up. Registering it lets mako-focus-dismiss dismiss the
# notification when this window is focused, which reads here as "no action" and
# falls through to the in-terminal prompt: the right outcome, since the
# terminal is what you just focused.
exec 3< <(notify-send --app-name="Claude Code" \
    "${ACTIONS[@]}" \
    -p --wait \
    "$SUMMARY" "$BODY")
read -r NOTIF_ID <&3 || NOTIF_ID=""
register_claude_notification "$NOTIF_ID" "${WS_WINDOW_ID:-}"
read -r ACTION <&3 || ACTION=""
unregister_claude_notification "$NOTIF_ID"

# Prompt answered -> workspace drops back to plain "busy" (the turn continues
# with the decision either way). On dismissal we fall through to the CLI
# prompt instead, so the attention flag stays up until PreToolUse/Stop.
case "$ACTION" in
    allow|always|deny)
        [[ -x "$HOME/bin/workspace-activity" ]] && \
            printf '%s' "$INPUT" | "$HOME/bin/workspace-activity" hook permission-end || true
        ;;
esac

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
