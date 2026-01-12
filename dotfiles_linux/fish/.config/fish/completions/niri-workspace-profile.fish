# Completion for niri-workspace-profile profile names
complete -c niri-workspace-profile -f -n "__fish_is_nth_token 1" \
    -a "(command ls ~/.config/niri-workspaces/*.json 2>/dev/null | xargs -n1 basename | sed 's/\.json\$//')"
