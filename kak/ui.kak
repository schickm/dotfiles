add-highlighter global/ number-lines -hlcursor


# Face customizations
face global GitDiffFlags default
face global MatchingChar red,white+b

# Show git gutter always
hook global WinCreate .* %{
    git show-diff
    add-highlighter window show_matching
}

# continously update git gutter
hook global NormalIdle .* %{
    git update-diff
}
