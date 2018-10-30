mkdir -p ~/bin
mkdir -p ~/.config/kak
mkdir -p ~/.ssh

ln -s ~/vc/dotfiles/gitconfig ~/.gitconfig
ln -s ~/vc/dotfiles/tmux.conf ~/.tmux.conf
ln -s ~/vc/dotfiles/kakrc ~/.config/kak/kakrc
ln -s ~/vc/dotfiles/ssh/config ~/.ssh/config

brew install direnv zsh zsh-completions
