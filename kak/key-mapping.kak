# edit with alt-p
map global normal <a-p> ':git-edit '
map global insert <a-p> '<esc>:git-edit '


# map jj to esc
hook global InsertChar j %{ try %{
  exec -draft hH <a-k>jj<ret> d
  exec -with-hooks <esc>
}}

declare-user-mode tig
map global tig b ': tig-blame<ret>' -docstring 'show blame (with tig)'
map global tig s ': suspend-and-resume "tig status"<ret>' -docstring 'show git status (with tig)'
map global tig m ': suspend-and-resume "tig"<ret>' -docstring 'show main view (with tig)'
map global tig + ': git-amend-current-buffer<ret>' -docstring 'append this files changes to most recent commit'
map global tig p ': suspend-and-resume "git push"<ret>' -docstring 'push'
map global tig P ': suspend-and-resume "git push -f --no-verify"<ret>' -docstring 'force push (no verify)'
define-command -hidden -override git-amend-current-buffer %{
    write
    nop %sh{
	git reset -- "$kak_buffile"
	git add "$kak_buffile"
	git commit --amend --no-edit 
    }
    echo -markup "{Information}%val{bufname} amended to git commit:" %sh{ git log -n 1 --format=%s }
}


declare-user-mode lint
map global lint n ': lint-next-message<ret>: lint-show<ret>' -docstring 'next lint message'
map global lint p ': lint-previous-message<ret>: lint-show<ret>' -docstring 'previous lint message'

hook global ModeChange push:[^:]*:next-key\[user.spell\] %{
    hook -once -always window NormalIdle .* spell-clear
}

declare-user-mode local

declare-user-mode kakoune
map global kakoune l ': e .kakrc.local<ret>' -docstring 'edit .kakrc.local'
map global kakoune s ': source %val{buffile}<ret>' -docstring 'source current buffer'
map global kakoune e ': evaluate-commands %val{selection}<ret>' -docstring 'eval current selection'
map global kakoune t ': rename-client tools <semicolon> set global toolsclient tools<ret>' -docstring 'mark current client as toolsclient'

map global user f ': toggle-broot<ret>' -docstring 'select files in broot'
map global user g ': enter-grep-mode<ret>' -docstring 'grep current selection or prompt'
map global user k ': enter-user-mode kakoune<ret>' -docstring 'kakoune specific helpers'
map global user l ': enter-user-mode local<ret>' -docstring 'local commands'
map global user L ': enter-user-mode lint<ret>' -docstring 'lint commands'
map global user r ': toggle-ranger<ret>' -docstring 'select files in ranger'
map global user s ': surround<ret>' -docstring 'Enter surround mode'
map global user S ': suspend-and-resume "aspell check %val{buffile}"<ret>' -docstring 'spellcheck with aspell'
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
