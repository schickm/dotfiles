##
## git-branch.kak by lenormf
## Store the current git branch that contains the buffer
##
source ~/vc/dotfiles/kak/widgets/git-branch.kak

# show git branch in modeline
set global modelinefmt ' %opt{modeline_git_branch}  %val{bufname} %val{cursor_line}:%val{cursor_char_column} {{context_info}} {{mode_info}} - %val{client}@[%val{session}]'

