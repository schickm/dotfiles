
evaluate-commands %sh{
    if ! command -v kak-lsp > /dev/null 2>&1; then
        echo "echo -debug %{Dependency unmet: kak-lsp, please install it to use a language servers}"
    fi
    if ! command -v typescript-language-server > /dev/null 2>&1; then
        echo "echo -debug %{Dependency unmet: typescript-language-server, please install it to use kak-lsp}"
    fi
}

eval %sh{kak-lsp --kakoune -s $kak_session}
# enable to setup debug logging of kak-lsp
# set global lsp_cmd "kak-lsp -s %val{session} -vvv --log /tmp/kak-lsp.log"

hook global WinSetOption filetype=(javascript) %{
    lsp-enable-window
}
