# use editor config on load for all windows except kak ones like *debug* or
# *scratch*
hook global WinCreate ^[^*]+$ %{editorconfig-load}
