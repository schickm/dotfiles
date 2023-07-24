##
## git-branch.kak by lenormf
## Adapted from https://github.com/lenormf/kakoune-extra/blob/master/widgets/git-branch.kak
## Store the current git branch that contains the buffer
##

evaluate-commands %sh{
    if ! command -v greadlink > /dev/null 2>&1; then
        echo "echo -debug %{Dependency unmet: greadlink, please install it to use git-branch.kak}"
    fi
}

declare-option str modeline_git_branch

hook global WinCreate .* %{
    hook window NormalIdle .* %{ evaluate-commands %sh{
        branch=$(cd "$(dirname "$(greadlink -e "${kak_buffile}")")" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if [ -n "${branch}" ]; then
            echo "set window modeline_git_branch '⎇ ${branch}'"
        fi
    } }
}
