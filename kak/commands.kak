
# fuzzy find using git
def git-edit -docstring 'add some docs' -override -params 1 -shell-script-candidates %{ git ls-files } %{
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

def jellyvision-stash-browse \
	-override \
	-docstring 'Open on JV Stash for current file and line' \
	%{ evaluate-commands %sh{

    local_branch_name=$(git name-rev --name-only HEAD)
    remote_name=$(git config branch.$local_branch_name.remote || echo "origin")
    remote_branch_name=$(git config branch.$local_branch_name.merge)
    repo_url=$(git config remote.$remote_name.url)
    repo_url=$(echo "$repo_url" | sed 's|^.*@||; s|:[[:digit:]]*/\([a-z]*\)/|/projects/\1/repos/|; s|\.git$||')
    line_number=$(echo "$kak_selection_desc" | sed 's/^\([0-9]*\)\.[0-9]*,\([0-9]*\).*$/\1-\2/')
    open "https://$repo_url/browse/$kak_bufname?at=$remote_branch_name#$line_number"
}}

def for-each-line \
 	-override \
 	-docstring "for-each-line <command> <path to file>: run command with the value of each line in the file" \
	-params 2 \
	%{ evaluate-commands %sh{

	while read f; do
		printf "$1 $f\n"
	done < "$2"
}}

def toggle-ranger -override %{
	suspend-and-resume \
		"ranger --choosefiles=/tmp/ranger-files-%val{client_pid}" \
		"for-each-line edit /tmp/ranger-files-%val{client_pid}"
}

def suspend-and-resume \
	-params 1..2 \
	-override \
	-docstring 'suspend-and-resume <cli command> [<kak command after resume>]: backgrounds current kakoune client and runs specified cli command.  Upon exit of command the optional kak command is executed.' \
	%{ evaluate-commands %sh{

	# Note we are adding '&& fg' which resumes the kakoune client process after the cli command exits
	cli_cmd="$1 && fg"
	post_resume_cmd="$2"

	# automation is different platform to platform
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

	# Uses platforms automation to schedule the typing of our cli command
	nohup sh -c "$automate_cmd"  > /dev/null 2>&1 &
	# Send kakoune client to the background
	$kill_cmd -SIGTSTP $kak_client_pid

	# ...At this point the kakoune client is paused until the " && fg " gets run in the $automate_cmd

	# Upon resume, run the kak command is specified
	if [ ! -z "$post_resume_cmd" ]; then
		echo "$post_resume_cmd"
	fi
}}

declare-option -docstring 'shell command to run when running an npm command' \
	str npmruncmd "npm run"

define-command npm-run \
	-params 1 \
	-override \
	-docstring %{npm-run <script>: Runs the specified script in the cwd's package.json} \
	-shell-script-candidates %{
		jq -c -r  ".scripts | keys | map(select(test(\"${1}\"))) | .[]" < package.json
	} \
	%{ evaluate-commands %sh{
		output=$(mktemp -d "${TMPDIR:-/tmp}"/kak-npm-run.XXXXXXXX)/fifo
		mkfifo ${output}
		( eval ${kak_opt_npmruncmd} "$@" > ${output} 2>&1 ) > /dev/null 2>&1 < /dev/null &

		printf %s\\n "evaluate-commands -try-client '$kak_opt_toolsclient' %{
			edit! -fifo ${output} -scroll *npm-run*
			hook -always -once buffer BufCloseFifo .* %{ nop %sh{ rm -r $(dirname ${output}) } }
		}"
	} }



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

define-command conditionally-enable-git-gutter \
	-override \
	-docstring '
conditionally-enable-git-gutter: show git gutter if current buffer is actually under
version control.' \
%{
	evaluate-commands %sh{
	# This ensures that we only enable git diffing when our buffer
	# has a file that's actually under version control
	if git ls-files --error-unmatch $kak_buffile >/dev/null 2>&1 ; then
		printf "git show-diff"
	fi
} }
