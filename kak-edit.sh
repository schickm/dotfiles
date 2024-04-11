#!/bin/sh

echo "eval -client $1 edit $2" | kak -p $3
