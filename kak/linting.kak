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

# working on getting the logic below to live in it's own hook.
hook -once global WinSetOption filetype=(javascript|typescript) %{ evaluate-commands %sh{

    # lintcmd='cat ${lint_file_in} | npx --quiet eslint --config .eslintrc.yml --format=$(npm root -g)/eslint-formatter-kakoune --stdin-filename ${kak_buffile} --output-file ${lint_file_out} --stdin || true'
    if [ "$kak_javascript_lintcmd" ]; then
        lintcmd="$kak_javascript_lintcmd"
        printf "
        echo -debug 'got lint cmd $lintcmd'
    		enable-lint '$lintcmd' javascript-lint-hooks

            hook global WinSetOption filetype=(javascript|typescript) %%{
		enable-lint '$lintcmd' javascript-lint-hooks
                hook -once -always window WinSetOption filetype=.* %%{ remove-hooks window javascript-lint-hooks }
            }
        "
    fi
} }

hook global WinSetOption filetype=sh %{
	enable-lint "shellcheck -fgcc -Cnever" shell-lint-hooks
}
