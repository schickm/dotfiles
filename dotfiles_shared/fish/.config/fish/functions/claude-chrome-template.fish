function claude-chrome-template \
    --description "Launch Chrome on the claude-code MCP template profile to edit its extensions/logins"

    set -l template $HOME/.cache/claude-chrome-template
    mkdir -p $template

    echo "Editing template profile: $template"
    echo "Install/remove extensions and sign into accounts, then quit Chrome."
    echo "Per-session profiles are seeded from this on first use; delete"
    echo "~/.cache/claude-chrome/* to re-seed existing ones."

    # --password-store=basic: encrypt cookies/passwords with the hardcoded key
    # (v10) instead of the keyring (v11), so the profile stays decryptable when
    # the MCP launches Chrome via Puppeteer. Must match the MCP's --chromeArg.
    google-chrome-stable --user-data-dir=$template --password-store=basic $argv
end
