function claude-cdp-info \
    --description "Print this project's Chrome profile dir and DevTools debug port (one per line). Arg: dir (default PWD)."

    # Single source of truth for the per-project key, shared by `claude` (which
    # tells the MCP which port to attach to) and `claude-chrome` (which launches
    # Chrome on that port). Both must compute identical values, so keep this the
    # only place the derivation lives.
    set -l dir $argv[1]
    test -n "$dir"; or set dir $PWD

    # normalize the path so the key is truly deterministic: strip trailing
    # slashes, collapse ./ ../ and redundant slashes, make absolute. -ms keeps
    # it lexical (no symlink resolution) so it matches fish's logical $PWD.
    set dir (realpath -ms -- $dir)

    # human-readable profile name: basename + short hash for uniqueness
    set -l proj (string replace -ra '[^A-Za-z0-9._-]' '-' (basename $dir))
    set -l hash (echo $dir | md5sum | string sub -l 6)

    # deterministic debug port in [10000, 14999] derived from the full path
    set -l sum (echo $dir | cksum | string split ' ')[1]
    set -l port (math $sum % 5000 + 10000)

    echo $HOME/.cache/claude-chrome/$proj-$hash
    echo $port
end
