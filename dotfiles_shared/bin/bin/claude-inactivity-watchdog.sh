#!/bin/bash
# Claude Code inactivity watchdog hook
# Backgrounds Claude (Ctrl+Z) after a period of no interaction, but ONLY once the
# Kitty window is not focused by the compositor. If still focused at the timeout,
# it waits another full interval and re-checks.
# Decisions are logged per instance to:
#   ~/.claude/logs/watchdog/<sanitized-cwd>-win<KITTY_WINDOW_ID>.log
# Supports multiple parallel Claude instances (keyed by Kitty window ID).

set -euo pipefail

INACTIVITY_TIMEOUT="${CLAUDE_INACTIVITY_TIMEOUT:-1800}" # 1800  # 30 minutes default
FOCUS_HELPER="${CLAUDE_FOCUS_HELPER:-$HOME/bin/claude-window-focused.sh}"

# Read hook input (consume stdin even if the guards below skip).
INPUT=$(cat)

# Not running in Kitty? Skip.
if [[ -z "${KITTY_WINDOW_ID:-}" ]]; then
    exit 0
fi

# Disabled via env var? Skip.
if [[ "${CLAUDE_INACTIVITY_WATCHDOG:-1}" == "0" ]]; then
    exit 0
fi

# --- Identify this instance (for logging) ---
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
[[ -z "$CWD" ]] && CWD="$PWD"
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || true)
TITLE=""
[[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]] && \
    TITLE=$(jq -rs 'map(select(.type == "ai-title") | .aiTitle) | last // empty' "$TRANSCRIPT_PATH" 2>/dev/null || true)

# --- Per-instance log file: ~/.claude/logs/watchdog/<sanitized-cwd>-win<id>.log ---
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

WATCHDOG_PID_FILE="/tmp/claude-inactivity-watchdog-${KITTY_WINDOW_ID}.pid"

# Kill existing watchdog for THIS window only.
if [[ -f "$WATCHDOG_PID_FILE" ]]; then
    OLD_PID=$(cat "$WATCHDOG_PID_FILE" 2>/dev/null || true)
    if [[ -n "$OLD_PID" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID" 2>/dev/null || true
        log "replaced previous watchdog (pid $OLD_PID)"
    fi
    rm -f "$WATCHDOG_PID_FILE"
fi

log "armed: timeout=${INACTIVITY_TIMEOUT}s cwd=$CWD title=\"$TITLE\""

# Start watchdog fully detached (new session, no inherited fds). The focus
# decision happens AFTER the sleep, inside this subshell. Identifying data is
# passed via the environment so the body can stay single-quoted (no fragile
# interpolation of titles/paths into code).
export WATCHDOG_PID_FILE INACTIVITY_TIMEOUT KITTY_WINDOW_ID SESSION_ID LOG_FILE FOCUS_HELPER
setsid bash -c '
    wlog() {
        printf "%s [win:%s sess:%s pid:%s] %s\n" \
            "$(date "+%Y-%m-%d %H:%M:%S%z")" "$KITTY_WINDOW_ID" "$SESSION_ID" "$$" "$*" >> "$LOG_FILE"
    }
    trap "wlog \"timer cancelled (replaced by a newer arm or shutdown)\"; exit 0" TERM
    echo $$ > "$WATCHDOG_PID_FILE"
    sleep "$INACTIVITY_TIMEOUT"
    wlog "inactivity reached (${INACTIVITY_TIMEOUT}s) -> checking focus"
    while "$FOCUS_HELPER"; do
        wlog "window FOCUSED -> deferring; rechecking in ${INACTIVITY_TIMEOUT}s"
        sleep "$INACTIVITY_TIMEOUT"
    done
    wlog "window NOT focused -> backgrounding (Ctrl+Z)"
    if kitty @ send-text --match "id:$KITTY_WINDOW_ID" "$(printf "\032")"; then
        wlog "suspend signal sent OK"
    else
        rc=$?; wlog "suspend signal FAILED (rc=$rc)"
    fi
' </dev/null >/dev/null 2>&1 &

exit 0
