#!/bin/bash

server_name=$(basename `PWD`)
socket_file=$(kak -l | grep $server_name)

if [[ $socket_file == "" ]]; then
    # Create new kakoune daemon for current dir
    setsid kak -d -s $server_name &
    sleep 1
fi

# and run kakoune (with any arguments passed to the script)
kak -c $server_name $@
