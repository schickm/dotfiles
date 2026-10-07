# Deprecated

Configuration from the desktop setup that Noctalia replaced in 2026-10. Nothing
here is stowed: the Ansible `dotfiles` role deploys only `dotfiles_shared`,
`dotfiles_linux` and `dotfiles_macos`.

| Package | Was | Replaced by |
|---|---|---|
| `waybar/` | bar config, Solarized style, custom modules | Noctalia bar (`dotfiles_linux/noctalia`) |
| `swaync/` | notification daemon and control center | Noctalia notifications |
| `mako/` | earlier notification daemon, already unused | Noctalia notifications |
| `bin/bin/waybar-failed-units` | failed systemd units module | nothing yet |
| `bin/bin/waybar-workspace-colors` | per-repo workspace button CSS | nothing yet; a Noctalia plugin is the planned home |
| `bin/bin/swaync-slack-record` | swaync script hook that fed `swaync-focus-dismiss`'s Slack rule | nothing; Noctalia has no per-notification script hook |
| `systemd/.../waybar.service.d/` | drop-ins that generated the CSS before waybar started | nothing |

Still in use and therefore not here: `workspace-activity` (the Claude hooks
still record activity claims, which a future bar plugin can read) and
`swaync-focus-dismiss` (closes notifications by freedesktop id, which works
with any daemon).
