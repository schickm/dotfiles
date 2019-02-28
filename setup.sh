mkdir -p ~/bin
mkdir -p ~/.ssh
mkdir -p ~/.config/kak/plugins/

ln -s ~/vc/dotfiles/gitconfig ~/.gitconfig
ln -s ~/vc/dotfiles/tmux.conf ~/.tmux.conf
ln -s ~/vc/dotfiles/kakrc ~/.config/kak/kakrc
ln -s ~/vc/dotfiles/ssh/config ~/.ssh/config
ln -s ~/vc/dotfiles/tigrc ~/.tigrc

brew install direnv zsh zsh-completions coreutils tig kak-lsp
brew cask install amethyst

git clone https://github.com/andreyorst/plug.kak.git ~/.config/kak/plugins/plug.kak
