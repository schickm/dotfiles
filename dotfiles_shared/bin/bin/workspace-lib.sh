#!/bin/bash
# Shared plumbing for the workspace scripts (start-new-workspace, start-new-ticket,
# resume-workspace).
# Source it, don't execute it. From a script in this same stow package:
#   source "$(dirname "$(readlink -f "$0")")/workspace-lib.sh"
# From anywhere else (another stow package, a hook), go through the installed
# copy instead — the sibling form breaks as soon as the caller moves packages:
#   source "$HOME/bin/workspace-lib.sh"
#
# Convention: ~/workvc/<repo>/ is a "workspace container" — machine-local
# support files (.wt-addrc, .workspacerc, certs, ...) at the top level, git
# worktrees as subdirectories (the git dir itself may be a bare repo in
# .bare). A directory counts as a container when it has a .workspacerc or
# .wt-addrc.
#
# .workspacerc (optional, sourced bash) may define:
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
    close_notification "$notif_id"
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

# Print the niri workspace name for a container's worktree dir. Generic
# main-worktree names (master/main/trunk) collide across repos and with
# hand-named niri workspaces, so they get a "<repo>/" prefix; every other
# worktree name is used as-is.
workspace_name_for() {
    local container="$1" worktree="$2"
    case "$worktree" in
        master|main|trunk|develop|beta) echo "$(basename "$container")/$worktree" ;;
        *) echo "$worktree" ;;
    esac
}

