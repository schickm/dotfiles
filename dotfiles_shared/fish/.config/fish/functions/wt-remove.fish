function wt-remove \
    --wraps "git worktree remove" \
    --description "wraps git worktree remove, and runs the closest .wt-removerc file it can find"

    # Unlike wt-add (hook after add), the hook runs *before* removal: it
    # clears state that would make the removal fail or leave orphans
    # (root-owned files from docker, the worktree's compose stack).
    # 2>/dev/null: no hook is the common case (and journal noise under the
    # nightly github-worktree-cleanup run, which delegates to this function).
    set removerc (upfind .wt-removerc 2>/dev/null)

    if test $status -eq 0
        /bin/sh $removerc $argv[1]; or return
    end

    git worktree remove $argv
end
