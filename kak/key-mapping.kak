# edit with alt-p
map global normal <a-p> ':git-edit '
map global insert <a-p> '<esc>:git-edit '


# map jj to esc
hook global InsertChar j %{ try %{
  exec -draft hH <a-k>jj<ret> d
  exec -with-hooks <esc>
}}

# tig mode
declare-user-mode tig
map global tig b ': tig-blame<ret>' -docstring 'show blame (with tig)'
map global tig s ': suspend-and-resume "tig status"<ret>' -docstring 'show git status (with tig)'
map global tig m ': suspend-and-resume "tig"<ret>' -docstring 'show main view (with tig)'

# lint mode
declare-user-mode lint
map global lint n ': lint-next-error<ret>: lint-show<ret>' -docstring 'next lint error'
map global lint p ': lint-previous-error<ret>: lint-show<ret>' -docstring 'previous lint error'


# user mode
map global user f ': toggle-broot<ret>' -docstring 'select files in broot'
map global user g ': enter-grep-mode<ret>' -docstring 'grep current selection or prompt'
map global user G ': enter-user-mode -lock grep<ret>' -docstring 'grep mode'
# map global user l ': enter-user-mode lsp<ret>' -docstring 'lsp commands'
map global user l ': enter-user-mode lint<ret>' -docstring 'lint commands'
map global user r ': toggle-ranger<ret>' -docstring 'select files in ranger'
map global user s ': surround<ret>' -docstring 'Enter surround mode'
map global user t ': enter-user-mode tig<ret>' -docstring 'tig commands'
map global user w ': write<ret>' -docstring 'write current buffer'
map global user W ': write-all<ret>' -docstring 'write all modified buffers'

# System clipboard handling
# ─────────────────────────

evaluate-commands %sh{
    case $(uname) in
        Linux) copy="xclip -i"; paste="xclip -o" ;;
        Darwin)  copy="pbcopy"; paste="pbpaste" ;;
    esac

    printf "map global user -docstring 'paste (after) from clipboard' p '<a-!>%s<ret>'\n" "$paste"
    printf "map global user -docstring 'paste (before) from clipboard' P '!%s<ret>'\n" "$paste"
    printf "map global user -docstring 'yank to clipboard' y '<a-|>%s<ret>:echo -markup %%{{Information}copied selection to X11 clipboard}<ret>'\n" "$copy"
    printf "map global user -docstring 'replace from clipboard' R '|%s<ret>'\n" "$paste"
}
