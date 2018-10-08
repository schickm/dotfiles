
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

def suspend-and-resume \
	-override \
	-params 1..2 \
	-docstring 'suspend-and-resume <cli command> [<kak command after resume>]' \
	%{ evaluate-commands %sh{
  nohup sh -c "sleep 0.1; osascript -e 'tell application \"System Events\" to keystroke \"$1 &&fg\\n\" '" > /dev/null 2>&1 &
  /bin/kill -SIGTSTP $PPID
  if [ ! -z "$2" ]; then
      echo "$2"
  fi
}}
