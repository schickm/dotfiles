
evaluate-commands %sh{
    if ! command -v kak-lsp > /dev/null 2>&1; then
        echo "echo -debug %{Dependency unmet: kak-lsp, please install it to use a language servers}"
    fi
}

eval %sh{kak-lsp --kakoune -s "$kak_session"}
set global lsp_cmd "kak-lsp -s %val{session} --log /tmp/kak-lsp.log --config kak-lsp.toml"

define-command -override -hidden lsp-show-error -params 1 -docstring "Render error" %{
    echo -debug "kak-lsp:" %arg{1}
}

hook global WinSetOption filetype=(typescript|terraform) %{
    map window user l ': enter-user-mode lsp<ret>' -docstring 'lsp commands'
    # enable to setup debug logging of kak-lsp
    lsp-enable-window
}

hook global WinSetOption filetype=terraform %{
    hook window BufWritePre .* lsp-formatting-sync
}
