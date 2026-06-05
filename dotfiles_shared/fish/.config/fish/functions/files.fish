function files --wraps='kitten ssh -t files.local "tmux a || tmux"' --description 'alias files=kitten ssh -t files.local "tmux a || tmux"'
    kitten ssh -t files.local "tmux a || tmux" $argv
end
