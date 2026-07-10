#!/bin/bash
# Shared plumbing for the workspace scripts (start-new-ticket, resume-workspace).
# Source it, don't execute it:
#   source "$(dirname "$(readlink -f "$0")")/workspace-lib.sh"
#
# Convention: ~/workvc/<repo>/ is a "workspace container" — machine-local
# support files (.wt-addrc, .workspacerc, certs, ...) at the top level, git
# worktrees as subdirectories (the git dir itself may be a bare repo in
# .bare). A directory counts as a container when it has a .workspacerc or
# .wt-addrc.
#
# .workspacerc (optional, sourced bash) may define:
#   MAIN_WORKTREE           subdir name of the primary worktree
#                           (default: first of master/main/trunk that exists)
#   WORKSPACE_COLOR         background color (CSS hex) for this repo's
#                           workspaces in waybar — pick something dark enough
#                           for white text (default: hashed from repo name,
#                           see workspace_color)
#   workspace_urls <dir>    echo URLs (one per line) to open in the
#                           workspace's Chrome, e.g. a dev-server hotlink
#   workspace_launch <dir>  launch the workspace's terminal windows
#                           (default: claude + editor)
#
# workspace_launch (and the Chrome spawn) run inside a fresh kernel session
# under niri-spawn-on-workspace: every window the launch's process tree opens
# is moved onto the workspace even if focus has moved elsewhere by the time
# the app gets around to mapping it. Recipes can keep plain `nohup ... &`
# spawns — no wrapping needed. The exception is single-instance apps that
# hand off to an already-running process (e.g. plain google-chrome joining an
# existing instance): those windows belong to the old session and won't be
# routed.

WORKVC_BASE="${WORKVC_BASE:-$HOME/workvc}"

# Run a command with a notification that dismisses when done
with_notification() {
    local title="$1"
    local body="$2"
    shift 2

    local notif_id=$(notify-send -p "$title" "$body")
    "$@"
    local exit_code=$?
    makoctl dismiss -n "$notif_id" >/dev/null
    return $exit_code
}

# List workspace container dirs (absolute paths, one per line).
workspace_containers() {
    local dir
    for dir in "$WORKVC_BASE"/*/; do
        dir="${dir%/}"
        if [[ -f "$dir/.workspacerc" || -f "$dir/.wt-addrc" ]]; then
            echo "$dir"
        fi
    done
    return 0
}

# Print the main worktree's directory name for a container.
detect_main_worktree() {
    local container="$1" name
    for name in master main trunk; do
        if [[ -e "$container/$name/.git" ]]; then
            echo "$name"
            return 0
        fi
    done
    return 1
}

# Print the container a worktree dir name belongs to. Fails for main-worktree
# names (they collide across repos and with hand-named niri workspaces) and
# for names present in more than one container.
container_for_worktree() {
    local target="$1" container found=""
    [[ -n "$target" ]] || return 1
    case "$target" in master|main|trunk) return 1 ;; esac
    for container in $(workspace_containers); do
        [[ -e "$container/$target/.git" ]] || continue
        [[ -n "$found" ]] && return 1
        found="$container"
    done
    [[ -n "$found" ]] && echo "$found"
}

# Find the container whose origin remote matches a GitHub "org/repo" slug.
container_for_github_slug() {
    local slug="$1" container main remote
    local slug_lc="${slug,,}"
    for container in $(workspace_containers); do
        main=$(detect_main_worktree "$container") || continue
        remote=$(git -C "$container/$main" remote get-url origin 2>/dev/null) || continue
        local remote_lc="${remote,,}"
        if [[ "$remote_lc" == *[:/]"$slug_lc" || "$remote_lc" == *[:/]"$slug_lc".git ]]; then
            echo "$container"
            return 0
        fi
    done
    return 1
}

# Print the container's waybar background color: WORKSPACE_COLOR from its
# .workspacerc, or a stable fallback picked from a palette by hashing the
# repo name (so unconfigured repos still get consistent, distinct colors).
workspace_color() {
    local container="$1" color=""
    if [[ -f "$container/.workspacerc" ]]; then
        color=$(unset WORKSPACE_COLOR
                source "$container/.workspacerc" >/dev/null 2>&1
                echo "${WORKSPACE_COLOR:-}")
    fi
    if [[ -z "$color" ]]; then
        local palette=('#b35a26' '#3d7a4e' '#5f5fa7' '#a84a5e'
                       '#2e7d8c' '#8a6d3b' '#6b4f8a' '#4a7ab5')
        local hash
        hash=$(basename "$container" | cksum | cut -d' ' -f1)
        color="${palette[hash % ${#palette[@]}]}"
    fi
    echo "$color"
}

# Source a container's .workspacerc and fill in defaults. Sets MAIN_WORKTREE
# and guarantees workspace_urls / workspace_launch are defined.
load_workspacerc() {
    local container="$1"
    MAIN_WORKTREE=""
    unset -f workspace_urls workspace_launch 2>/dev/null || true

    if [[ -f "$container/.workspacerc" ]]; then
        source "$container/.workspacerc"
    fi

    if [[ -z "$MAIN_WORKTREE" ]]; then
        MAIN_WORKTREE=$(detect_main_worktree "$container") || MAIN_WORKTREE=""
    fi

    if ! declare -F workspace_urls >/dev/null; then
        workspace_urls() { :; }
    fi

    if ! declare -F workspace_launch >/dev/null; then
        workspace_launch() {
            nohup env DISABLE_INSTALLATION_CHECKS=1 DISABLE_AUTOUPDATER=1 kitty-run claude --dangerously-skip-permissions &>/dev/null &
            nohup kitty-run k &>/dev/null &
        }
    fi
}
