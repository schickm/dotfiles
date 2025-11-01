function wt-remove \
    --wraps "git worktree remove" \
    --description "simple wrapper around 'git worktree remove'. Currently does nothing extra"

    git worktree remove $argv
end
