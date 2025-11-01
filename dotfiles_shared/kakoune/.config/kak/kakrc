hook -once global KakBegin .* %{
   enable-auto-pairs
}

evaluate-commands %sh{
    if [ -f .kakrc.local ]
    then
        printf "source .kakrc.local"
    fi
}
