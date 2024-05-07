#!/bin/sh

COMMIT_MSG_FILE=$1
BRANCH_NAME=$(sh ~/vc/dotfiles/extract-jira-ticket.sh)

# check if an actual branch name was extract AND ensure that it's not already in the commit message that we have so far
if [ -n "$BRANCH_NAME" ] && ! grep -q "$BRANCH_NAME:\|fixup!" "$COMMIT_MSG_FILE"; then
    echo "${BRANCH_NAME}: $(cat "$COMMIT_MSG_FILE")" > "$COMMIT_MSG_FILE"
fi
