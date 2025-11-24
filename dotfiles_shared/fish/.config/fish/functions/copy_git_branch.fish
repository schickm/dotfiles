#!/usr/bin/env fish .

function copy_git_branch
    git branch --show-current | wl-copy
end
