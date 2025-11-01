function k
    set server_name (basename $PWD | sed 's/[[:blank:][:punct:]]//g')

    if ! test (kak -l | grep $server_name)
        kak -d -s $server_name & disown
    end

    kak -c $server_name $argv
end
