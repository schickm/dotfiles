plug Delapouite/kakoune-buffers
# Suggested hook

#hook global WinDisplay .* info-buffers

# Suggested mappings

map global user b ':enter-buffers-mode<ret>'              -docstring 'buffers…'
map global user B ':enter-user-mode -lock buffers<ret>'   -docstring 'buffers (lock)…'
