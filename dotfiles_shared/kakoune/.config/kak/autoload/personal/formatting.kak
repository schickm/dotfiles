# The best way to deal with setting this is to use direnv
#
# Examples for future implementations
#
# Javascript
#    export kak_javascript_formatcmd='prettierd %%val{buffile}'

# TODO - this needs to be generalized currently javascript & html is just
# duplicate code
define-command setup-javascript-autoformatting \
	-docstring 'setup-javascript-autoformatting: installed prettierd if necessary and autoformats on save' \
	-override %{

	evaluate-commands %sh{
		kecho() {
			printf "echo %s\n" "$*"
		}

		prettierd --version >/dev/null 2>/dev/null
		return_code=$?

		if [ "$return_code" -ne 0 ]; then
		  kecho "installing prettierd";
		  npm i -g @fsouza/prettierd >/dev/null 2>/dev/null
		else
		  kecho "installed"
		fi

	}
}

evaluate-commands %sh{
    if [ -z "$kak_javascript_formatcmd" ]; then
        printf "echo -debug 'formatting.kak - javascript automatic formatting will be disabled, environment var \"kak_javascript_formatcmd\" not defined'"
    else
	    printf "
	        hook global WinSetOption filetype=(javascript|typescript|json) %%{
	            set buffer formatcmd \"$kak_javascript_formatcmd\"
	            hook -group javascript-format-hooks window BufWritePre .* format
	            hook -once -always window WinSetOption filetype=.* %%{ remove-hooks window javascript-format-hooks }
	        }
	    "
    fi
}

evaluate-commands %sh{
    if [ -z "$kak_html_formatcmd" ]; then
        printf "echo -debug 'formatting.kak - html automatic formatting will be disabled, environment var \"kak_html_formatcmd\" not defined'"
    else
	    printf "
	        hook global WinSetOption filetype=html %%{
	            set buffer formatcmd \"$kak_html_formatcmd\"
	            hook -group html-format-hooks window BufWritePre .* format
	            hook -once -always window WinSetOption filetype=.* %%{ remove-hooks window html-format-hooks }
	        }
	    "
    fi
}

hook global WinSetOption deno_active=true %{
	set buffer formatcmd 'deno fmt -'
	hook -group deno-hooks window BufWritePre .* format
}

hook global WinSetOption deno_active=false %{
	remove-hooks window deno-hooks
}


hook global WinSetOption filetype=yaml %{
	set buffer formatcmd "prettierd %val{buffile}"
	# set buffer formatcmd 'cat ${format_file_in} | npx prettier --stdin --parser yaml > ${format_file_out}'
    hook -group yaml-format-hooks window BufWritePre .* format
}

hook global WinSetOption filetype=(?!yaml).* %{
    remove-hooks window yaml-format-hooks
}

hook global WinSetOption filetype=rust %{
	set window formatcmd 'rustfmt'
	hook -group rust-format-hooks window BufWritePre .* format
}

hook global WinSetOption filetype=(?!rust).* %{
    remove-hooks window rust-format-hooks
}

hook global BufCreate .*\.kakrc\.local %{
    set buffer filetype kak
}

hook global BufCreate .*\.aws/config %{
    set buffer filetype ini
}
