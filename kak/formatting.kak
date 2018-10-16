hook global WinSetOption filetype=javascript %{
    set buffer formatcmd 'cat ${format_file_in} | yarn -s prettier --stdin-filepath ${kak_buffile} --stdin > ${format_file_out}'
    hook -group javascript-format-hooks window BufWritePre .* format
}


hook global WinSetOption filetype=(?!javascript).* %{
    remove-hooks window javascript-format-hooks
}
