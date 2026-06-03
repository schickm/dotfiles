function claude-chrome \
    --description "Launch this project's Chrome (seeded from template) with remote debugging so the chrome-devtools MCP can attach. Arg 1: workspace dir (default PWD). Remaining args are passed to Chrome (e.g. URLs to open)."

    set -l info (claude-cdp-info $argv[1])
    set -l profile $info[1]
    set -l port $info[2]
    set -l extra $argv[2..-1]

    # seed from the template on first use so extensions/logins are present
    if not test -d $profile
        mkdir -p (dirname $profile)
        cp -r $HOME/.cache/claude-chrome-template $profile
    end

    echo "Launching Chrome for "(basename $profile)" on debug port $port"
    echo "  profile:   $profile"
    echo "  attach at: http://127.0.0.1:$port"

    # --password-store=basic keeps cookies decryptable (v10) by any launch context;
    # --remote-debugging-port is the per-project port the MCP attaches to.
    google-chrome-stable \
        --user-data-dir=$profile \
        --password-store=basic \
        --remote-debugging-port=$port $extra &
    disown
end
