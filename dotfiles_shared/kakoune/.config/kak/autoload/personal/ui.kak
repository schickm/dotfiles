add-highlighter global/ number-lines -hlcursor
add-highlighter global/ show-matching

colorscheme solarized-light
# customized highlighter for max_line_length editorconfig value
hook global WinSetOption autowrap_column=.* %{
	# colors are based on solarized-light theme, but background has value bumped up
	add-highlighter -override window/max_line_length column 101 rgb:93a1a1,rgb:f7f2dc
}


set global ui_options terminal_assistant=none

hook global WinCreate .* %{
	# Show git gutter always when viewing file under version control
	conditionally-enable-git-gutter
}

hook -once global KakBegin .* %{
	# require-module iterm
	# alias global terminal iterm-terminal-window
	set global git_diff_add_char "+"
	set global git_diff_mod_char "~"
}
