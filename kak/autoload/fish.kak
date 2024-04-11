hook global WinSetOption filetype=(fish) %{
    set buffer formatcmd fish_indent
    hook window BufWritePre .* format
}
