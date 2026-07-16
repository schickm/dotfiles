function ssh --wraps=ssh --description 'ssh via kitten when inside kitty'
  # kitten ssh intentionally forwards KITTY_WINDOW_ID to remotes (so remote
  # kitten icat/clipboard/etc. can reach the local kitty), so its presence
  # alone doesn't mean we're local. SSH_CONNECTION/SSH_TTY mark a remote shell.
  if set -q KITTY_WINDOW_ID
     and not set -q SSH_CONNECTION
     and not set -q SSH_TTY
     and command -q kitten
    kitten ssh $argv
  else
    command ssh $argv
  end
end
