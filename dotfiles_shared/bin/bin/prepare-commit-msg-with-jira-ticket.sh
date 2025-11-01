#!/bin/sh
#
# To use this, just add the following to any .git/hooks/prepare-commit-msg file (assuming it's in PATH):
#
#    prepare-commit-msg-with-jira-ticket.sh "$1"
#
COMMIT_MSG_FILE="$1"

# Read the first line of the commit message file
FIRST_LINE=$(head -n 1 "$COMMIT_MSG_FILE")

if echo "$FIRST_LINE" | grep -q "^fixup! "; then
    echo "Skipping ticket number prepending for fixup commit."
    exit 0
fi

TICKET=$(extract-jira-ticket.sh)

if test -n "$TICKET" && ! echo "$FIRST_LINE" | grep -q "\[$TICKET\]"; then
    echo "Prepending ticket number."
    printf "%s %s" "[$TICKET]" "$(cat $COMMIT_MSG_FILE)" > "$COMMIT_MSG_FILE"
fi


