
hook global WinSetOption filetype=kak %{
	enable-lint-on-change kak-lint-hooks
    hook -once -always window WinSetOption filetype=.* %%{ remove-hooks window kak-lint-hooks }
}