# Print the container a niri workspace name belongs to. Workspace names are
# derived from worktree dirs via workspace_name_for, so recompute the forward
# name for every worktree and compare — no parsing of the name itself (repo
# names may contain the separator). Fails for names that no worktree maps to
# (hand-named workspaces, bare main-worktree names) and for names produced
# by more than one container.
container_for_worktree() {
    local target="$1" container dir found=""
    [[ -n "$target" ]] || return 1
    for container in $(workspace_containers); do
        for dir in "$container"/*/; do
            dir="${dir%/}"
            [[ -e "$dir/.git" ]] || continue
            [[ "$(workspace_name_for "$container" "$(basename "$dir")")" == "$target" ]] || continue
            [[ -n "$found" ]] && return 1
            found="$container"
        done
    done
    [[ -n "$found" ]] && echo "$found"
}

# Prompt for a workspace container with fuzzel; prints its absolute path.
# Returns 1 when the prompt is dismissed (a normal cancel, not an error).
# --only-match rejects free text, so the result is always a real container.
pick_container() {
    local repo
    repo=$(workspace_containers | xargs -rn1 basename |
        fuzzel --dmenu --only-match --prompt "Repository: ") || return 1
    [[ -n "$repo" ]] || return 1
    echo "$WORKVC_BASE/$repo"
}

# Prompt for the base branch to fork new work off; prints the ref to fork from
# (a full refs/... path, or whatever free text was typed).
#   return 1  prompt dismissed — a normal cancel, caller should exit quietly
#   return 2  real failure — already reported via notify-send
#
# The menu merges refs/heads and refs/remotes/origin into one entry per branch
# name, newest commit first, with origin's default branch pinned on top. A name
# that exists only locally is marked "(local)": the mark answers "is this on the
# remote?", nothing more — an unmarked name may still resolve to its local ref.
#
# Resolution deliberately fetches BEFORE comparing dates: refs/remotes is only
# as fresh as the last fetch, so "newest wins" against stale refs would pick a
# local ref that the remote has already moved past. A tie goes to the local ref
# (in practice the two are the same commit, so the base is identical anyway).
pick_base_branch() {
    local container="$1" title="${2:-Pick Base Branch}"

    local default_branch
    default_branch=$(git -C "$container" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null) || default_branch=""
    default_branch=${default_branch#origin/}

    local list
    list=$({
        git -C "$container" for-each-ref --format='%(committerdate:unix) %(refname:lstrip=3) r' refs/remotes/origin
        git -C "$container" for-each-ref --format='%(committerdate:unix) %(refname:lstrip=2) l' refs/heads
    } | awk '
        $3 == "r" && $2 == "HEAD" { next }
        { if (!($2 in date) || $1 > date[$2]) date[$2] = $1
          if ($3 == "r") remote[$2] = 1 }
        END { for (n in date) printf "%s\t%s%s\n", date[n], n, (n in remote ? "" : " (local)") }
    ' | sort -rn | cut -f2-)

    if [[ -z "$list" ]]; then
        notify-send -u critical "$title Failed" "No branches in $(basename "$container")"
        return 2
    fi

    # Pin the default branch on top, dropping the copy the date sort produced.
    local menu="$list"
    if [[ -n "$default_branch" ]]; then
        menu=$(printf '%s\n' "$default_branch"; grep -vxF "$default_branch" <<<"$list")
    fi

    # No --only-match here: free text is how you base off a tag or a raw SHA.
    local pick
    pick=$(fuzzel --dmenu --prompt "Base branch: " <<<"$menu") || return 1
    [[ -n "$pick" ]] || return 1
    pick=${pick% (local)}

    local has_remote="" has_local=""
    git -C "$container" show-ref --verify --quiet "refs/remotes/origin/$pick" && has_remote=1
    git -C "$container" show-ref --verify --quiet "refs/heads/$pick" && has_local=1

    # Free text: not a branch at all, so it has to name some other commit-ish.
    if [[ -z "$has_remote" && -z "$has_local" ]]; then
        if ! git -C "$container" rev-parse --verify --quiet "$pick^{commit}" >/dev/null; then
            notify-send -u critical "$title Failed" "Not a branch, tag or commit: $pick"
            return 2
        fi
        echo "$pick"
        return 0
    fi

    if [[ -n "$has_remote" ]]; then
        with_notification "$title" "Fetching $pick..." \
            git -C "$container" fetch origin "$pick" >/dev/null 2>&1 || true
    fi

    if [[ -n "$has_remote" && -n "$has_local" ]]; then
        local remote_date local_date
        remote_date=$(git -C "$container" log -1 --format=%ct "refs/remotes/origin/$pick")
        local_date=$(git -C "$container" log -1 --format=%ct "refs/heads/$pick")
        if ((remote_date > local_date)); then
            echo "refs/remotes/origin/$pick"
        else
            echo "refs/heads/$pick"
        fi
    elif [[ -n "$has_remote" ]]; then
        echo "refs/remotes/origin/$pick"
    else
        echo "refs/heads/$pick"
    fi
}

# Create branch <name> off <base_ref>, then a worktree of the same name in the
# container. Branch first (rather than `wt-add -b`) so the worktree path stays
# wt-add's first argument, which is what its closing `cd` relies on — and, when
# the base is a remote ref, it sets up remote tracking for free. Rolls the
# branch back if the worktree fails, so a retry starts from a clean slate.
# Returns 1 on failure; the caller reports it.
create_worktree_branch() {
    local container="$1" base_ref="$2" name="$3"
    cd "$container" || return 1
    git branch "$name" "$base_ref" || return 1
    with_notification "Setting up worktree..." "$name" fish -c "wt-add $name $name" || {
        git branch -D "$name" 2>/dev/null || true
        return 1
    }
}

# Find the container whose origin remote matches a GitHub "org/repo" slug.
container_for_github_slug() {
    local slug="$1" container remote
    local slug_lc="${slug,,}"
    for container in $(workspace_containers); do
        remote=$(git -C "$container" remote get-url origin 2>/dev/null) || continue
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

# Workspace label derived from a working directory: the worktree's workspace
# name for paths inside a workspace container (matching the niri workspace
# names resume-workspace assigns, see workspace_name_for), otherwise the
# directory's basename.
workspace_name_from_cwd() {
    local cwd="${1:-}" container
    [[ -n "$cwd" ]] || return 0
    container=$(container_for_cwd "$cwd")
    if [[ -n "$container" && "$cwd" != "$container" ]]; then
        local rel="${cwd#"$container"/}"
        workspace_name_for "$container" "${rel%%/*}"
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

# Notification bookkeeping for swaync-focus-dismiss: it clears a Claude Code
# notification once you focus the window that raised it, but the notification
# protocol gives the daemon no way to tie one to a window. Record the mapping
# out of band instead — one file per notification, named by notification id,
# holding the niri window id.
#
# Registering is best-effort throughout: with no niri window id, no runtime dir
# or no daemon running, the notification simply behaves as it did before (it
# waits for a click or a middle-click).
CLAUDE_NOTIFY_DIR="${XDG_RUNTIME_DIR:-/tmp}/claude-notifications"

register_claude_notification() {
    local notif_id="${1:-}" window_id="${2:-}"
    [[ "$notif_id" =~ ^[0-9]+$ && "$window_id" =~ ^[0-9]+$ ]] || return 0
    mkdir -p "$CLAUDE_NOTIFY_DIR" 2>/dev/null || return 0
    printf '%s\n' "$window_id" > "$CLAUDE_NOTIFY_DIR/$notif_id" 2>/dev/null || true
    return 0
}

# Close a notification by id via the freedesktop D-Bus call (daemon-agnostic:
# works with swaync, mako, or anything spec-compliant). No-op on a dead id.
close_notification() {
    local notif_id="${1:-}"
    [[ "$notif_id" =~ ^[0-9]+$ ]] || return 0
    gdbus call --session \
        --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.CloseNotification \
        "$notif_id" >/dev/null 2>&1 || true
    return 0
}

# Drop a registration once the notification is gone for any other reason (the
# hook saw its action, or --wait returned). The daemon prunes leftovers too, so
# this is only about not leaving obvious litter behind.
unregister_claude_notification() {
    local notif_id="${1:-}"
    [[ "$notif_id" =~ ^[0-9]+$ ]] || return 0
    rm -f "$CLAUDE_NOTIFY_DIR/$notif_id" 2>/dev/null || true
    return 0
}

# seed_claude_local_md <worktree_dir> <purpose>
# Write the worktree's CLAUDE.local.md: the purpose text (may be multi-line)
# followed by the container's workspace_claude_guidance output, if any.
# Requires load_workspacerc to have run (it defines the guidance function).
# Either part may be empty — a workspace with no stated purpose, a container
# that opts out of guidance — so join only the parts that are actually there,
# and write no file at all when both are empty.
seed_claude_local_md() {
    local worktree_dir="$1" purpose="$2"
    local guidance body
    guidance=$(workspace_claude_guidance "$worktree_dir")
    if [[ -n "$purpose" && -n "$guidance" ]]; then
        body="$purpose

$guidance"
    else
        body="${purpose:-$guidance}"
    fi
    [[ -n "$body" ]] || return 0
    printf '%s\n' "$body" >"$worktree_dir/CLAUDE.local.md"
}

# Source a container's .workspacerc and fill in defaults. Guarantees
# workspace_urls / workspace_launch are defined.
load_workspacerc() {
    local container="$1"
    unset -f workspace_urls workspace_launch workspace_claude_guidance 2>/dev/null || true

    if [[ -f "$container/.workspacerc" ]]; then
        source "$container/.workspacerc"
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
