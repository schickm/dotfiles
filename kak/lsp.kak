
evaluate-commands %sh{
    if ! command -v kak-lsp > /dev/null 2>&1; then
        echo "echo -debug %{Dependency unmet: kak-lsp, please install it to use a language servers}"
    fi
}

eval %sh{kak-lsp --kakoune -s $kak_session}

hook global WinSetOption filetype=(typescript) %{
    # enable to setup debug logging of kak-lsp
    set global lsp_cmd "kak-lsp -s %val{session} -vvv --log /tmp/kak-lsp.log --config kak-lsp.toml"
    lsp-enable-window
    lsp-auto-hover-enable
}

