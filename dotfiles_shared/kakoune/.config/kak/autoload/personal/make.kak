hook -once global KakBegin .* %{
	require-module make

	complete-command make shell-script-candidates %{
		make -qp | sed -n -E 's/^([a-z_-]+):$/\1/p' | sort
	}
}
