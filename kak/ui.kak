add-highlighter global/ number-lines -hlcursor
colorscheme solarized-dark

# Face customizations
face global GitDiffFlags default
face global MatchingChar red,white+b
face global LineNumberCursor black,rgb:dddddd

# Show git gutter always
hook global WinCreate .* %{
    git show-diff
    add-highlighter window/ show-matching
}

# continously update git gutter
hook global NormalIdle .* %{
    git update-diff
}
