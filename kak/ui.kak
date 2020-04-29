add-highlighter global/ number-lines -hlcursor
colorscheme solarized-light

hook global WinCreate .* %{
    add-highlighter window/ show-matching
	# Show git gutter always when viewing file under version control
	conditionally-enable-git-gutter
}

hook global WinSetOption filetype=markdown %{
    add-highlighter window/ wrap
    autowrap-enable
}

hook global WinSetOption filetype=(?!markdown).* %{
    remove-highlighter window/wrap
}
