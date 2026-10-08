#!/bin/bash

# Automatically clean up git worktrees whose GitHub PRs have been merged,
# or that have no PR and no commits beyond the main branch,
# across every repo container in ~/workvc (see worktree-lib.sh).
# Exits non-zero if any worktree has uncommitted or unmerged work.
# When run from a terminal (stdin and stdout are TTYs; not the case under
# systemd), each such error instead shows the worktree's diff and prompts to
# open a kitty terminal there, force the removal, or skip.
# Usage: github-worktree-cleanup.sh [--dry-run]

source "$(dirname "$(readlink -f "$0")")/worktree-lib.sh"

dry_run=0
if [ "${1:-}" = "--dry-run" ] || [ "${1:-}" = "-n" ]; then
    dry_run=1
    echo "DRY RUN: no worktrees will be removed"
fi

had_errors=0

interactive=0
if [ -t 0 ] && [ -t 1 ]; then
    interactive=1
fi

exclude_worktrees=(
    "master"
    "main"
    "trunk"
)

is_excluded() {
    local dir_name="$1"
    for excluded in "${exclude_worktrees[@]}"; do
        if [ "$dir_name" = "$excluded" ]; then
            return 0
        fi
    done
    return 1
}

# Niri workspaces are named after worktree dir basenames (resume-worktree /
# niri-create-workspace; main worktrees get a repo prefix via
# workspace_name_for, but those are excluded from cleanup anyway), so a
# same-named workspace with windows means the worktree's apps are still
# running — removing the worktree out from under them leaves a zombie
# workspace. Snapshot once; if niri isn't reachable
# (e.g. headless run) the check never matches and cleanup proceeds as before.
niri_workspaces=$(niri msg --json workspaces 2>/dev/null || true)

workspace_has_windows() {
    local name="$1"
    [ -n "$niri_workspaces" ] || return 1
    jq -e --arg name "$name" \
        '.[] | select(.name == $name and .active_window_id != null)' \
        >/dev/null 2>&1 <<<"$niri_workspaces"
}

# Extra args (e.g. --force) go to `git worktree remove` via wt-remove.
remove_worktree() {
    local wt_path="$1" branch="$2"
    shift 2
    if [ "$dry_run" -eq 1 ]; then
        echo "  Would remove worktree $wt_path and branch $branch"
        return 0
    fi
    # wt-remove (fish) runs the container's .wt-removerc hook before
    # removing — same delegation takeover-pr uses for wt-add. upfind
    # resolves the hook from cwd, which is the repo container here. The
    # hook only reads $argv[1], so the path must come before any flags.
    # -D: a squash-merged branch is never an ancestor of main, so -d would
    # refuse; callers have already proved its changes are in main (or the
    # user chose to force it).
    fish -c 'wt-remove $argv' "$wt_path" "$@" && git branch -D "$branch"
}

# Uncommitted changes, untracked files, and commits whose changes aren't in
# main, paged. Reads $main_branch from the calling cleanup_repo.
show_worktree_diff() {
    local wt_path="$1" branch="$2"
    {
        echo "### git status: $wt_path"
        git -C "$wt_path" -c color.ui=always status --short
        echo
        echo "### Uncommitted changes (vs HEAD)"
        git -C "$wt_path" -c color.ui=always diff HEAD
        echo
        echo "### Commits on $branch whose changes are not in origin/$main_branch"
        git -c color.ui=always log -p --cherry-pick --right-only \
            "origin/$main_branch...$branch" 2>/dev/null
    } | less -RFX
}

# Report a per-worktree error. Non-interactive runs flag it for the exit
# status; interactive runs let the user inspect and resolve it instead.
worktree_error() {
    local message="$1" wt_path="$2" branch="$3" choice
    echo "  ERROR: $message" >&2
    if [ "$interactive" -eq 0 ]; then
        had_errors=1
        return
    fi

    show_worktree_diff "$wt_path" "$branch"
    # Prompts read /dev/tty: stdin is the `git worktree list` loop.
    while true; do
        read -r -n1 -p "  [t]erminal, [d]elete anyway, [s]kip? " choice </dev/tty
        echo
        case "$choice" in
            t)
                setsid -f kitty --directory "$wt_path" >/dev/null 2>&1
                ;;
            d)
                remove_worktree "$wt_path" "$branch" --force || {
                    echo "  ERROR: forced removal failed for $branch" >&2
                    had_errors=1
                }
                return
                ;;
            s)
                echo "  Skipping $branch"
                return
                ;;
        esac
    done
}

