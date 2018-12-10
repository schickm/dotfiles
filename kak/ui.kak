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

hook global WinSetOption filetype=markdown %{
    add-highlighter window/ wrap
}

hook global WinSetOption filetype=(?!markdown).* %{
    remove-highlighter window/wrap
}
