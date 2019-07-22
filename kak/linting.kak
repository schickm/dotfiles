# available vars for running linting
# 
# kak_buffile     - origional name of file that had the code to be linted
#
# The best way to deal with setting this is to use direnv
#
# Examples for future implementations
#
# Javascript
# BEWARE - I am explicitly ignoring the exit code from eslint
# once I'm on eslint 5, I can just ignore exit code 1 and allow errors for 2
# but on eslint <5 it sends error code 1 for config errrors and lint errors
# 	run() { cat "$1" | npx --quiet eslint --format=$(npm root -g)/eslint-formatter-kakoune --stdin-filename ${kak_buffile} --stdin; } && run

evaluate-commands %sh{
    lintcmd='cat ${lint_file_in} | npx --quiet eslint --config .eslintrc.yml --format=$(npm root -g)/eslint-formatter-kakoune --stdin-filename ${kak_buffile} --output-file ${lint_file_out} --stdin || true'
    if [ -z "$kak_javascript_lintcmd" ]; then
        printf "echo -debug 'linting.kak - environment var \"kak_javascript_lintcmd\" not defined, using stock command'"
    else
        lintcmd="$kak_javascript_lintcmd"
    fi

    hasformatter=$(npm list --parseable -g | grep eslint-formatter-kakoune)
    if [ -z "$hasformatter" ]; then
    	printf "echo -debug 'linting.kak - eslint-formatter-kakoune is not installed, linting will be disabled. Please install it via: npm -g eslint-formatter-kakoune'"
	else
	    printf "
	        hook global WinSetOption filetype=javascript %%{
	            set buffer lintcmd '$lintcmd'
	            lint-enable
	            lint

	            hook -group javascript-lint-hooks window InsertEnd .* lint
	        }

	        hook global WinSetOption filetype=(?!javascript).* %%{
	            remove-hooks window javascript-lint-hooks
	        }
	    "
	fi

}


