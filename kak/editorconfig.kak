# use editor config on load
hook global BufCreate .* %{editorconfig-load}
