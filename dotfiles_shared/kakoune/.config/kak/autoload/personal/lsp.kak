
evaluate-commands %sh{
    if ! command -v kak-lsp > /dev/null 2>&1; then
        echo "echo -debug %{Dependency unmet: kak-lsp, please install it to use a language servers}"
    fi
}

eval %sh{kak-lsp --kakoune -s "$kak_session"}
# set global lsp_cmd "kak-lsp -s %val{session} -vvv --log /tmp/kak-lsp.log"
set global lsp_cmd "kak-lsp -s %val{session}"

define-command -override -hidden lsp-show-error -params 1 -docstring "Render error" %{
    echo -debug "kak-lsp:" %arg{1}
}

hook global WinSetOption filetype=(typescript|terraform|python) %{
    map window user l ': enter-user-mode lsp<ret>' -docstring 'lsp commands'
    # enable to setup debug logging of kak-lsp
    lsp-enable-window
    lsp-auto-hover-enable
}

hook global WinSetOption filetype=(terraform|python) %{
    hook window BufWritePre .* lsp-formatting-sync
}
