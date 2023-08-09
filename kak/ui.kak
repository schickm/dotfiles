add-highlighter global/ number-lines -hlcursor
add-highlighter global/ show-matching
colorscheme solarized-light

set global ui_options terminal_assistant=none

hook global WinCreate .* %{
	# Show git gutter always when viewing file under version control
	conditionally-enable-git-gutter
}

require-module iterm
alias global terminal iterm-terminal-window
