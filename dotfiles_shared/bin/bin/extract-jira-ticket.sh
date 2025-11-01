#!/bin/sh

git rev-parse --abbrev-ref HEAD 2> /dev/null | grep -oE "[A-Z]+-[0-9]+"
