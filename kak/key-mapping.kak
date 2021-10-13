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
map global lint n ': lint-next-message<ret>: lint-show<ret>' -docstring 'next lint message'
map global lint p ': lint-previous-message<ret>: lint-show<ret>' -docstring 'previous lint message'

# Spell mode
# taken from https://discuss.kakoune.com/t/mode-hooks-and-user-modes/169/7?u=schickm
declare-user-mode spell
define-command -hidden -params 0 _spell-replace %{
    hook -always -once window ModeChange push:prompt:next-key\[user.spell\] %{
        execute-keys <esc>
    }

    hook -once -always window NormalIdle .* %{
        enter-user-mode -lock spell
        spell
    }
    spell-replace
}
map global spell a ': spell-add; spell<ret>' -docstring 'add to dictionary'
map global spell r ': _spell-replace<ret>' -docstring 'suggest replacements'
map global spell n ': spell-next<ret>' -docstring 'next misspelling'

hook global ModeChange push:[^:]*:next-key\[user.spell\] %{
    hook -once -always window NormalIdle .* spell-clear
}

# local mode
declare-user-mode local

# kak mode

declare-user-mode kakoune
map global kakoune l ': e .kakrc.local<ret>' -docstring 'edit .kakrc.local'
map global kakoune s ': source %val{buffile}<ret>' -docstring 'source current buffer'
map global kakoune t ': rename-client tools <semicolon> set global toolsclient tools<ret>' -docstring 'mark current client as toolsclient'

# user mode
map global user f ': toggle-broot<ret>' -docstring 'select files in broot'
map global user g ': enter-grep-mode<ret>' -docstring 'grep current selection or prompt'
map global user k ': enter-user-mode kakoune<ret>' -docstring 'kakoune specific helpers'
map global user l ': enter-user-mode local<ret>' -docstring 'local commands'
map global user L ': enter-user-mode lint<ret>' -docstring 'lint commands'
map global user r ': toggle-ranger<ret>' -docstring 'select files in ranger'
map global user s ': surround<ret>' -docstring 'Enter surround mode'
map global user S ': spell ; enter-user-mode -lock spell<ret>' -docstring 'spell mode'
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
