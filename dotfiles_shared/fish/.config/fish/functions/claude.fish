function claude
    # Tell the chrome-devtools MCP which already-running Chrome to attach to:
    # the per-project debug port from `claude-cdp-info` (same value `claude-chrome`
    # launched on). Chrome is expected to already be running for this project
    # (launch it with `claude-chrome`); the MCP attaches via --browserUrl.
    set -lx CDP_PORT (claude-cdp-info)[2]

    DISABLE_INSTALLATION_CHECKS=1 DISABLE_AUTOUPDATER=1 /bin/claude $argv
end
