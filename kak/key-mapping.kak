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
map global tig b ':tig-blame<ret>' -docstring 'show blame (with tig)'
map global tig s ':suspend-and-resume "tig status"<ret>' -docstring 'show git status(with tig)'

# user mode
map global user w ':write<ret>' -docstring 'write current buffer'
map global user W ':write-all<ret>' -docstring 'write all modified buffers'
map global user t ':enter-user-mode tig<ret>' -docstring 'tig commands'
map global user g ':grep<ret> gg' -docstring 'grep current selection'
map global user l ':enter-user-mode lsp<ret>' -docstring 'lsp commands'
