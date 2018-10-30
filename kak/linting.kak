# available vars for running linting
# lint_file_in  - name of file that contains code to be linted
# lint_file_out - destination for linted code
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
# 	cat ${lint_file_in} | yarn -s eslint --config .eslintrc.js --format=node_modules/eslint-formatter-kakoune --stdin-filename ${kak_buffile} --output-file ${lint_file_out} --stdin || true

evaluate-commands %sh{
    if [ -z "$kak_lintcmd" ]; then
        printf "echo -debug 'linting.kak - environment var \"kak_lintcmd\" not defined, linting will be disabled'"
    else
        printf "
            hook global WinSetOption filetype=javascript %%{
                set buffer lintcmd '$kak_lintcmd'
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


