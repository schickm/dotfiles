#!/bin/sh
#
# Utility script that is meant to connect a file path to an existing kak session. It uses the PWD
# to determine the kakoune session name.
#
# Written for integration with iTerm.  Preferences -> Profiles -> Advanced -> Semantic History:
#  Run Command ~/bin/edit-file-in-kak-session.sh \5 \1 \2
#
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <pwd> <file> <line num>" >&2  # Error message to stderr
  exit 1  # Exit with error code
fi

pwd=$1
file=$2
line=$3
kak_session=$(basename "$pwd" | sed 's/[[:blank:][:punct:]]//g')
kak_client='client0'

echo "evaluate-commands -try-client $kak_client edit $file $line" | ~/bin/kak -p "$kak_session"
