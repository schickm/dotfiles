mkdir -p ~/bin
mkdir -p ~/.ssh
mkdir -p ~/.config/kak/plugins/

ln -s ~/vc/dotfiles/gitconfig ~/.gitconfig
ln -s ~/vc/dotfiles/tmux.conf ~/.tmux.conf
ln -s ~/vc/dotfiles/kakrc ~/.config/kak/kakrc
ln -s ~/vc/dotfiles/ssh/config ~/.ssh/config
ln -s ~/vc/dotfiles/tigrc ~/.tigrc
ln -s ~/vc/dotfiles/kak-mgr.sh ~/bin/k

mkdir -p ~/Library/Preferences/kak-lsp/
ln -s ~/vc/dotfiles/kak-lsp.toml ~/Library/Preferences/kak-lsp/kak-lsp.toml

brew install direnv zsh zsh-completions coreutils tig jq rust pup nodenv diff-so-fancy editorconfig aspell difftastic
brew cask install amethyst

git clone https://github.com/andreyorst/plug.kak.git ~/.config/kak/plugins/plug.kak
