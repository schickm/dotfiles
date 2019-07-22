# Handy Vars for running formatting
#
# kak_buffile     - origional name of file that had the code to be formatted
#
# The best way to deal with setting this is to use direnv
#
# Examples for future implementations
#
# Javascript
#    run() { cat "$1" | npx --quiet prettier --stdin-filepath ${kak_buffile} --stdin; } && run

evaluate-commands %sh{
    if [ -z "$kak_javascript_formatcmd" ]; then
        printf "echo -debug 'formatting.kak - environment var \"kak_javascript_formatcmd\" not defined, javascript automatic formatting will be disabled'"
    else
	    printf "
	        hook global WinSetOption filetype=javascript %%{
	            set buffer formatcmd '$kak_javascript_formatcmd'
	            hook -group javascript-format-hooks window BufWritePre .* format
	        }

	        hook global WinSetOption filetype=(?!javascript).* %%{
	            remove-hooks window javascript-format-hooks
	        }
	    "
    fi

}

hook global WinSetOption filetype=markdown %{
	set buffer formatcmd 'cat ${format_file_in} | npx prettier --stdin --parser markdown --prose-wrap always > ${format_file_out}'
    hook -group markdown-format-hooks window BufWritePre .* format
}

hook global WinSetOption filetype=(?!markdown).* %{
    remove-hooks window markdown-format-hooks
}

