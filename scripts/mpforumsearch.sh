#!/bin/sh

# one liner
# curl https://www.mountainproject.com/ajax/public/search/results/category\?q\=moccasym\&c\=Forums\&o\=0\&s\=Default | jq -r '.results.Forums[] | gsub("\\n"; "")' | while read line; do echo $line | pup 'text{}' | sed 's/^[ \t]*//;s/[ \t]*$//'; done
query=$1
result=$(curl "https://www.mountainproject.com/ajax/public/search/results/category?q=${query}&c=Forums&o=0&s=Default")

$(echo $result | jq -r '.results.Forums[2] | gsub("\\n"; "")')

