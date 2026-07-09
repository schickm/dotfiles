#!/bin/sh
# Toggle Handy voice-to-text recording (Mod+A) plus a visual "recording"
# indicator notification.
#
# Handy itself is toggled exactly as the old bind did, by sending the newest
# handy process SIGUSR2 -- its behaviour is unchanged. This script just adds a
# persistent mako notification that appears on the first press and is dismissed
# on the second, so there's a visible cue that recording is in progress.
#
# The on-screen notification IS the toggle state: if a "Handy" notification is
# currently displayed we dismiss it, otherwise we show one. No state file -- a
# hidden file can silently desync from Handy (a SIGUSR2 dropped while Handy was
# busy transcribing inverted the parity permanently, and the file survived in
# $XDG_RUNTIME_DIR across sessions). With the notification as the source of
# truth, any desync is visible and fixed by just dismissing the notification.
set -eu

# Toggle Handy first so it responds as fast as possible, independent of the
# notification work below. Use -x (exact name match) so we signal only the
# real "handy" process -- a plain substring match would also hit this script
# (handy-toggle-notify.sh) and, being newer, steal the signal from Handy.
# pkill exits non-zero if no process matched.
pkill -USR2 -nx handy || true

# Find our currently-displayed indicator, if any. makoctl list is plain text:
# a "Notification <id>: ..." header followed by an indented "App name:" line.
id=$(makoctl list | awk '
    /^Notification [0-9]+:/ { nid = $2; sub(":", "", nid) }
    /^  App name: Handy$/   { print nid; exit }
')

if [ -n "$id" ]; then
    makoctl dismiss -n "$id"
else
    # -t 0 keeps it on screen until we dismiss it on the next press.
    notify-send -t 0 -u critical -a "Handy" \
        "🔴 Recording" "Voice-to-text is listening"
fi
