#!/bin/bash
# Claude Code UserPromptSubmit hook - disarm the inactivity watchdog.
#
# The watchdog (claude-inactivity-watchdog.sh) arms a timer on every Stop and
# backgrounds the window once it expires. That timer measures "time since the
# last Stop", which it treats as a proxy for "the user has been idle". The proxy
# breaks for a single long-running turn: while Claude is actively working it
# emits no Stop, so the timer from the PREVIOUS Stop keeps counting and can
# suspend the window mid-work.
#
# Fix: cancel the pending timer the moment a new turn begins. After this runs
# there is no armed watchdog until the next Stop, so an active turn can never be
# backgrounded. The watchdog is only ever armed in the genuine idle window
# (between a Stop and the next prompt).
#
# Keyed by Kitty window id, matching the watchdog. Logged to the same
# per-instance file so arm/disarm pairs interleave for debugging.
set -euo pipefail

# Consume stdin even when the guards below skip.
INPUT=$(cat)

# Not running in Kitty? Nothing the watchdog could have armed.
[[ -n "${KITTY_WINDOW_ID:-}" ]] || exit 0

WATCHDOG_PID_FILE="/tmp/claude-inactivity-watchdog-${KITTY_WINDOW_ID}.pid"
[[ -f "$WATCHDOG_PID_FILE" ]] || exit 0

# --- Identify this instance (for logging), mirroring the watchdog ---
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
[[ -z "$CWD" ]] && CWD="$PWD"

LOG_DIR="$HOME/.claude/logs/watchdog"
mkdir -p "$LOG_DIR" 2>/dev/null || true
cwd_clean="${CWD#/}"
SANITIZED="${cwd_clean//\//-}"
[[ -z "$SANITIZED" ]] && SANITIZED="root"
LOG_FILE="$LOG_DIR/${SANITIZED}-win${KITTY_WINDOW_ID}.log"

log() {
    printf '%s [win:%s sess:%s] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S%z')" "$KITTY_WINDOW_ID" "$SESSION_ID" "$*" >> "$LOG_FILE"
}

OLD_PID=$(cat "$WATCHDOG_PID_FILE" 2>/dev/null || true)
rm -f "$WATCHDOG_PID_FILE"

if [[ -n "$OLD_PID" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
    # The watchdog runs under setsid, so its pid is its own process-group
    # leader. Signal the whole group (negative pid) so the `sleep` child is
    # interrupted too -- otherwise bash defers the TERM trap until the long
    # sleep finishes and the process lingers. Fall back to a plain kill.
    kill -TERM -- "-$OLD_PID" 2>/dev/null || kill -TERM "$OLD_PID" 2>/dev/null || true
    log "disarmed watchdog (pid $OLD_PID) -- new turn started"
fi

exit 0
