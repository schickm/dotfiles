#!/bin/sh

# This script exists as an "nnn opener".  These are scripts that get called by nnn when a file is
# opened in the UI.  For more details look at nnn-for-kak.sh found in this same directory.

file="$1"

echo "eval -client $kak_client edit $file" | kak -p "$kak_session"

