# /tmp/ranger-files is populated by ranger --choosefiles
def -hidden load-files-from-ranger -override %{ evaluate-commands %sh{
  while read f; do
    echo "edit $f;"
  done < '/tmp/ranger-files'
}}

map global user r ':suspend-and-resume " ranger --choosefiles=/tmp/ranger-files" load-files-from-ranger<ret>' -docstring 'select files in ranger'
