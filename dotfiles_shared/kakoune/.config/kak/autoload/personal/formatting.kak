# The best way to deal with setting this is to use direnv
#
# Examples for future implementations
#
# Javascript
#    export kak_javascript_formatcmd='prettierd %%val{buffile}'

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

# Define formatters entirely via the environment (e.g. in a direnv .envrc):
#
#   export kak_formatter_javascript='javascript|typescript|json prettierd %val{buffile}'
#   export kak_formatter_html='html prettierd %val{buffile}'
#
# Convention: kak_formatter_<anything> = "<filetype-regex> <command...>"
#   - first whitespace-delimited token = filetype regex used in the hook
#   - everything after the first space  = the formatcmd
#
# Adding a formatter for a new filetype needs no edit here, just a new env var.
evaluate-commands %sh{
    formatters=$(env | grep '^kak_formatter_')

    if [ -z "$formatters" ]; then
        printf "echo -debug %s\n" "'formatting.kak - no kak_formatter_* env vars set, automatic formatting disabled'"
        exit 0
    fi

    printf '%s\n' "$formatters" | while IFS='=' read -r name value; do
        filetypes="${value%% *}"   # first token
        formatcmd="${value#* }"    # remainder

        # skip malformed entries (no space => no command part)
        if [ "$filetypes" = "$value" ]; then
            printf "echo -debug %s\n" "'formatting.kak - ignoring $name, expected \"<filetype-regex> <command>\"'"
            continue
        fi

        # Kakoune hook group names allow only [a-zA-Z0-9-]; the var name has
        # underscores, so sanitize it (kak_formatter_my_lang -> my-lang-format-hooks).
        group="$(printf '%s' "${name#kak_formatter_}" | tr -c 'a-zA-Z0-9' '-')-format-hooks"

        printf "echo -debug %s\n" "'formatting.kak - registered formatter for filetype=($filetypes): $formatcmd'"
        printf '%s' "
            hook global WinSetOption filetype=($filetypes) %{
                set buffer formatcmd \"$formatcmd\"
                hook -group $group window BufWritePre .* format
                hook -once -always window WinSetOption filetype=.* %{ remove-hooks window $group }
            }
        "
    done
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
