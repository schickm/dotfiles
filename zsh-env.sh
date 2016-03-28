# add 'source dotfiles/bash_profile' to ~/.bash_profile

alias p='ls -GF'
alias pg='p | grep -i'
alias ..='cd ..'
alias ...='cd ../..'
alias tre='tree -FCA'
alias cpwd="pwd | tr -d '\n' | pbcopy"
alias g='git'
alias npm-exec='PATH=$(npm bin):$PATH'
alias htop='sudo htop'
alias pbcopy="perl -p -e 'chomp if eof' | pbcopy"
alias atom='open -a Atom'

alias emulsion.me='ssh emulsion@emulsion.me'
alias mattschick.com='ssh schickm@mattschick.com'
alias schickm.com='ssh schickm@schickm.com'


# load custom path if present
if [ -f ~/.path ]; then
  source ~/.path
fi

# Autocomplete for 'g' as well
# complete -o default -o nospace -F _git g