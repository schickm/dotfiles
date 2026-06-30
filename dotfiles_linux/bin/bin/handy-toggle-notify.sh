#!/bin/sh
# Toggle Handy voice-to-text recording (Mod+A) plus a visual "recording"
# indicator notification.
#
# Handy itself is toggled exactly as the old bind did, by sending the newest
# handy process SIGUSR2 -- its behaviour is unchanged. This script just adds a
# persistent mako notification that appears on the first press and is dismissed
# on the second, so there's a visible cue that recording is in progress.
#
# State (the notification id) lives in $XDG_RUNTIME_DIR so it resets on logout.
set -eu

STATE="${XDG_RUNTIME_DIR:-/tmp}/handy-recording.state"

# Toggle Handy first so it responds as fast as possible, independent of the
# notification work below. Use -x (exact name match) so we signal only the
# real "handy" process -- a plain substring match would also hit this script
# (handy-toggle-notify.sh) and, being newer, steal the signal from Handy.
# pkill exits non-zero if no process matched.
pkill -USR2 -nx handy || true

if [ -f "$STATE" ]; then
    # --- Stop: dismiss the recording indicator ---------------------------
    id=$(cat "$STATE" 2>/dev/null || true)
    rm -f "$STATE"
    [ -n "${id:-}" ] && makoctl dismiss -n "$id" 2>/dev/null || true
else
    # --- Start: show a persistent recording indicator --------------------
    # -t 0 keeps it on screen until we dismiss it on the next press.
    id=$(notify-send --print-id -t 0 -u critical -a "Handy" \
        "🔴 Recording" "Voice-to-text is listening")
    printf '%s\n' "$id" > "$STATE"
fi
