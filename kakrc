source "%val{config}/plugins/plug.kak/rc/plug.kak"

source ~/vc/dotfiles/kak/commands.kak
source ~/vc/dotfiles/kak/options.kak
source ~/vc/dotfiles/kak/key-mapping.kak
source ~/vc/dotfiles/kak/grep.kak
source ~/vc/dotfiles/kak/linting.kak
source ~/vc/dotfiles/kak/formatting.kak
source ~/vc/dotfiles/kak/ui.kak
source ~/vc/dotfiles/kak/editorconfig.kak
source ~/vc/dotfiles/kak/modeline.kak
source ~/vc/dotfiles/kak/search.kak
source ~/vc/dotfiles/kak/lsp.kak
source ~/vc/dotfiles/kak/npm.kak
source ~/vc/dotfiles/kak/markdown.kak
source ~/vc/dotfiles/kak/latex.kak
source ~/vc/dotfiles/kak/kak.kak
source ~/vc/dotfiles/kak/gitlab.kak

plug "andreyorst/plug.kak" noload

plug "schickm/kakoune-ember"

plug "alexherbo2/auto-pairs.kak" config %{
    enable-auto-pairs
}

plug "alexherbo2/lib.kak"
plug "alexherbo2/surround.kak"
plug "https://gitlab.com/Screwtapello/kakoune-shellcheck"
plug "https://github.com/occivink/kakoune-find"

evaluate-commands %sh{
    if [ -f .kakrc.local ]
    then
        printf "source .kakrc.local"
    fi
}

evaluate-commands %sh{
    kcr init kakoune
}
