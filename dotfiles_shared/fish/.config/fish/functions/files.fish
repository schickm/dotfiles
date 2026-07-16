function files --wraps='ssh -t files.local "tmux a || tmux"' --description 'ssh to files.local and attach tmux'
    ssh -t files.local "tmux a || tmux" $argv
end
