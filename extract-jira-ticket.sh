#!/bin/sh

COMMIT_MSG_FILE=$1

BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD 2> /dev/null | grep -oE "[A-Z]+-[0-9]+")
# check if an actual branch name was extract AND ensure that it's not already in the commit message that we have so far
if [ -n "$BRANCH_NAME" ] && ! grep -q "$BRANCH_NAME:" "$COMMIT_MSG_FILE"; then
    echo "${BRANCH_NAME}: $(cat "$COMMIT_MSG_FILE")" > "$COMMIT_MSG_FILE"
fi
