hook global WinSetOption filetype=javascript %{
	complete-command get-edit shell-script-candidates %{
		git ls-files | sed -e 's/index.js/_____index.js/' | sort | sed -e 's/_____//'
	}
}
