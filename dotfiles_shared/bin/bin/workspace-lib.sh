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
#   workspace_claude_guidance <dir>
#                           echo repo-specific standing guidance appended to
#                           a new worktree's CLAUDE.local.md (default: use
#                           the Chrome MCP for in-browser testing; define an
#                           empty function to omit)
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

# Stable palette pick for an arbitrary string. Hashes with a trailing
# newline to stay byte-identical with the original `basename | cksum`
# pipeline, so existing waybar colors don't shift.
palette_color_for() {
    local palette=('#b35a26' '#3d7a4e' '#5f5fa7' '#a84a5e'
                   '#2e7d8c' '#8a6d3b' '#6b4f8a' '#4a7ab5')
    local hash
    hash=$(printf '%s\n' "$1" | cksum | cut -d' ' -f1)
    echo "${palette[hash % ${#palette[@]}]}"
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
    [[ -z "$color" ]] && color=$(palette_color_for "$(basename "$container")")
    echo "$color"
}

# Resolve the niri window id of the Kitty OS window this process runs in:
# walk /proc up to the backing kitty process, then disambiguate several OS
# windows of one kitty process by the active pane title. Prints nothing when
# not running under kitty + niri. (Shared by the Claude Code hooks and
# workspace-activity.)
resolve_claude_window_id() {
    command -v niri >/dev/null 2>&1 || return 0
    command -v kitty >/dev/null 2>&1 || return 0
    [[ -n "${KITTY_WINDOW_ID:-}" ]] || return 0
    local kpid=$$ wtitle
    while [[ "${kpid:-1}" -gt 1 ]]; do
        [[ "$(cat /proc/$kpid/comm 2>/dev/null || true)" == "kitty" ]] && break
        kpid=$(awk '/^PPid:/{print $2}' /proc/$kpid/status 2>/dev/null || echo 1)
    done
    [[ "${kpid:-1}" -gt 1 ]] || return 0
    wtitle=$(kitty @ ls 2>/dev/null | jq -r '
        [ .[] | select(any(.tabs[].windows[]; .is_self == true)) ][0]
        | .tabs[] | select(.is_active == true)
        | .windows[] | select(.is_active == true) | .title' 2>/dev/null || true)
    niri msg --json windows 2>/dev/null | jq -r --argjson p "$kpid" --arg t "$wtitle" '
        ([ .[] | select(.pid == $p) ]) as $m
        | (if ($m | length) == 1 then $m[0]
           else ($m[] | select(.title == $t)) end).id // empty' 2>/dev/null | head -1 || true
    return 0
}

# Print the name of the niri workspace holding a window id; empty when the
# workspace is unnamed or niri is unavailable.
workspace_name_for_window() {
    local win_id="${1:-}" ws_id
    [[ -n "$win_id" ]] || return 0
    ws_id=$(niri msg --json windows 2>/dev/null | jq -r --argjson w "$win_id" \
        '[ .[] | select(.id == $w) ] | first | .workspace_id // empty' 2>/dev/null) || ws_id=""
    [[ -n "$ws_id" ]] || return 0
    niri msg --json workspaces 2>/dev/null | jq -r --argjson w "$ws_id" \
        '[ .[] | select(.id == $w) ] | first | .name // empty' 2>/dev/null || true
    return 0
}

# Print the workspace container a working directory lives in; empty when the
# path isn't inside one.
container_for_cwd() {
    local cwd="${1:-}"
    case "$cwd" in "$WORKVC_BASE"/*) ;; *) return 0 ;; esac
    local rel="${cwd#"$WORKVC_BASE"/}"
    local container="$WORKVC_BASE/${rel%%/*}"
    [[ -f "$container/.workspacerc" || -f "$container/.wt-addrc" ]] && echo "$container"
    return 0
}

# Workspace label derived from a working directory: the worktree dir name for
# paths inside a workspace container (matching the niri workspace names
# resume-workspace assigns), otherwise the directory's basename.
workspace_name_from_cwd() {
    local cwd="${1:-}" container
    [[ -n "$cwd" ]] || return 0
    container=$(container_for_cwd "$cwd")
    if [[ -n "$container" && "$cwd" != "$container" ]]; then
        local rel="${cwd#"$container"/}"
        echo "${rel%%/*}"
    else
        basename "$cwd"
    fi
    return 0
}

# Escape a string for Pango markup (mako parses notification bodies as
# markup when markup=1, so raw commands / paths / model output must be
# escaped before interpolation).
pango_escape() {
    # Replacements quoted so bash 5.2's patsub_replacement leaves & literal.
    local s=$1
    s=${s//&/'&amp;'}
    s=${s//</'&lt;'}
    s=${s//>/'&gt;'}
    echo "$s"
}

# Notification context for the Claude Code hooks. Sets (any may be empty):
#   WS_WINDOW_ID  niri window id of the hook's Kitty OS window
#   WS_NAME       niri workspace name, falling back to a cwd-derived label
#   WS_COLOR      the workspace's waybar color (set whenever WS_NAME is)
#   WS_TAG        Pango-markup pill for notification bodies, styled like the
#                 waybar workspace button (workspace color, white text)
# Safe under set -e.
resolve_workspace_context() {
    local cwd="${1:-}" container=""
    WS_WINDOW_ID=$(resolve_claude_window_id)
    WS_NAME=""
    WS_COLOR=""
    WS_TAG=""
    [[ -n "$WS_WINDOW_ID" ]] && WS_NAME=$(workspace_name_for_window "$WS_WINDOW_ID")
    [[ -z "$WS_NAME" ]] && WS_NAME=$(workspace_name_from_cwd "$cwd")
    [[ -z "$WS_NAME" ]] && return 0
    container=$(container_for_cwd "$cwd")
    if [[ -z "$container" ]]; then
        container=$(container_for_worktree "$WS_NAME") || container=""
    fi
    if [[ -n "$container" ]]; then
        WS_COLOR=$(workspace_color "$container")
    else
        WS_COLOR=$(palette_color_for "$WS_NAME")
    fi
    WS_TAG="<span background='$WS_COLOR' foreground='#ffffff' weight='bold'> $(pango_escape "$WS_NAME") </span>"
    return 0
}

# seed_claude_local_md <worktree_dir> <purpose>
# Write the worktree's CLAUDE.local.md: the purpose text (may be multi-line)
# followed by the container's workspace_claude_guidance output, if any.
# Requires load_workspacerc to have run (it defines the guidance function).
seed_claude_local_md() {
    local worktree_dir="$1" purpose="$2"
    local guidance
    guidance=$(workspace_claude_guidance "$worktree_dir")
    cat >"$worktree_dir/CLAUDE.local.md" <<EOF
$purpose${guidance:+

$guidance}
EOF
}

# Source a container's .workspacerc and fill in defaults. Sets MAIN_WORKTREE
# and guarantees workspace_urls / workspace_launch are defined.
load_workspacerc() {
    local container="$1"
    MAIN_WORKTREE=""
    unset -f workspace_urls workspace_launch workspace_claude_guidance 2>/dev/null || true

    if [[ -f "$container/.workspacerc" ]]; then
        source "$container/.workspacerc"
    fi

    if [[ -z "$MAIN_WORKTREE" ]]; then
        MAIN_WORKTREE=$(detect_main_worktree "$container") || MAIN_WORKTREE=""
    fi

    if ! declare -F workspace_urls >/dev/null; then
        workspace_urls() { :; }
    fi

    if ! declare -F workspace_claude_guidance >/dev/null; then
        workspace_claude_guidance() {
            echo "Be sure to use the Chrome MCP for anything that would benefit from in-browser testing / validation."
        }
    fi

    if ! declare -F workspace_launch >/dev/null; then
        workspace_launch() {
            nohup env DISABLE_INSTALLATION_CHECKS=1 DISABLE_AUTOUPDATER=1 kitty-run claude --dangerously-skip-permissions &>/dev/null &
            nohup kitty-run k &>/dev/null &
        }
    fi
}
