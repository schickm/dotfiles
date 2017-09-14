decl str-list auto_pairs %((,):{,}:[,]:<,>:",":',':`,`)

def -hidden -params 2 auto-pairs-insert-opener %{ try %{
  exec -draft ';<a-K>[[:alnum:]]<ret>'
  exec -no-hooks "%arg{2}<a-;>H"
}}

def -hidden -params 2 auto-pairs-insert-closer %{ try %{
  exec -draft ";<a-k>\Q%arg{2}<ret>d"
}}

def -hidden -params 2 auto-pairs-delete-opener %{ try %{
  exec -draft ";<a-k>\Q%arg{2}<ret>d"
}}

def -hidden -params 2 auto-pairs-delete-closer %{ try %{
  exec -draft "h<a-k>\Q%arg{1}<ret>d"
}}

def -hidden auto-pairs-insert-new-line %{ try %{
  %sh{
    regex=$(printf '\Q%s\E' "$kak_opt_auto_pairs" | sed s/:/'\\E|\\Q'/g';'s/'<,>'/'<lt>,<gt>'/g';'s/,/'\\E\\n\\h*\\Q'/g)
    echo "exec -draft %(;K<a-k>$regex<ret>)"
  }
  exec <ret>
  exec -draft 'k<a-x>dO'
  exec <up><end>
}}

def -hidden auto-pairs-insert-space %{
  %sh{
    regex=$(printf '\Q%s\E' "$kak_opt_auto_pairs" | sed s/:/'\\E|\\Q'/g';'s/'<,>'/'<lt>,<gt>'/g';'s/,/'\\E\\h\\Q'/g)
    echo "exec -draft %(;2H<a-k>$regex<ret>)"
  }
  exec -no-hooks <space><left>
}

def auto-pairs-enable %{
  %sh{
    for pair in $(echo "$kak_opt_auto_pairs" | tr : '\n'); do
      opener=$(echo $pair | cut -d , -f 1)
      closer=$(echo $pair | cut -d , -f 2)
      echo "hook window InsertChar \Q$closer -group auto-pairs-insert %(auto-pairs-insert-closer %-$opener- %-$closer-)"
      echo "hook window InsertChar \Q$opener -group auto-pairs-insert %(auto-pairs-insert-opener %-$opener- %-$closer-)"
      echo "hook window InsertDelete \Q$opener -group auto-pairs-delete %(auto-pairs-delete-opener %-$opener- %-$closer-)"
      echo "hook window InsertDelete \Q$closer -group auto-pairs-delete %(auto-pairs-delete-closer %-$opener- %-$closer-)"
    done
  }
  hook window InsertChar \n -group auto-pairs-insert auto-pairs-insert-new-line
  hook window InsertChar \h -group auto-pairs-insert auto-pairs-insert-space
}

def auto-pairs-disable %{
  remove-hooks window auto-pairs-insert
  remove-hooks window auto-pairs-delete
}
