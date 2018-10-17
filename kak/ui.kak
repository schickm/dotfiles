add-highlighter global/ number-lines -hlcursor
colorscheme solarized-dark

# Show git gutter always
hook global WinCreate .* %{
    git show-diff
    add-highlighter window/ show-matching
}

# continously update git gutter
hook global NormalIdle .* %{
    git update-diff
}
