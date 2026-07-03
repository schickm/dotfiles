#!/bin/sh
# Toggle hiding of all floating windows (handy while screen sharing).
#
# First run : move every floating window to the "scratch" workspace,
#             recording each window's original workspace so it can return.
# Second run: move each recorded window back to where it came from.
#
# State is kept in $XDG_RUNTIME_DIR so it resets on logout.
set -eu

STATE="${XDG_RUNTIME_DIR:-/tmp}/niri-hidden-floating"
SCRATCH="scratch"

if [ -f "$STATE" ]; then
    # --- Restore ---------------------------------------------------------
    # Each line: "<window_id>\t<workspace_reference>" (name when available,
    # otherwise the numeric index).
    while IFS='	' read -r id ref; do
        [ -n "${id:-}" ] || continue
        niri msg action move-window-to-workspace --window-id "$id" --focus false "$ref" || true
    done < "$STATE"
    rm -f "$STATE"
else
    # --- Hide ------------------------------------------------------------
    # Resolve each floating window's workspace to a stable reference
    # (prefer the workspace name; fall back to its index).
    niri msg -j windows \
        | jq -r --argjson ws "$(niri msg -j workspaces)" '
            ($ws | map({(.id|tostring): (.name // (.idx|tostring))}) | add) as $ref
            | .[] | select(.is_floating)
            | "\(.id)\t\($ref[(.workspace_id|tostring)])"' \
        > "$STATE"

    [ -s "$STATE" ] || { rm -f "$STATE"; exit 0; }  # nothing floating

    while IFS='	' read -r id ref; do
        [ -n "${id:-}" ] || continue
        niri msg action move-window-to-workspace --window-id "$id" --focus false "$SCRATCH"
    done < "$STATE"
fi
