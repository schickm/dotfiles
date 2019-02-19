
# fuzzy find using git
def git-edit -override -params 1 -shell-script-candidates %{ git ls-files } %{
    edit %arg{1}
}

# easy access to editing my kakrc
def kakrc -override -docstring "open kakrc in a less fastidious way" %{
    edit %sh{ echo ${XDG_CONFIG_HOME:-${HOME}/.config}/kak/kakrc }
}

def github-blame -override -docstring 'Open blame on github for current file and line' %{ evaluate-commands %sh{
    local_branch_name=$(git name-rev --name-only HEAD)
    remote_name=$(git config branch.$local_branch_name.remote || echo "origin")
    remote_branch_name=$(git config branch.$local_branch_name.merge | sed 's|refs/heads/||')
    repo_url=$(git config remote.$remote_name.url)
    repo_url=$(echo "$repo_url" | sed 's/^git@//; s/:/\//; s/\.git$//')
    line_number=$(echo "$kak_selection_desc" | sed -n 's/^.*,\([[:digit:]]*\).*$/\1/p')
    open "https://$repo_url/blame/$remote_branch_name/$kak_bufname#L$line_number"
}}

def tig-blame -override -docstring 'Open blame in tig for current file and line' %{
    suspend-and-resume "tig blame +%val{cursor_line} %val{buffile}" 
}

def suspend-and-resume \
    -override \
    -params 1..2 \
    -docstring 'suspend-and-resume <cli command> [<kak command after resume>]' \
    %{ evaluate-commands %sh{

	cli_cmd="$1 && fg"
	post_resume_cmd="$2"
	platform=$(uname -s)
	case $platform in
		Darwin)
			automate_cmd="sleep 0.01; osascript -e 'tell application \"System Events\" to keystroke \"$cli_cmd\\n\" '"
			kill_cmd="/bin/kill"
			break
			;;
		Linux)
			automate_cmd="sleep 0.2; xdotool type '$cli_cmd'; xdotool key Return"
			kill_cmd="/usr/bin/kill"
			break
		    ;;
	esac

	nohup sh -c "$automate_cmd"  > /dev/null 2>&1 &
	$kill_cmd -SIGTSTP $kak_client_pid
	if [ ! -z "$post_resume_cmd" ]; then
		echo "$post_resume_cmd"
	fi

}}


define-command iterm-terminal-window-with-shell \
	-params 1 \
	-override \
	-docstring '
iterm-terminal-window <command>: create a new terminal as an iterm window
The command passed as argument will be executed in the new terminal with the default login shell'\
%{
    nop %sh{
        osascript \
        -e "tell application \"iTerm\"" \
        -e "    create window with default profile" \
        -e "	tell current window" \
        -e "		tell current session" \
        -e "			write text \"$1\"" \
        -e "		end tell" \
        -e "	end tell" \
        -e "end tell" >/dev/null
    }
}

define-command iterm-terminal-tab-with-shell \
	-params 1 \
	-override \
	-docstring '
iterm-terminal-tab <command>: create a new terminal as an iterm tab
The command passed as argument will be executed in the new terminal with the default login shell'\
%{
    nop %sh{
        osascript \
        -e "tell application \"iTerm\"" \
        -e "	tell current window" \
        -e "    	create tab with default profile" \
        -e "		tell current tab" \
        -e "			tell current session" \
        -e "				write text \"$1\"" \
        -e "			end tell" \
        -e "		end tell" \
        -e "	end tell" \
        -e "end tell" >/dev/null
    }
}

define-command new-kak-window \
	-override \
	-docstring 'new-kak-window: launch a new window with kak connected to this session' \
%{
	iterm-terminal-window-with-shell "kak -c %val{session}"
}

define-command new-kak-tab \
	-override \
	-docstring 'new-kak-tab: launch a new tab with kak connected to this session' \
%{
	iterm-terminal-tab-with-shell "kak -c %val{session}"
}
