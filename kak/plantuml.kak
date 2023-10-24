define-command render-plantuml \
	-override \
	-docstring "renders plantuml of current buffer" %{
	async-command "java -Djava.awt.headless=true -jar ~/vc/dotfiles/plantuml.jar ""%val{buffile}"""
}

hook global WinSetOption filetype=plantuml %{
    hook window BufWritePost .* render-plantuml
}
