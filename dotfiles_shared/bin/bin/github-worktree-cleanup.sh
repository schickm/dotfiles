#!/bin/bash

# Automatically clean up git worktrees whose GitHub PRs have been merged.
# Exits non-zero if any worktree has uncommitted or unmerged work.
# Usage: github-worktree-cleanup.sh [--dry-run]

dry_run=0
if [ "${1:-}" = "--dry-run" ] || [ "${1:-}" = "-n" ]; then
    dry_run=1
    echo "DRY RUN: no worktrees will be removed"
fi

had_errors=0

echo "=== Processing repo: /home/matt/workvc/rwgps-ui ==="

exclude_worktrees=(
    "master"
    "pr-review"
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

# Niri workspaces are named after worktree dir basenames (resume-workspace /
# niri-create-workspace), so a same-named workspace with windows means the
# worktree's apps are still running — removing the worktree out from under
# them leaves a zombie workspace. Snapshot once; if niri isn't reachable
# (e.g. headless run) the check never matches and cleanup proceeds as before.
niri_workspaces=$(niri msg --json workspaces 2>/dev/null || true)

workspace_has_windows() {
    local name="$1"
    [ -n "$niri_workspaces" ] || return 1
    jq -e --arg name "$name" \
        '.[] | select(.name == $name and .active_window_id != null)' \
        >/dev/null 2>&1 <<<"$niri_workspaces"
}

if [ ! -d "/home/matt/workvc/rwgps-ui" ]; then
    echo "ERROR: repo directory /home/matt/workvc/rwgps-ui does not exist" >&2
    had_errors=1
else
    cd "/home/matt/workvc/rwgps-ui"

    # Derive GitHub owner/repo slug from remote URL
    remote_url=$(git remote get-url origin 2>/dev/null)
    github_repo="${remote_url##*github.com?}"
    github_repo="${github_repo%.git}"
    if [ -z "$github_repo" ]; then
        echo "ERROR: could not derive GitHub repo slug from remote URL for /home/matt/workvc/rwgps-ui" >&2
        had_errors=1
    fi

    git fetch --prune

    # Auto-detect main branch
    main_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
    if [ -z "$main_branch" ]; then
        if git show-ref --verify --quiet refs/remotes/origin/main; then
            main_branch=main
        elif git show-ref --verify --quiet refs/remotes/origin/master; then
            main_branch=master
        else
            echo "ERROR: could not detect main branch for /home/matt/workvc/rwgps-ui" >&2
            had_errors=1
            main_branch=""
        fi
    fi

    if [ -n "$main_branch" ] && [ -n "$github_repo" ]; then
        # Parse worktree list to find non-main worktrees
        current_path=""
        current_branch=""

        while IFS= read -r line; do
            if [[ "$line" =~ ^worktree\ (.+) ]]; then
                current_path="${BASH_REMATCH[1]}"
                current_branch=""
            elif [[ "$line" =~ ^branch\ refs/heads/(.+) ]]; then
                current_branch="${BASH_REMATCH[1]}"
            elif [ -z "$line" ]; then
                # End of worktree entry — process it
                if [ -n "$current_branch" ] && [ "$current_branch" != "$main_branch" ] && [ -n "$current_path" ]; then
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

                    if [ "$open_prs" -eq 0 ] && [ "$merged_prs" -eq 0 ]; then
                        # No PR found — skip immediately, noting any local divergence
                        unpushed=$(git rev-list --count "origin/$main_branch..$current_branch" 2>/dev/null || echo "0")
                        if [ "$unpushed" -gt 0 ]; then
                            echo "  Skipping $current_branch (no PR found, $unpushed commit(s) not in $main_branch)"
                        else
                            echo "  Skipping $current_branch (no PR found)"
                        fi
                    elif [ "$open_prs" -gt 0 ]; then
                        echo "  Skipping $current_branch (PR is open)"
                    elif workspace_has_windows "$local_dir_name"; then
                        echo "  Skipping $current_branch (niri workspace still has windows)"
                    elif [ -n "$(git -C "$current_path" status --porcelain 2>/dev/null)" ]; then
                        echo "  ERROR: $current_path has uncommitted or untracked changes, skipping" >&2
                        had_errors=1
                    else
                        # PR is merged — check for unpushed local commits
                        unpushed=$(git rev-list --count "origin/$main_branch..$current_branch" 2>/dev/null || echo "0")
                        if [ "$unpushed" -gt 0 ]; then
                            echo "  ERROR: $current_branch has $unpushed local commit(s) not in $main_branch, skipping (PR merged but local commits may be lost)" >&2
                            had_errors=1
                        elif [ "$dry_run" -eq 1 ]; then
                            echo "  Would remove worktree $current_path and branch $current_branch (PR merged)"
                        else
                            echo "  Removing worktree $current_path (PR merged)"
                            git worktree remove "$current_path" && git branch -d "$current_branch" || {
                                echo "  ERROR: failed to remove worktree or branch for $current_branch" >&2
                                had_errors=1
                            }
                        fi
                    fi
                fi
                current_path=""
                current_branch=""
            fi
        done < <(git worktree list --porcelain && echo "")
    fi
fi

if [ "$had_errors" -ne 0 ]; then
    echo "Finished with errors" >&2
    exit 1
fi

echo "Worktree cleanup complete"
