
function k
    set server_name (basename $PWD | sed 's/\.//g')
    kcr create $server_name
    kcr attach $server_name
end
