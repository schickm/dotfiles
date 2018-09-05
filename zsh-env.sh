# add 'source dotfiles/bash_profile' to ~/.bash_profile

alias p='ls -GF'
alias pg='p | grep -i'
alias tre='tree -FCA'
alias cpwd="pwd | tr -d '\n' | pbcopy"
alias g='git'
alias dc='docker-compose'
alias npm-exec='PATH=$(npm bin):$PATH'
alias htop='sudo htop'
alias pbcopy="perl -p -e 'chomp if eof' | pbcopy"
alias atom='open -a Atom'
alias tig='tig status'
alias rr='ranger --choosefiles=/tmp/ranger-files'

alias emulsion.me='ssh emulsion@emulsion.me'
alias mattschick.com='ssh schickm@mattschick.com'
alias schickm.com='ssh schickm@schickm.com'

# load custom path if present
if [ -f ~/.path ]; then
  source ~/.path
fi

# up that history size
SAVEHIST=10000
HISTSIZE=10000

# single ENTER during history completion
zmodload zsh/complist
bindkey -M menuselect '^M' .accept-line

unsetopt share_history
setopt HIST_IGNORE_SPACE

gdf() {
    echo 'Commits that exist in '$1' but not in '$2':'
    git log --graph --pretty=format:'%Cred%h%Creset %s' --abbrev-commit $2..$1
    echo 'Commits that exist in '$2' but not in '$1':'
    git log --graph --pretty=format:'%Cred%h%Creset %s' --abbrev-commit $1..$2
}
