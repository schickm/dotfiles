
declare-user-mode markdown

hook global WinSetOption filetype=markdown %{
    set buffer formatcmd 'npx prettier --stdin-filepath=${kak_buffile} --parser markdown'
    hook -group markdown-format-hooks window BufWritePre .* format
    map global user m ': enter-user-mode markdown<ret>' -docstring 'markdown commands'

}

hook global WinSetOption filetype=(?!markdown).* %{
    remove-hooks window markdown-format-hooks
}

hook global WinSetOption filetype=markdown %{
    add-highlighter window/wrap wrap -word

	hook window WinSetOption filetype=(?!markdown).* %{
	    remove-highlighter window/wrap
	}
}

