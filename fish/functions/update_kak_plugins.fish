set __autoload $HOME/.config/kak/autoload

function update_kak_plugins --description 'Installs/updates kakoune plugins'
  mkdir -p $__autoload

  set plugin_repos  "https://github.com/alexherbo2/auto-pairs.kak.git"


  for repo in $plugin_repos
    echo "Updating $repo..."
    set plugin_dir (basename $repo .git)
    set plugin_path $__autoload/$plugin_dir
    if not test -d $plugin_path
      git clone $repo $plugin_path
    else
      pushd $plugin_path
      git pull
      popd
    end
  end

end
