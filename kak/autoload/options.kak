hook -once global KakBegin .* %{

	# global 4 space indent
	set global indentwidth 4
	set global aligntab false

	# always use git grep
	set global grepcmd 'git grep -n'
	set global autoreload yes

	set global ui_options terminal_assistant=none terminal_info_max_width=100
}
