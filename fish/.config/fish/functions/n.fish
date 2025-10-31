function n --wraps nnn --description 'my custom launcher for nnn'
    set --export EDITOR kak
    set --export NNN_PLUG 'p:preview-tui'
    set --export NNN_FIFO "/tmp/nnn.fifo"

    nnn
end
