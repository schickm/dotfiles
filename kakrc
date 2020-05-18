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
source ~/vc/dotfiles/kak/buffers.kak

plug "andreyorst/plug.kak" noload

plug "schickm/kakoune-ember"

plug "alexherbo2/auto-pairs.kak" config %{
    hook global WinSetOption filetype=(javascript|kak) %{
    	auto-pairs-enable
    }
}

plug "alexherbo2/surround.kak" config %{
    set-option global surround_begin auto-pairs-disable
    set-option global surround_end auto-pairs-enable
}

evaluate-commands %sh{
    if [ -f .kakrc.local ]
    then
        printf "source .kakrc.local"
    fi
}
