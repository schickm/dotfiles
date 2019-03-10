
evaluate-commands %sh{
    if ! command -v kak-lsp > /dev/null 2>&1; then
        echo "echo -debug %{Dependency unmet: kak-lsp, please install it to use a language servers}"
    fi
    if ! command -v typescript-language-server > /dev/null 2>&1; then
        echo "echo -debug %{Dependency unmet: typescript-language-server, please install it to use kak-lsp}"
    fi
}

eval %sh{kak-lsp --kakoune -s $kak_session}
lsp-enable
hook global WinSetOption filetype=javascript %{
    lsp-enable-window
}

# turn on verbose logging for kak-lsp
# nop %sh{ (kak-lsp -s $kak_session -vvv ) > /tmp/kak-lsp.log 2>&1 < /dev/null & }
