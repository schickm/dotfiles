#!/bin/sh

cleanup='s|/Users/mattschick/|| ; s|jellyvc/|| ; s/[^[:alnum:]-]/_/g'
repo=$(git rev-parse --show-toplevel 2>/dev/null | sed "$cleanup" | tail -c 36)
args=

if [ -n "$repo" ]; then
    if kak -l | grep -wq "$repo"; then
        args="-c $repo" # join session
    else
        args="-s $repo" # make session
    fi
fi

exec kak $args $@ # launch editor
