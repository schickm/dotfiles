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
map global tig b ':<space>tig-blame<ret>' -docstring 'show blame (with tig)'
map global tig s ':<space>suspend-and-resume "tig status"<ret>' -docstring 'show git status (with tig)'
map global tig m ':<space>suspend-and-resume "tig"<ret>' -docstring 'show main view (with tig)'

# user mode
map global user w ':<space>write<ret>' -docstring 'write current buffer'
map global user W ':<space>write-all<ret>' -docstring 'write all modified buffers'
map global user t ':<space>enter-user-mode tig<ret>' -docstring 'tig commands'
map global user g ':<space>grep<ret> gg' -docstring 'grep current selection'
map global user l ':<space>enter-user-mode lsp<ret>' -docstring 'lsp commands'
map global user s ':<space>auto-pairs-surround<ret>' -docstring 'surround'

# System clipboard handling
# ─────────────────────────

evaluate-commands %sh{
    case $(uname) in
        Linux) copy="xclip -i"; paste="xclip -o" ;;
        Darwin)  copy="pbcopy"; paste="pbpaste" ;;
    esac

    printf "map global user -docstring 'paste (after) from clipboard' p '!%s<ret>'\n" "$paste"
    printf "map global user -docstring 'paste (before) from clipboard' P '<a-!>%s<ret>'\n" "$paste"
    printf "map global user -docstring 'yank to clipboard' y '<a-|>%s<ret>:echo -markup %%{{Information}copied selection to X11 clipboard}<ret>'\n" "$copy"
    printf "map global user -docstring 'replace from clipboard' R '|%s<ret>'\n" "$paste"
}
