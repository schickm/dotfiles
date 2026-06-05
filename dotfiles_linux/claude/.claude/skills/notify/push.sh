#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <title> <message>" >&2
  exit 1
fi

source ~/.claude/skills/notify/config

curl -s -X POST https://api.pushover.net/1/messages.json \
  -d "token=$PUSHOVER_TOKEN" \
  -d "user=$PUSHOVER_USER" \
  -d "title=$1" \
  -d "message=$2"
