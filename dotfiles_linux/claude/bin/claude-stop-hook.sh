#!/bin/bash
# Claude Code Stop hook - notify when waiting for input.
#   * Only notifies when Claude's Kitty window is NOT focused.
#   * Click the notification -> focus that window in niri (switching to its
#     workspace) and select its Kitty pane.
#   * swaync's close button dismisses without focusing.
#   * Focusing the window any other way (keyboard, waybar, workspace switch) also
#     clears it: the notification is registered against its niri window id and
#     swaync-focus-dismiss closes it when that window takes focus.
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
# The lib ships in the shared bin package, so go through ~/bin rather than
# resolving it next to this script (which lives in the claude package).
WORKSPACE_LIB="$HOME/bin/workspace-lib.sh"
source "$WORKSPACE_LIB"
resolve_workspace_context "$CWD"
NIRI_ID="$WS_WINDOW_ID"

# Conversation name as the headline (helps tell apart multiple Claude windows);
# falls back to the generic label before a title has been generated. The
# workspace pill leading the body says where it came from.
SUMMARY="${TITLE:-Waiting for input}"
BODY="$(pango_escape "$LAST_MESSAGE")"$'\n\n'"📁 $(pango_escape "$CWD_DISPLAY")"
[[ -n "$WS_TAG" ]] && BODY="$WS_TAG"$'\n'"$BODY"

# --- Notify (detached so the hook never blocks) and handle the click ---
# One stop notification per workspace: swaync ignores the
# x-canonical-private-synchronous hint mako honored, so replacement is done by
# hand — remember the previous notification's id per workspace and close it
# before sending the new one (closing also releases its --wait process).
#
# `-p` prints the notification id as soon as it is created, `--wait` prints the
# invoked action (nothing, if it was dismissed) when it closes — so read them
# off the same pipe one at a time rather than capturing the lot at the end. The
# id has to be in hand while the notification is still up: that is what lets
# swaync-focus-dismiss clear it when this window is focused.
export CLAUDE_SUMMARY="$SUMMARY"
export CLAUDE_BODY="$BODY"
export CLAUDE_NIRI_ID="$NIRI_ID"
export CLAUDE_CATEGORY="${WS_NAME:+ws-$WS_NAME}"
export CLAUDE_STOP_ID_FILE="${XDG_RUNTIME_DIR:-/tmp}/claude-stop-ids/claude-stop${WS_NAME:+-$WS_NAME}"
export CLAUDE_LIB="$WORKSPACE_LIB"
setsid bash -c '
    source "$CLAUDE_LIB"
    mkdir -p "$(dirname "$CLAUDE_STOP_ID_FILE")" 2>/dev/null || true
    if prev=$(cat "$CLAUDE_STOP_ID_FILE" 2>/dev/null) && [[ "$prev" =~ ^[0-9]+$ ]]; then
        close_notification "$prev"
    fi
    exec 3< <(notify-send --app-name="Claude Code" \
        --action="default=Focus window" \
        -t 0 \
        ${CLAUDE_CATEGORY:+--category="$CLAUDE_CATEGORY"} \
        -p --wait \
        "$CLAUDE_SUMMARY" "$CLAUDE_BODY")
    read -r notif_id <&3 || exit 0
    printf "%s\n" "$notif_id" > "$CLAUDE_STOP_ID_FILE" 2>/dev/null || true
    register_claude_notification "$notif_id" "${CLAUDE_NIRI_ID:-}"
    read -r action <&3 || action=""
    unregister_claude_notification "$notif_id"
    # Only clear the id file if a newer stop notification has not replaced it.
    [[ "$(cat "$CLAUDE_STOP_ID_FILE" 2>/dev/null)" == "$notif_id" ]] && rm -f "$CLAUDE_STOP_ID_FILE"
    if [[ "$action" == "default" ]]; then
        [[ -n "${CLAUDE_NIRI_ID:-}" ]] && niri msg action focus-window --id "$CLAUDE_NIRI_ID" >/dev/null 2>&1 || true
        [[ -n "${KITTY_WINDOW_ID:-}" ]] && kitty @ focus-window --match "id:${KITTY_WINDOW_ID}" >/dev/null 2>&1 || true
    fi
' </dev/null >/dev/null 2>&1 &

exit 0
