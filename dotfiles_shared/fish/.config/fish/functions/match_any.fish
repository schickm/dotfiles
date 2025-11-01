function match_any --description "Checks if any of the regexs match the test string.  <test string> <regex> [<regex>, ...]"
    set -l test_string $argv[1]
    set -l patterns $argv[2..-1]

    for pattern in $patterns
        if string match -qr "$pattern" "$test_string"
            return 0
        end
    end

    return 1
end
