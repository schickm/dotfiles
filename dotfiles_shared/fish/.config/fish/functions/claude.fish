function claude
    # The chrome-devtools MCP runs in launch mode (mcpServers.chrome-devtools in
    # ~/.claude.json): on the first browser tool call of a session it launches a
    # headless Chrome itself — using this project's profile and exposing this
    # project's debug port — and closes it when the session ends. Nothing runs
    # when no session needs a browser. CDP_PROFILE/CDP_PORT parameterize that
    # server config; the debug port keeps `chrome://inspect` (from a personal
    # Chrome, via Configure → 127.0.0.1:$CDP_PORT) available to screencast into
    # the headless instance for manual logins/2FA.
    set -l info (claude-cdp-info)
    set -lx CDP_PROFILE $info[1]
    set -lx CDP_PORT $info[2]

    # Seed the profile from the template on first use (logins/extensions), since
    # the MCP may launch Chrome before `claude-chrome` ever runs for this project.
    if not test -d $CDP_PROFILE
        mkdir -p (dirname $CDP_PROFILE)
        cp -r $HOME/.cache/claude-chrome-template $CDP_PROFILE
    end

    DISABLE_INSTALLATION_CHECKS=1 DISABLE_AUTOUPDATER=1 /bin/claude $argv
end
