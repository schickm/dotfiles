hook -once global KakBegin .* %{

	# global 4 space indent
	set global indentwidth 4
	set global aligntab false

	# always use git grep
	set global grepcmd 'git grep -n'
	set global autoreload yes

	set global ui_options terminal_assistant=none terminal_info_max_width=100
}

#
# These options are used by commands in github.kak and jenkins.kak
#
# They build up elaborate process of getting the actual url and remote branch name
#

declare-option -hidden str git_upstream_cmd \
	"git status --branch --porcelain=v2 | grep -m 1 '^# branch.upstream ' | cut -d ' ' -f 3"
declare-option -hidden str git_remote_name_cmd \
	"%opt{git_upstream_cmd} | cut -d '/' -f 1"
declare-option -hidden str git_remote_branch_cmd \
	"%opt{git_upstream_cmd} | cut -d '/' -f 2-"
declare-option -hidden str git_remote_url_cmd \
	"NAME=$(%opt{git_remote_name_cmd}) && git remote get-url $NAME | sed 's|^git@github.com:|https://github.com/|; s|\.git$||'"
