# grep mode
declare-user-mode grep
map global grep n ': grep-next-match<ret>' -docstring 'goto next match'
map global grep p ': grep-previous-match<ret>' -docstring 'goto previous match'
map global grep <ret> ': grep-jump<ret>' -docstring 'goto match'
map global grep j ': execute-keys j<ret>' -docstring 'next line'
map global grep k ': execute-keys k<ret>' -docstring 'previous line'
map global grep b ': buffer *grep*<ret>' -docstring 'back to matches'


def grep-lock \
	-params 2 \
	-hidden \
	-override %{

	grep %arg{1} %arg{2}
	enter-user-mode -lock grep
}

def enter-grep-mode \
	-override \
	-docstring 'Grep current selection if greater than 1 character and enter grep mode (lock), or prompt for input' \
	%{ evaluate-commands %sh{

	target="${kak_grep_files:-.}";

	if test "${#kak_selection}" -gt 1 ; then
		escaped=$(echo $kak_selection | sed "s/'/''/")
		printf "
			grep-lock '$escaped' '$target'
		"
	else
		echo "prompt 'grep (${target}):' %{ grep-lock %val{text} $target }"
	fi
}}

