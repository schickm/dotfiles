face global search +u

def search-highlighting-enable -docstring 'Enable search highlighting' %{
  hook window -group search-highlighting NormalKey [/?*nN]|<a-[/?*nN]> %{ try %{
    add-highlighter dynregex '%reg{/}' 0:search
  }}
  hook window -group search-highlighting NormalKey <esc> %{ try %{
    remove-highlighter dynregex_%reg{<slash>}
  }}
}

def search-highlighting-disable -docstring 'Disable search highlighting' %{
  remove-highlighter dynregex_%reg{<slash>}
  remove-hooks window search-highlighting
}

hook global WinCreate .* %{
    search-highlighting-enable
}
