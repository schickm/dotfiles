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

define-command add-npm-to-user-mode \
	-override \
	-hidden %{

        map global user n ': enter-user-mode npm<ret>' -docstring 'npm specific helpers'
}

hook global WinSetOption filetype=javascript add-npm-to-user-mode 
hook global BufCreate .*/?package\.json add-npm-to-user-mode
