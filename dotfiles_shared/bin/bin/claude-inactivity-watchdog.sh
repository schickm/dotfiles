#!/bin/bash
# Claude Code inactivity watchdog hook
# Suspends Claude (Ctrl+Z) after 30 minutes of no interaction
# Uses Kitty IPC to send the suspend signal
# Supports multiple parallel Claude instances (keyed by Kitty window ID)

set -euo pipefail

INACTIVITY_TIMEOUT="${CLAUDE_INACTIVITY_TIMEOUT:-1800}" # 1800  # 30 minutes default

# Read hook input (required even if we don't use it)
cat > /dev/null

# Not running in Kitty? Skip.
if [[ -z "${KITTY_WINDOW_ID:-}" ]]; then
    exit 0
fi

# Disabled via env var? Skip.
if [[ "${CLAUDE_INACTIVITY_WATCHDOG:-1}" == "0" ]]; then
    exit 0
fi

WATCHDOG_PID_FILE="/tmp/claude-inactivity-watchdog-${KITTY_WINDOW_ID}.pid"

# Kill existing watchdog for THIS window only
if [[ -f "$WATCHDOG_PID_FILE" ]]; then
    OLD_PID=$(cat "$WATCHDOG_PID_FILE" 2>/dev/null || true)
    if [[ -n "$OLD_PID" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID" 2>/dev/null || true
    fi
    rm -f "$WATCHDOG_PID_FILE"
fi

# Start watchdog fully detached (new session, no inherited fds)
setsid bash -c "
    trap 'exit 0' TERM
    echo \$\$ > '$WATCHDOG_PID_FILE'
    sleep $INACTIVITY_TIMEOUT
    kitty @ send-text --match 'id:${KITTY_WINDOW_ID}' \$'\x1a'
" </dev/null >/dev/null 2>&1 &

exit 0
