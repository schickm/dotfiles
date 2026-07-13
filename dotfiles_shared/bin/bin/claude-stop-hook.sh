#!/bin/bash
# Claude Code Stop hook - notify when waiting for input.
#   * Only notifies when Claude's Kitty window is NOT focused.
#   * Left-click the notification -> focus that window in niri (switching to its
#     workspace) and select its Kitty pane.
#   * Right-click -> mako action menu; middle-click / `makoctl dismiss` -> dismiss
#     without focusing.
set -euo pipefail

INPUT=$(cat)

# --- Skip if Claude's Kitty window currently has keyboard focus ---
[[ -x "$HOME/bin/claude-window-focused.sh" ]] && "$HOME/bin/claude-window-focused.sh" && exit 0

TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')

# --- Last assistant message (the response that just finished) ---
# Take the text of the final assistant entry that appears AFTER the most recent
# user message, so we always get the current turn's response. The Stop hook can
# fire just before Claude Code finishes flushing that message to the transcript,
# so poll briefly (~2s) for it instead of falling back to the previous turn.
extract_last_response() {
    jq -rs '
        (map(.type == "user") | rindex(true)) as $lu
        | (if $lu == null then . else .[$lu + 1:] end)
        | [ .[] | select(.type == "assistant") ] | (last // null)
        | if . == null then ""
          else ((.message.content // []) | map(select(.type == "text") | .text) | join("\n"))
          end' "$1" 2>/dev/null || true
}

LAST_MESSAGE=""
if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
    for _ in $(seq 1 10); do
        LAST_MESSAGE=$(extract_last_response "$TRANSCRIPT_PATH")
        [[ -n "$LAST_MESSAGE" ]] && break
        sleep 0.2
    done
    LAST_MESSAGE=$(printf '%s' "$LAST_MESSAGE" | head -c 500)
fi
[[ -z "$LAST_MESSAGE" ]] && LAST_MESSAGE="(no message)"

# --- Conversation title (most recent ai-title) and working directory ---
TITLE=""
[[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]] && \
    TITLE=$(jq -rs 'map(select(.type == "ai-title") | .aiTitle) | last // empty' "$TRANSCRIPT_PATH" 2>/dev/null || true)

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[[ -z "$CWD" ]] && CWD="$PWD"
CWD_DISPLAY="${CWD/#$HOME/\~}"

# --- Workspace context + niri window id (click-to-focus) ---
# resolve_workspace_context sets WS_WINDOW_ID / WS_NAME / WS_COLOR / WS_TAG.
source "$(dirname "$(readlink -f "$0")")/workspace-lib.sh"
resolve_workspace_context "$CWD"
NIRI_ID="$WS_WINDOW_ID"

# Conversation name as the headline (helps tell apart multiple Claude windows);
# falls back to the generic label before a title has been generated. The
# workspace pill leading the body says where it came from.
SUMMARY="${TITLE:-Waiting for input}"
BODY="$(pango_escape "$LAST_MESSAGE")"$'\n\n'"📁 $(pango_escape "$CWD_DISPLAY")"
[[ -n "$WS_TAG" ]] && BODY="$WS_TAG"$'\n'"$BODY"

# --- Notify (detached so the hook never blocks) and handle the click ---
# The synchronous hint is per-workspace: a new stop notification replaces the
# previous one from the same workspace but leaves other workspaces' up.
export CLAUDE_SUMMARY="$SUMMARY"
export CLAUDE_BODY="$BODY"
export CLAUDE_NIRI_ID="$NIRI_ID"
export CLAUDE_CATEGORY="${WS_NAME:+ws-$WS_NAME}"
export CLAUDE_SYNC_KEY="claude-stop${WS_NAME:+-$WS_NAME}"
setsid bash -c '
    action=$(notify-send --app-name="Claude Code" \
        --action="default=Focus window" \
        -t 0 \
        ${CLAUDE_CATEGORY:+--category="$CLAUDE_CATEGORY"} \
        -h "string:x-canonical-private-synchronous:$CLAUDE_SYNC_KEY" \
        --wait \
        "$CLAUDE_SUMMARY" "$CLAUDE_BODY") || exit 0
    if [[ "$action" == "default" ]]; then
        [[ -n "${CLAUDE_NIRI_ID:-}" ]] && niri msg action focus-window --id "$CLAUDE_NIRI_ID" >/dev/null 2>&1 || true
        [[ -n "${KITTY_WINDOW_ID:-}" ]] && kitty @ focus-window --match "id:${KITTY_WINDOW_ID}" >/dev/null 2>&1 || true
    fi
' </dev/null >/dev/null 2>&1 &

exit 0
