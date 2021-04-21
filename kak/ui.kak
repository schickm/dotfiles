add-highlighter global/ number-lines -hlcursor
add-highlighter global/ show-matching
colorscheme solarized-light

hook global WinCreate .* %{
	# Show git gutter always when viewing file under version control
	conditionally-enable-git-gutter
}

hook global WinSetOption filetype=markdown %{
    add-highlighter window/wrap wrap -word

	hook window WinSetOption filetype=(?!markdown).* %{
	    remove-highlighter window/wrap
	}
}

