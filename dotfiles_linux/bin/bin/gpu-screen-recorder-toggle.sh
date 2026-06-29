#!/bin/sh
# Toggle a screen recording with gpu-screen-recorder (Wayland/niri).
#
# First run : start recording the portal-selected output to a timestamped
#             file in "~/Videos/screen recordings" and remember the PID + path.
# Second run: stop the recording (SIGINT lets gsr finalize the mp4), then ask
#             for a name via fuzzel, rename the file, and open it in the default
#             video player. An empty / cancelled prompt keeps the timestamp name.
#
# State is kept in $XDG_RUNTIME_DIR so it resets on logout.
set -eu

STATE="${XDG_RUNTIME_DIR:-/tmp}/gpu-screen-recorder.state"
VIDEO_DIR="$HOME/Videos/screen recordings"

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a "Screen Recorder" "$@" || true
}

if [ -f "$STATE" ]; then
    # --- Stop ------------------------------------------------------------
    # State file holds two lines: PID then output path.
    pid=$(sed -n 1p "$STATE")
    out=$(sed -n 2p "$STATE")
    rm -f "$STATE"

    if [ -n "${pid:-}" ] && kill -0 "$pid" 2>/dev/null; then
        kill -INT "$pid"
        # Wait for gsr to flush and finalize the container before touching it.
        while kill -0 "$pid" 2>/dev/null; do sleep 0.1; done
    fi

    if [ ! -f "$out" ]; then
        notify "Recording failed" "No output file at $out"
        exit 1
    fi

    # Ask for a descriptive name (dmenu mode returns the typed text).
    name=$(printf '' | fuzzel --dmenu --prompt 'Name this recording: ' 2>/dev/null || true)
    if [ -n "$name" ]; then
        # Sanitize: spaces and slashes -> dashes.
        safe=$(printf '%s' "$name" | tr ' /' '--')
        dest="$VIDEO_DIR/$safe.mp4"
        mv -- "$out" "$dest"
        out="$dest"
    fi

    notify "Recording saved" "$out"
    xdg-open "$out" >/dev/null 2>&1 &
else
    # --- Start -----------------------------------------------------------
    mkdir -p "$VIDEO_DIR"
    stamp=$(date +%Y%m%d-%H%M%S)
    out="$VIDEO_DIR/rec-$stamp.mp4"

    gpu-screen-recorder -w portal -a default_input -f 20 -k h264 -o "$out" &
    pid=$!

    printf '%s\n%s\n' "$pid" "$out" > "$STATE"
    notify "Recording started" "$out"
fi
