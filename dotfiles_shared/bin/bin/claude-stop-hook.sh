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
if command -v kitty >/dev/null 2>&1; then
    SELF_FOCUSED=$(kitty @ ls 2>/dev/null | jq -r '
        [ .[] | select(.is_focused == true)
              | .tabs[] | select(.is_active == true)
              | .windows[] | select(.is_active == true and .is_self == true)
              | .id ] | first // empty' 2>/dev/null || true)
    [[ -n "$SELF_FOCUSED" ]] && exit 0
fi

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

# Conversation name as the headline (helps tell apart multiple Claude windows);
# falls back to the generic label before a title has been generated.
SUMMARY="${TITLE:-Waiting for input}"
BODY="$LAST_MESSAGE"$'\n\n'"📁 $CWD_DISPLAY"

# --- Resolve the niri window id of Claude's Kitty OS window (for click-to-focus) ---
NIRI_ID=""
if command -v niri >/dev/null 2>&1 && command -v kitty >/dev/null 2>&1; then
    # Walk up to the kitty process backing this OS window.
    kpid=$$
    while [[ "${kpid:-1}" -gt 1 ]]; do
        [[ "$(cat /proc/$kpid/comm 2>/dev/null || true)" == "kitty" ]] && break
        kpid=$(awk '/^PPid:/{print $2}' /proc/$kpid/status 2>/dev/null || echo 1)
    done
    # Title of the active pane in Claude's OS window, to disambiguate when one
    # kitty process backs several OS windows (same pid, different titles).
    wtitle=$(kitty @ ls 2>/dev/null | jq -r '
        [ .[] | select(any(.tabs[].windows[]; .is_self == true)) ][0]
        | .tabs[] | select(.is_active == true)
        | .windows[] | select(.is_active == true) | .title' 2>/dev/null || true)
    if [[ "${kpid:-1}" -gt 1 ]]; then
        NIRI_ID=$(niri msg --json windows 2>/dev/null | jq -r --argjson p "$kpid" --arg t "$wtitle" '
            ([ .[] | select(.pid == $p) ]) as $m
            | (if ($m | length) == 1 then $m[0]
               else ($m[] | select(.title == $t)) end).id // empty' 2>/dev/null | head -1 || true)
    fi
fi

# --- Notify (detached so the hook never blocks) and handle the click ---
export CLAUDE_SUMMARY="$SUMMARY"
export CLAUDE_BODY="$BODY"
export CLAUDE_NIRI_ID="$NIRI_ID"
setsid bash -c '
    action=$(notify-send --app-name="Claude Code" \
        --action="default=Focus window" \
        -t 0 \
        -h "string:x-canonical-private-synchronous:claude-stop" \
        --wait \
        "$CLAUDE_SUMMARY" "$CLAUDE_BODY") || exit 0
    if [[ "$action" == "default" ]]; then
        [[ -n "${CLAUDE_NIRI_ID:-}" ]] && niri msg action focus-window --id "$CLAUDE_NIRI_ID" >/dev/null 2>&1 || true
        [[ -n "${KITTY_WINDOW_ID:-}" ]] && kitty @ focus-window --match "id:${KITTY_WINDOW_ID}" >/dev/null 2>&1 || true
    fi
' </dev/null >/dev/null 2>&1 &

exit 0
