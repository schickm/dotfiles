# map jj to esc
hook global InsertChar j %{ try %{
  exec -draft hH <a-k>jj<ret> d
  exec -with-hooks <esc>
}}

declare-user-mode file
map global file b ': nop %sh{ echo "$kak_bufname" | wl-copy }<ret>' -docstring 'Copy current buffer name to clipboard'
map global file f ': nop %sh{ echo "$kak_buffile" | wl-copy }<ret>' -docstring 'Copy full file path of buffer to clipboard'
map global file c ': terminal claude "I want to ask you a few questions about @%val{buffile}"<ret>' -docstring 'open claude for current file'
map global file n ': terminal nnn-for-kak.sh %val{session} %val{client} %val{buffile}<ret>' -docstring 'launch nnn for current buffer''s directory'
map global file N ': terminal nnn-for-kak.sh %val{session} %val{client}<ret>' -docstring 'launch nnn in CWD'
map global file o ': nop %sh{ open "$(dirname "$kak_buffile")" }<ret>' -docstring 'open current directory in Finder'
map global file t ': iterm-terminal-window-with-shell "cd %sh{ dirname ""$kak_buffile"" }"<ret>' -docstring 'open current directory in Terminal'


declare-user-mode git

map global git a ': suspend-and-resume "git add . && git commit"<ret>' -docstring 'commit all tracked files'
map global git b ': suspend-and-resume "tig blame +%val{cursor_line} %val{buffile}"<ret>' -docstring 'show blame (with tig)'
map global git B ': git-remote-blame<ret>' -docstring 'show blame in browser based on remote'
map global git c ': suspend-and-resume "git reset && git add %val{buffile} && git commit && git push"<ret>' -docstring 'commit current file and push'
map global git f ': suspend-and-resume "git commit %val{buffile}"<ret>' -docstring 'make commit with current file'
map global git F ': git-add-fixup-for-current-buffer<ret>' -docstring 'make fixup commit for current buffer'
map global git s ': suspend-and-resume "kak_session=%val{session} kak_client=%val{client} tig status"<ret>' -docstring 'show git status (with tig)'
map global git m ': suspend-and-resume "kak_session=%val{session} kak_client=%val{client} tig"<ret>' -docstring 'show main view (with tig)'
map global git + ': git-amend-current-buffer<ret>' -docstring 'append this files changes to most recent commit'
map global git p ': suspend-and-resume "git push"<ret>' -docstring 'push'
map global git P ': suspend-and-resume "git push -f --no-verify"<ret>' -docstring 'force push (no verify)'
map global git t ': nop %sh{ open "https://jira.grubhub.com/browse/$(extract-jira-ticket.sh)" }<ret>' -docstring 'open Jira ticket (from branch name)'
map global git u ': suspend-and-resume "git pull"<ret>' -docstring 'pull'

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

# commands that are local to the directory being worked on
declare-user-mode local
map global user l ': enter-user-mode local<ret>' -docstring 'local commands'

declare-user-mode kakoune
map global kakoune l ': e .kakrc.local<ret>' -docstring 'edit .kakrc.local'
map global kakoune s ': source %val{buffile}<ret>' -docstring 'source current buffer'
map global kakoune e ': evaluate-commands %val{selection}<ret>' -docstring 'eval current selection'
map global kakoune k ': eval menu %sh{ kak -l | sed -E "s/(.*)/\1 %{terminal kak -c \1}/" | tr ''\n'' '' '' }<ret>' -docstring 'open other kak session in new terminal'
map global kakoune t ': rename-client tools <semicolon> set global toolsclient tools<ret>' -docstring 'mark current client as toolsclient'
map global kakoune m ': rename-client main <semicolon> set global jumpclient main<ret>' -docstring 'mark current client as main client'
map global kakoune d ': buffer *debug*<ret>' -docstring 'show debug buffer'


map global user b ': buffer ' -docstring 'open buffer...'
map global user f ': enter-user-mode file<ret>' -docstring 'file commands'
map global user g ': enter-user-mode -lock grep<ret>'
map global user G ': enter-grep-mode<ret>' -docstring 'grep current selection or prompt'
map global user k ': enter-user-mode kakoune<ret>' -docstring 'kakoune specific helpers'
map global user L ': enter-user-mode lint<ret>' -docstring 'lint commands'
map global user e ': git-edit ' -docstring 'git edit'
map global user s ': surround<ret>' -docstring 'Enter surround mode'
map global user S ': suspend-and-resume "aspell check %val{buffile}"<ret>' -docstring 'spellcheck with aspell'
map global user t ': enter-user-mode git<ret>' -docstring 'git commands'
map global user w ': write<ret>' -docstring 'write current buffer'
map global user W ': write-all<ret>' -docstring 'write all modified buffers'

# System clipboard handling
# ─────────────────────────

evaluate-commands %sh{
    case $(uname) in
        Linux) copy="wl-copy"; paste="wl-paste" ;;
        Darwin)  copy="pbcopy"; paste="pbpaste" ;;
    esac

    printf "map global user -docstring 'paste (after) from clipboard' p '<a-!>%s<ret>'\n" "$paste"
    printf "map global user -docstring 'paste (before) from clipboard' P '!%s<ret>'\n" "$paste"
    printf "map global user -docstring 'yank to clipboard' y '<a-|>%s<ret>:echo -markup %%{{Information}copied selection to X11 clipboard}<ret>'\n" "$copy"
    printf "map global user -docstring 'replace from clipboard' R '|%s<ret>'\n" "$paste"
}
