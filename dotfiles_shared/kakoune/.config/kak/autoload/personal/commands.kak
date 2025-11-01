
# fuzzy find using git
def git-edit -docstring 'add some docs' -override -params 1 -shell-script-candidates %{ git ls-files } %{
    edit %arg{1}
}

# easy access to editing my kakrc
def kakrc -override -docstring "open kakrc in a less fastidious way" %{
    edit %sh{ echo ${XDG_CONFIG_HOME:-${HOME}/.config}/kak/kakrc }
}

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

def toggle-broot -override %{
	suspend-and-resume \
		"broot --out=/tmp/broot-files-%val{client_pid}" \
		"for-each-line edit /tmp/broot-files-%val{client_pid}"
}

def redraw-screen \
	-params 0 \
	-override \
%{ nop %sh{
	osascript -e 'tell application \"System Events\" to keystroke \"l\" using control down'
} }

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
			automate_cmd="sleep 0.01; osascript -e 'tell application \"System Events\" to keystroke \"${cli_cmd}\n\"'"
			kill_cmd="/bin/kill"
			;;
		Linux)
			automate_cmd="sleep 0.2; xdotool type '$cli_cmd'; xdotool key Return"
			kill_cmd="/usr/bin/kill"
		    ;;
	esac

	# Uses platforms automation to schedule the typing of our cli command
	nohup sh -c "$automate_cmd"  > /dev/null 2>&1 &
	# Send kakoune client to the background
	$kill_cmd -SIGTSTP $kak_client_pid

	# ...At this point the kakoune client is paused until the " && fg " gets run in the $automate_cmd

	# Upon resume, run the kak command is specified
	if [ ! -z "$post_resume_cmd" ]; then
		echo "redraw-screen"
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

define-command launch-node-inspector \
    -override \
    -docstring 'launch-node-inspector: uses applescript to open Chrome and open the node debugging tools' \
%{
	nop %sh{
		osascript \
		-e "set debugUrl to \"chrome://inspect\"" \
		-e "set js to \"document.getElementById('node-frontend').click();\"" \
		-e "tell application \"Google Chrome\"" \
		-e "	if windows = {} then" \
		-e "		make new window" \
		-e "		set URL of (active tab of window 1) to debugUrl" \
		-e "	else" \
		-e "		make new tab at the end of window 1 with properties {URL:debugUrl}" \
		-e "	end if" \
		-e "	delay 0.5" \
		-e "	set lastWindow to front window" \
		-e "	execute front window's active tab javascript js" \
		-e "	tell lastWindow to close active tab" \
		-e "  activate" \
		-e "end tell"
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
			printf "
				git show-diff
				hook buffer BufWritePost .* %%{
					git update-diff
				}
			"
		#else
		#	printf "echo -debug \"conditionally-enable-git-gutter - skipping file $kak_buffile as it's not under version control\""
		fi
	}
}

define-command async-command \
	-override \
	-docstring 'async-command <command to run>: runs command asyncronously' \
	-params 1 %{

	nop %sh{ {
	  eval "$1"
	} > /dev/null 2>&1 < /dev/null & }
}

define-command print-command-to-fifo \
    -override \
    -docstring 'print-command-to-fifo <command to run> [<name of buffer>]: runs command another buffer ' \
    -params 1..2 %{

    evaluate-commands %sh{
        output=$(mktemp -d -t kak-temp-XXXXXXXX)/fifo
        buffer="${2:-*cmd*}"
        mkfifo "${output}"

        ( eval $1 > ${output} 2>&1 ) > /dev/null 2>&1 < /dev/null &
        echo "
            evaluate-commands -try-client '$kak_opt_toolsclient' %{
                edit! -scroll -fifo ${output} ${buffer}
                hook buffer BufCloseFifo .* %{
                    nop %sh{
                        rm -r $(dirname ${output})
                    }
                }
            }
        "
    }
}
# sets the lintcmd, runs lint right away, and sets up hooks to lint at appropriate times
define-command enable-lint \
	-docstring 'enable-lint <lint cmd> <hook group> - sets up linting for given window' \
	-override \
	-params 2 \
	%{

	echo -debug "running lint cmd " %arg{1}
    set-option window lintcmd %arg{1}

	enable-lint-on-change %arg{2}
}

define-command enable-lint-on-change \
	-override \
	-params 1 \
	-docstring 'enable-lint-on-change <hook group> - enables hooks that runs linting on exit of insert mode and after deletion' \
	%{

	# Run linting when we exit insert mode
    hook -group %arg{1} window ModeChange pop:insert:.* lint
    # ...and when we delete some code in normal mode
    hook -group %arg{1} window NormalKey d lint
    # and run lint for the first time.  Something was wrong with the context
    # so I had to run it inside this normal idle hook
	hook -group %arg{1} -once window NormalIdle .* lint
}

define-command laptop-screen-mode -override -docstring 'Sets ui options that work well on small laptop screen' \
	%{
	set global lsp_hover_max_lines 10
}

define-command git-add-fixup-for-current-buffer -override %{
	write
	prompt -shell-script-candidates %{
		git log -n 100 --oneline
	} "which commit? " %{
		eval %sh{
			commit_sha=$(echo "$kak_text" | cut -d ' ' -f 1)
			commit_message=$(echo "$kak_text" | cut -d ' ' -f 2-)

			git reset -- "$kak_buffile" >/dev/null
			git add "$kak_buffile" >/dev/null
			git commit --fixup "$commit_sha" >/dev/null

			printf "echo -markup ""{StatusLineInfo}Fixup created for {StatusLineValue}%s""\n" "$commit_message"
		}
	}
}
