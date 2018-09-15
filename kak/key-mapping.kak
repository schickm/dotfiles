# edit with alt-p
map global normal <a-p> ':git-edit '
map global insert <a-p> '<esc>:git-edit '


# map jj to esc
hook global InsertChar j %{ try %{
  exec -draft hH <a-k>jj<ret> d
  exec -with-hooks <esc>
}}

# user mode
map global user w ':write<ret>' -docstring 'write current buffer'
map global user W ':write-all<ret>' -docstring 'write all modified buffers'
map global user t ':suspend-and-resume tig<ret>' -docstring 'launch tig'
