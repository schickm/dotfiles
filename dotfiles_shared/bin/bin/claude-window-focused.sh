#!/bin/bash
# Shared helper for Claude Code Kitty hooks.
#
# Exit 0 if the Kitty window this process belongs to is the window the user is
# actually looking at right now; exit 1 otherwise. "Otherwise" deliberately
# includes every uncertain case (Kitty not installed, not running under Kitty,
# remote control unreachable, malformed output, compositor unreachable) so
# callers fail open to acting: the stop-notification still fires and the
# inactivity watchdog still backgrounds when focus cannot be determined.
#
# Two independent things have to be true:
#   1. Within my own Kitty OS window I am the active pane (Kitty `is_self` +
#      `is_active`). If a sibling pane is on top, the user isn't looking at me.
#   2. My Kitty OS window is the one the compositor currently has focused.
#
# For (2) we ask niri directly rather than trusting Kitty's own `is_focused`.
# In a niri column that stacks several windows on top of each other, Kitty can
# report `is_focused == true` for an obscured window, so it would treat both
# the top and the buried window as focused. niri's `focused-window` is the
# single source of truth: exactly one window is focused, and it is the one on
# top of the stack. We map our OS window to a niri window by the backing kitty
# pid (disambiguated by title when one kitty process backs several OS windows).
set -uo pipefail

command -v kitty >/dev/null 2>&1 || exit 1
[[ -n "${KITTY_WINDOW_ID:-}" ]] || exit 1

LS=$(kitty @ ls 2>/dev/null) || exit 1
[[ -n "$LS" ]] || exit 1

# (1) Am I the active pane in the active tab of my own Kitty OS window?
self_active=$(printf '%s' "$LS" | jq -r '
    [ .[] | select(any(.tabs[].windows[]; .is_self == true))
          | .tabs[] | select(.is_active == true)
          | .windows[] | select(.is_active == true and .is_self == true)
          | .id ] | first // empty' 2>/dev/null)
[[ -n "$self_active" ]] || exit 1

# Title of the active pane in my OS window — used to identify my OS window to
# niri (kitty mirrors the active pane's title onto the OS window).
my_title=$(printf '%s' "$LS" | jq -r '
    [ .[] | select(any(.tabs[].windows[]; .is_self == true)) ][0]
    | .tabs[] | select(.is_active == true)
    | .windows[] | select(.is_active == true) | .title' 2>/dev/null)

# Without niri we cannot tell a stacked/obscured window from a top one, so fall
# back to kitty's own OS-window focus flag (fail-open to acting elsewhere).
if ! command -v niri >/dev/null 2>&1; then
    printf '%s' "$LS" | jq -e '
        any(.[]; .is_focused == true
            and any(.tabs[].windows[]; .is_self == true and .is_active == true))' \
        >/dev/null 2>&1
    exit $?
fi

# (2) Walk up to the kitty process backing this OS window.
kpid=$$
while [[ "${kpid:-1}" -gt 1 ]]; do
    [[ "$(cat /proc/$kpid/comm 2>/dev/null || true)" == "kitty" ]] && break
    kpid=$(awk '/^PPid:/{print $2}' /proc/$kpid/status 2>/dev/null || echo 1)
done
[[ "${kpid:-1}" -gt 1 ]] || exit 1

# Is the single window niri currently has focused my Kitty OS window?
niri msg --json focused-window 2>/dev/null | jq -e --argjson p "$kpid" --arg t "$my_title" '
    . != null and .pid == $p and ($t == "" or .title == $t)' >/dev/null 2>&1
