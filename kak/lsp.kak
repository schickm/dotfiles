
evaluate-commands %sh{
    if ! command -v kak-lsp > /dev/null 2>&1; then
        echo "echo -debug %{Dependency unmet: kak-lsp, please install it to use a language servers}"
    fi
}

eval %sh{kak-lsp --kakoune -s $kak_session}
set global lsp_cmd "kak-lsp -s %val{session} --log /tmp/kak-lsp.log --config kak-lsp.toml"

hook global WinSetOption filetype=(typescript|terraform) %{
    map window user l ': enter-user-mode lsp<ret>' -docstring 'lsp commands'
}

hook global WinSetOption filetype=terraform %{
    hook window BufWritePre .* lsp-formatting-sync
}

hook global WinSetOption filetype=(typescript|terraform) %{
    # enable to setup debug logging of kak-lsp
    lsp-enable-window
    lsp-auto-hover-enable
}