cleanup_repo() {
    local repo_dir="$1"

    echo "=== Processing repo: $repo_dir ==="

    cd "$repo_dir" || {
        echo "ERROR: cannot cd into $repo_dir" >&2
        had_errors=1
        return
    }

    # Derive GitHub owner/repo slug from remote URL
    local remote_url github_repo
    remote_url=$(git remote get-url origin 2>/dev/null)
    github_repo="${remote_url##*github.com?}"
    github_repo="${github_repo%.git}"
    if [ -z "$github_repo" ]; then
        echo "ERROR: could not derive GitHub repo slug from remote URL for $repo_dir" >&2
        had_errors=1
        return
    fi

    git fetch --prune

    # Auto-detect main branch
    local main_branch
    main_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
    if [ -z "$main_branch" ]; then
        if git show-ref --verify --quiet refs/remotes/origin/main; then
            main_branch=main
        elif git show-ref --verify --quiet refs/remotes/origin/master; then
            main_branch=master
        else
            echo "ERROR: could not detect main branch for $repo_dir" >&2
            had_errors=1
            return
        fi
    fi

    # Parse worktree list to find non-main worktrees
    local current_path="" current_branch="" local_dir_name unpushed open_prs merged_prs

    while IFS= read -r line; do
        if [[ "$line" =~ ^worktree\ (.+) ]]; then
            current_path="${BASH_REMATCH[1]}"
            current_branch=""
        elif [[ "$line" =~ ^branch\ refs/heads/(.+) ]]; then
            current_branch="${BASH_REMATCH[1]}"
        elif [ -z "$line" ]; then
            # End of worktree entry — process it
            if [ -n "$current_branch" ] && [ "$current_branch" != "$main_branch" ] && [ -n "$current_path" ]; then
                # Corvid Worktrees live under a Workspace Directory, outside the
                # container, and are not this script's to remove — a fresh one
                # with no commits would otherwise match "no PR, no commits".
                case "$current_path" in
                "$repo_dir"/*) ;;
                *)
                    echo "  Skipping worktree outside this container: $current_path"
                    current_path=""
                    current_branch=""
                    continue
                    ;;
                esac

                # Check if worktree directory is excluded
                local_dir_name="${current_path##*/}"
                if is_excluded "$local_dir_name"; then
                    echo "  Skipping excluded worktree: $local_dir_name"
                    current_path=""
                    current_branch=""
                    continue
                fi

                echo "  Checking worktree: $current_path (branch: $current_branch)"

                # Check PR status to decide what to do
                open_prs=$(gh pr list --repo "$github_repo" --state open --head "$current_branch" --json number --jq 'length' 2>/dev/null || echo "0")
                merged_prs=$(gh pr list --repo "$github_repo" --state merged --head "$current_branch" --json number --jq 'length' 2>/dev/null || echo "0")

                # A branch with no PR and no commits beyond main holds no work
                # of its own (a scratch or abandoned worktree), so it is as
                # safe to remove as a merged one.
                no_pr_empty=0
                unpushed=""
                if [ "$open_prs" -eq 0 ] && [ "$merged_prs" -eq 0 ]; then
                    unpushed=$(git rev-list --count "origin/$main_branch..$current_branch" 2>/dev/null) || unpushed=""
                    [ "$unpushed" = "0" ] && no_pr_empty=1
                fi

                if [ "$open_prs" -eq 0 ] && [ "$merged_prs" -eq 0 ] && [ "$no_pr_empty" -eq 0 ]; then
                    if [ -n "$unpushed" ]; then
                        echo "  Skipping $current_branch (no PR found, $unpushed commit(s) not in $main_branch)"
                    else
                        worktree_error "could not compare $current_branch with origin/$main_branch, skipping" \
                            "$current_path" "$current_branch"
                    fi
                elif [ "$open_prs" -gt 0 ]; then
                    echo "  Skipping $current_branch (PR is open)"
                elif workspace_has_windows "$local_dir_name"; then
                    echo "  Skipping $current_branch (niri workspace still has windows)"
                elif [ -n "$(git -C "$current_path" status --porcelain 2>/dev/null)" ]; then
                    if [ "$no_pr_empty" -eq 1 ]; then
                        # Without a PR, local changes are work in progress,
                        # not leftovers — skip quietly rather than error.
                        echo "  Skipping $current_branch (no PR found, has uncommitted or untracked changes)"
                    else
                        worktree_error "$current_path has uncommitted or untracked changes, skipping" \
                            "$current_path" "$current_branch"
                    fi
                else
                    if [ "$no_pr_empty" -eq 1 ]; then
                        reason="no PR, no commits beyond $main_branch"
                    else
                        reason="PR merged"
                        # PR is merged — check for unpushed local commits. Compare
                        # by patch (git cherry) rather than ancestry: squash- and
                        # rebase-merges land the changes in main under different
                        # SHAs, so rev-list would flag them forever.
                        unpushed=$(git cherry "origin/$main_branch" "$current_branch" 2>/dev/null | grep -c '^+')
                    fi
                    if [ "$unpushed" -gt 0 ]; then
                        worktree_error "$current_branch has $unpushed local commit(s) whose changes are not in $main_branch, skipping (PR merged but local commits may be lost)" \
                            "$current_path" "$current_branch"
                    else
                        [ "$dry_run" -eq 1 ] || echo "  Removing worktree $current_path ($reason)"
                        remove_worktree "$current_path" "$current_branch" ||
                            worktree_error "failed to remove worktree or branch for $current_branch" \
                                "$current_path" "$current_branch"
                    fi
                fi
            fi
            current_path=""
            current_branch=""
        fi
    done < <(git worktree list --porcelain && echo "")
}

containers=$(repo_containers)
if [ -z "$containers" ]; then
    echo "ERROR: no repo containers found under $WORKVC_BASE" >&2
    exit 1
fi

while IFS= read -r container; do
    cleanup_repo "$container"
done <<<"$containers"

if [ "$had_errors" -ne 0 ]; then
    echo "Finished with errors" >&2
    exit 1
fi

echo "Worktree cleanup complete"
