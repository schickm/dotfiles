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
map global user r ' :toggle-ranger<ret>' -docstring 'select files in ranger'
map global user s ':<space>auto-pairs-surround<ret>' -docstring 'surround'

