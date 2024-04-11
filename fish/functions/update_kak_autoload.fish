set __autoload $HOME/.config/kak/autoload


function update_kak_autoload --description 'Installs/updates kakoune plugins'
    mkdir -p $__autoload
    mkdir -p $__plugins

    update_repos
    update_symlinks
end

function update_repos
    set plugin_repos \
        "https://github.com/alexherbo2/auto-pairs.kak.git" \
        "https://gitlab.com/Screwtapello/kakoune-shellcheck.git" \
        "https://github.com/occivink/kakoune-find" \
        "https://bitbucket.org/KJ_Duncan/kakoune-plantuml.kak"
    set __plugins $__autoload/plugins

    for repo in $plugin_repos
        echo "Updating $repo..."
        set plugin (basename $repo .git)
        set plugin_path $__plugins/$plugin
        if not test -d $plugin_path
            git clone $repo $plugin_path
        else
            pushd $plugin_path
            git pull
            popd
        end
    end
end

function update_symlinks
    set __kak_rc "$__autoload/kak_official"
    set __personal_rc "$__autoload/personal"

    mkdir -p $__kak_rc
    mkdir -p $__personal_rc

    ln -s "$HOME/vc/kakoune/rc" "$__kak_rc"
    ln -s "$HOME/vc/dotfiles/kak/autoload" "$__personal_rc"
end
