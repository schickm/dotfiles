function urlescape -a value
    string escape --style=url $value | sed -r 's|/|%2F|g'
end
