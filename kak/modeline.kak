##
## git-branch.kak by lenormf
## Store the current git branch that contains the buffer
##
source ~/vc/dotfiles/kak/widgets/git-branch.kak

# show git branch in modeline
# modeline_git_branch may or may not be set, that's why there's no spacing around it
# If it is set, it will provide it's own spacing
set global modelinefmt '%opt{modeline_git_branch}%val{bufname} %val{cursor_line}:%val{cursor_char_column} {{context_info}} {{mode_info}} - %val{client}@[%val{session}]'
