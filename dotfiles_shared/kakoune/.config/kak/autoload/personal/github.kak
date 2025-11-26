#
# My own Github related helpers
#

hook global BufOpenFile .* %{
	evaluate-commands %sh{
	    # first figure out the origin branch's remote
        if ! remote_name=$(eval "$kak_opt_git_remote_name_cmd") || [ -z "$remote_name" ]; then
		  printf 'echo -debug "github.kak - failed to determine git remote.  Is your branch pushed?"\n'
          exit 1
        fi

	    remote=$(git remote get-url "$remote_name")


	    case "$remote" in
	      git@github.com*)
			printf 'echo -debug remote_name %s\n' "$remote_name"
			printf 'echo -debug remote %s\n' "$remote"

			printf 'setup-github-mode'
		    ;;
	      *)
	      	printf 'echo "%s not supported remote"' "$remote"
	      	;;
	    esac
	}
}


define-command github-blame-url-for-selection \
	-params 1 \
	-docstring "github-blame-url-for-selection <open|copy>" \
	-override \
	%{
	nop %sh{
		repo_url=$(eval "$kak_opt_git_remote_url_cmd")
		branch=$(git rev-parse --abbrev-ref HEAD)
		remote_branch=$(eval "$kak_opt_git_remote_branch_cmd")
		merge_base=$(git merge-base "$branch" "$remote_branch")
		# The kak instance may have been launched in a subdirectory of the git repo (this happens
		# frequently with monorepos).  This ensures that we use the full relative path for the git
		# repo itself
		repo_file_path=$(git ls-files --full-name "$kak_bufname")
		lines=$(echo "$kak_selection_desc" | sed -e 's/\([0-9]*\)\.[0-9]*/L\1/g' -e 's/,/-/')
		url="$repo_url/blob/$merge_base/$repo_file_path#$lines"

		case $1 in
			open)
				open "$url"
		      	;;
			copy)
				echo "$url" | wl-copy 2>/dev/null
				;;
			*)
				echo "Invalid option"
				exit 1
				;;
		esac
	 }
}

# Wrapped in try so that entire file can be re-sourced without throwing an error
# due to there already being a usermode named github
try %{ declare-user-mode github }

define-command setup-github-mode \
	-override \
	-docstring 'setup-github-mode <repo url> <remote branch name>' %{

	map buffer git g ': enter-user-mode github<ret>' -docstring 'Github related commands'

    map buffer github p ": async-command ""gh pr view -w""<ret>" \
    	-docstring 'Open this pull request'
    map buffer github u ": github-blame-url-for-selection copy<ret>" \
    	-docstring 'Copy file+line url to clipboard'
    map buffer github U ": github-blame-url-for-selection open<ret>" \
    	-docstring 'Open file in browser on Github'
}

