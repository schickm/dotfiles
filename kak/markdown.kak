
hook global WinSetOption filetype=markdown %{
    set buffer formatcmd 'npx prettier --stdin-filepath=${kak_buffile} --parser markdown'
    hook -group markdown-format-hooks window BufWritePre .* format
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

