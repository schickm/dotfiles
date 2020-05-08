def grep-or-prompt \
	-override \
	-docstring 'Grep current selection if greater then 1 character, or prompt for input' \
	%{ evaluate-commands %sh{

	if test "${#kak_selection}" -gt 1 ; then
		echo "grep $kak_selection"
	else
		echo "prompt grep: %{ grep %val{text} }"
	fi
}}

