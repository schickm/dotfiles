hook global WinSetOption filetype=javascript %{
    set buffer lintcmd 'yarn -s eslint --config .eslintrc.js --format=node_modules/eslint-formatter-kakoune'
    lint-enable
    lint

    hook -group javascript-lint-hooks window InsertEnd .* lint
}


hook global WinSetOption filetype=(?!javascript).* %{
    remove-hooks window javascript-lint-hooks
}
