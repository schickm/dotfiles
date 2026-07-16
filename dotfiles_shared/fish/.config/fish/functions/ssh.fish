function ssh --wraps=ssh --description 'ssh via kitten when inside kitty'
  if set -q KITTY_WINDOW_ID; and command -q kitten
    kitten ssh $argv
  else
    command ssh $argv
  end
end
