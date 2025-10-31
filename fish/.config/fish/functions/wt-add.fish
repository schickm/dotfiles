function wt-add \
    --wraps "git worktree add" \
    --description "wraps git worktree add, and runs the closest .wt-addrc file it can find"

    git worktree add $argv; or return

    # search for rc file and execute if exists
    set addrc (upfind .wt-addrc)

    if test $status -eq 0
        /bin/sh $addrc $argv[1]; or return
    end

    cd $argv[1]
end
