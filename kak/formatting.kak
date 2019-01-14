# available vars for running formatting
# format_file_in  - name of file that contains code to be formatted
# format_file_out - destination for formatted code
# kak_buffile     - origional name of file that had the code to be formatted
#
# The best way to deal with setting this is to use direnv
#
# Examples for future implementations
#
# Javascript
#    cat ${format_file_in} | yarn -s prettier --stdin-filepath ${kak_buffile} --stdin > ${format_file_out}

evaluate-commands %sh{
    formatcmd='cat ${format_file_in} | npx --quiet prettier --stdin-filepath ${kak_buffile} --stdin > ${format_file_out}'
    if [ -z "$kak_javascript_formatcmd" ]; then
        printf "echo -debug 'formatting.kak - environment var \"kak_javascript_formatcmd\" not defined, using stock version'"
    else
        formatcmd="$kak_javascript_formatcmd"
    fi

    printf "
        hook global WinSetOption filetype=javascript %%{
            set buffer formatcmd '$formatcmd'
            hook -group javascript-format-hooks window BufWritePre .* format
        }

        hook global WinSetOption filetype=(?!javascript).* %%{
            remove-hooks window javascript-format-hooks
        }
    "
}


