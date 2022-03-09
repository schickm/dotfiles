define-command open-npm-homepage \
	-override \
	-docstring 'searches npm for first arg and opens its homepage' \
	-params 1 \
	%{
	evaluate-commands %sh{
    		open $(npm view "$1" homepage)
	}
}

declare-user-mode npm
map global npm h ': open-npm-homepage %val{selection}<ret>' -docstring 'open homepage for given selection'


hook global WinSetOption filetype=javascript %{
    map global user n ': enter-user-mode npm<ret>' -docstring 'npm specific helpers'
}
