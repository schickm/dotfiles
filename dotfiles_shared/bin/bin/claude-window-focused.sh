#!/bin/bash
# Shared helper for Claude Code Kitty hooks.
#
# Exit 0 if the Kitty window this process belongs to currently has keyboard
# focus in the compositor; exit 1 otherwise. "Otherwise" deliberately includes
# every uncertain case (Kitty not installed, not running under Kitty, remote
# control unreachable, malformed output) so callers fail open to acting:
# the stop-notification still fires and the inactivity watchdog still
# backgrounds when focus cannot be determined.
#
# Relies on Kitty's `is_self` (the window this process runs in) and the
# OS-window/tab/window focus flags, which resolve correctly in any child
# process that inherits KITTY_WINDOW_ID.
set -uo pipefail

command -v kitty >/dev/null 2>&1 || exit 1
[[ -n "${KITTY_WINDOW_ID:-}" ]] || exit 1

focused=$(kitty @ ls 2>/dev/null | jq -r '
    [ .[] | select(.is_focused == true)
          | .tabs[] | select(.is_active == true)
          | .windows[] | select(.is_active == true and .is_self == true)
          | .id ] | first // empty' 2>/dev/null)

[[ -n "$focused" ]]
