# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .*\.(hbs) %{
    set buffer filetype handlebars
}

addhl -group / regions -default raw handlebars \
    expression {{ }} ''

addhl -group /handlebars/raw ref html
addhl -group /handlebars/expression regex \{\{[#/]?(\w+(?:-\w+)*) 1:keyword
addhl -group /handlebars/expression regex \h*(\w+(?:-\w+)*)= 1:identifier 
addhl -group /handlebars/expression regex \h+(as)\h+(?<!\|)(\|\h*(?:\w+)(?:\h*(?:\w+))*\h*\|)(?!\|) 1:identifier 2:identifier
addhl -group /handlebars/expression regions content \
    string '"' (?<!\\)(\\\\)*"      '' \
    string "'" "'"                  ''
addhl -group /handlebars/expression/content/string fill string
# addhl -group /handlebars/expression regex \h*(\w+(?:-\w+))=(\w+) 1:keyword 2:value

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾
hook -group handlebars-highlight global WinSetOption filetype=handlebars %{ addhl ref handlebars }
