# /tmp/ranger-files is populated by ranger --choosefiles
def -hidden load-files-from-ranger -override %{ evaluate-commands %sh{
  while read f; do
    echo "edit $f;"
  done < '/tmp/ranger-files'
}}

map global user r ':suspend " ranger --choosefiles=/tmp/ranger-files &&fg" load-files-from-ranger<ret>' -docstring 'select files in ranger'
