#!/bin/sh

# Meant to be called by kakoune so that nnn redirects opened files back kakoune client that called
# it.

if [ "$#" -le 1 ] || [ "$#" -ge 4 ]; then
  echo "Usage: $0 <kak_session> <kak_client> [<directory to open>]" >&2  # Error message to stderr
  exit 1  # Exit with error code
fi

# Export these so that they are available inside of nnn-kak-opener.sh.  NNN doesn't support openers
# being passed arguments, so thus we have to make them available in the ENV.
export kak_session="$1"
export kak_client="$2"

# and set the opener script.  This will get triggered by NNN whenever a file is opened in it, passing
# the file name as the first argument
export NNN_OPENER="nnn-kak-opener.sh"

# Change directory if new one was given
path="$3"
if test -n "$path"; then
  if [ -f "$path" ]; then
    path="$(dirname "$path")"
  elif [ ! -d "$path" ]; then
    echo "Error: '$path' is not a file or directory" >&2
    exit 1
  fi

  if [ -d "$path" ]; then
    cd "$path" || {
      echo "Error: Failed to change directory to '$path'" >&2
      exit 1
    }
  else
    echo "Error: '$path' is not a directory" >&2
    exit 1
  fi
fi

# and lastly launch nnn
nnn
