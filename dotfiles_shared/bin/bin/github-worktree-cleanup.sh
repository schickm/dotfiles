#!/bin/bash

# Automatically clean up git worktrees whose GitHub PRs have been merged,
# or that have no PR and no commits beyond the main branch,
# across every repo container in ~/workvc (see worktree-lib.sh).
# Exits non-zero if any worktree has uncommitted or unmerged work.
# Usage: github-worktree-cleanup.sh [--dry-run]

source "$(dirname "$(readlink -f "$0")")/worktree-lib.sh"

dry_run=0
if [ "${1:-}" = "--dry-run" ] || [ "${1:-}" = "-n" ]; then
    dry_run=1
    echo "DRY RUN: no worktrees will be removed"
fi

had_errors=0

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
                        echo "  ERROR: could not compare $current_branch with origin/$main_branch, skipping" >&2
                        had_errors=1
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
                        echo "  ERROR: $current_path has uncommitted or untracked changes, skipping" >&2
                        had_errors=1
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
                        echo "  ERROR: $current_branch has $unpushed local commit(s) whose changes are not in $main_branch, skipping (PR merged but local commits may be lost)" >&2
                        had_errors=1
                    elif [ "$dry_run" -eq 1 ]; then
                        echo "  Would remove worktree $current_path and branch $current_branch ($reason)"
                    else
                        echo "  Removing worktree $current_path ($reason)"
                        # wt-remove (fish) runs the container's .wt-removerc
                        # hook before removing — same delegation takeover-pr
                        # uses for wt-add. upfind resolves the hook from cwd,
                        # which is $repo_dir here.
                        # -D: a squash-merged branch is never an ancestor of
                        # main, so -d would refuse; the cherry or rev-list
                        # check above already proved its changes are in main.
                        fish -c 'wt-remove $argv[1]' "$current_path" && git branch -D "$current_branch" || {
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
