
evaluate-commands %sh{
    if ! command -v kak-lsp > /dev/null 2>&1; then
        echo "echo -debug %{Dependency unmet: kak-lsp, please install it to use a language servers}"
    fi
}

# Debug: set-option global lsp_debug true
# Then view logs with: buffer *debug*
eval %sh{kak-lsp}

define-command -override -hidden lsp-show-error -params 1 -docstring "Render error" %{
    echo -debug "kak-lsp:" %arg{1}
}

hook global WinSetOption filetype=(typescript|terraform|python) %{
    map window user l ': enter-user-mode lsp<ret>' -docstring 'lsp commands'
    lsp-enable-window
    lsp-auto-hover-enable
    # Prepend LSP modeline (breadcrumbs, code actions, progress) for this window
    set-option window modelinefmt "%opt{lsp_modeline} %opt{modelinefmt}"
}

hook global WinSetOption filetype=(terraform|python) %{
    hook window BufWritePre .* lsp-formatting-sync
}
