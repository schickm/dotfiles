hook global WinSetOption filetype=javascript %{
	complete-command git-edit shell-script-candidates %{
		git ls-files | sed -e 's/index.js/_____index.js/' | sort | sed -e 's/_____//'
	}
}
