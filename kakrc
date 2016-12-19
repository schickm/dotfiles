# fuzzy find using git
def git-edit -params 1 -shell-candidates %{ git ls-files } %{ edit %arg{1} }
alias global ge git-edit

# show git branch in modeline
set global modelinefmt '⎇ %opt{modeline_git_branch}  %val{bufname} %val{cursor_line}:%val{cursor_char_column} '

# show line numbers on all files
hook global WinCreate .* %{addhl number_lines}

# map jj to esc
hook global InsertChar j %{ try %{
  exec -draft hH <a-k>jj<ret> d
  exec <esc>
}}

# syntax highlight handlebars files as html (for now...)
hook global BufCreate .*\.(hbs) %{
    set buffer filetype html
}

hook global BufCreate .*\.jshintrc %{
	set buffer filetype json
}

# use editor config on load
hook global BufOpen .* %{editorconfig-load}

# autoload all my stuff
%sh{
    autoload() {
        dir=$1
        for rcfile in ${dir}/*.kak; do
            if [ -f "$rcfile" ]; then
                echo "try %{ source '${rcfile}' } catch %{ echo -debug Autoload: could not load '${rcfile}' }";
            fi
        done
        for subdir in ${dir}/*; do
            if [ -d "$subdir" ]; then
                autoload $subdir
            fi
        done
    }

	autoload ~/vc/dotfiles/kak
}
# do syntax highlighting for perl modules as well
hook global BufCreate .*\.pm %{
    set buffer filetype perl
}

# Face customizations
face GitDiffFlags default

# Show git gutter always
hook global WinCreate .* %{
	git show-diff
}

hook global NormalIdle .* %{
	git update-diff
}

# linting
hook global WinSetOption filetype=javascript %{
	%sh{
		log () {
			echo "echo -debug \"$1\""
        }

        gnureadlink() {
            if hash greadlink 2>/dev/null; then
                greadlink "$@"
            else
                readlink "$@"
            fi
        }

        find_in_closest_parent_dir() {
            filename=$1
            path=$2
            while [[ $path != "/" ]]
            do
        	out=$(find $path -maxdepth 1 -mindepth 1 -name $filename)

        	if [[ -n $out ]] 
                then 
                    echo "$path/$filename"
        	    break
        	fi

                path=$(gnureadlink -f $path/..)
            done
        }
		target_dir=$(dirname $kak_buffile)
    	jshint_path=$(find_in_closest_parent_dir .jshintrc ${target_dir})

    	echo "set buffer lintcmd 'jshint --config $jshint_path --reporter ~/vc/dotfiles/kak/jshint-reporter.js'"
    }
	lint-enable
	lint

	hook window BufWritePost .* %{
		lint
	}
}

