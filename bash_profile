# add 'source dotfiles/bash_aliases' to ~/.profile

alias p='ls -GF'
alias pg='p | grep -i'
alias ..='cd ..'
alias ...='cd ../..'
alias tre='tree -FCA'
alias cpwd="pwd | tr -d '\n' | pbcopy"
alias g='git'
alias s='svn'
alias npm-exec='PATH=$(npm bin):$PATH'

alias emulsion.me='ssh emulsion@emulsion.me'
alias mattschick.com='ssh mattschick.com@s35017.gridserver.com'
alias schickm.com='ssh schickmc@schickm.com'