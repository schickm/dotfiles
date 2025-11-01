hook global BufOpenFile .*\.envrc(?:\.local)?$ %{
	set buffer filetype sh
}
