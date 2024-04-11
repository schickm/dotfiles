
define-command -override surround -docstring %{
 Surround all selections with the typed character.
} %{ on-key %{ evaluate-commands %sh{
  left=$kak_key
  right=$kak_key
  pair() {
   ( [ "$kak_key" = "$1" ] || [ "$kak_key" = "$2" ] ) \
   && left=$1 && right=$2
  }
  pair '(' ')' || pair '[' ']' ||
  pair '{' '}' || pair '<lt>' '<gt>'
  printf "execute-keys %%{i%s<esc>a%s<esc>}" "$left" "$right"
}}}
