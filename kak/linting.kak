hook global WinSetOption filetype=javascript %{
    # BEWARE - I am explicitly ignoring the exit code from eslint
    # once I'm on eslint 5, I can just ignore exit code 1 and allow errors for 2
    # but on eslint <5 it sends error code 1 for config errrors and lint errors
    set buffer lintcmd 'cat ${lint_file_in} | yarn -s eslint --config .eslintrc.js --format=node_modules/eslint-formatter-kakoune --stdin-filename ${kak_buffile} --output-file ${lint_file_out} --stdin || true'
    lint-enable
    lint

    hook -group javascript-lint-hooks window InsertEnd .* lint
}


hook global WinSetOption filetype=(?!javascript).* %{
    remove-hooks window javascript-lint-hooks
}
