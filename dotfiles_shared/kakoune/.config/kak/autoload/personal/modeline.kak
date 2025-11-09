##
## git-branch.kak by lenormf
## Store the current git branch that contains the buffer
##
evaluate-commands %sh{
    if ! command -v readlink > /dev/null 2>&1; then
        echo "echo -debug %{Dependency unmet: greadlink, please install it to use git-branch.kak}"
    fi
}

declare-option str modeline_git_branch

hook global WinCreate .* %{
    hook window NormalIdle .* %{ evaluate-commands %sh{
        branch=$(cd "$(dirname "$(readlink -e "${kak_buffile}")")" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if [ -n "${branch}" ] && [ "$kak_client" = "main" ]; then
            echo "set window modeline_git_branch ' ⎇ ${branch} '"
        fi
    } }
}

# show git branch in modeline
# modeline_git_branch may or may not be set, that's why there's no spacing around it
# If it is set, it will provide it's own spacing
set global modelinefmt '%opt{modeline_git_branch}%val{bufname} %val{cursor_line}:%val{cursor_char_column} {{context_info}} {{mode_info}} - %val{client}@[%val{session}]'
