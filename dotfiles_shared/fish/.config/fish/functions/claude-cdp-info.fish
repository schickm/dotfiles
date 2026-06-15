function claude-cdp-info \
    --description "Print this project's Chrome profile dir and DevTools debug port (one per line). Arg: dir (default PWD)."

    # Single source of truth for the per-project key, shared by `claude` (which
    # tells the MCP which port to attach to) and `claude-chrome` (which launches
    # Chrome on that port). Both must compute identical values, so keep this the
    # only place the derivation lives.
    set -l dir $argv[1]
    test -n "$dir"; or set dir $PWD

    # Anchor on the git worktree root so the profile is stored IN the project
    # (at <root>/.claude-chrome) and is identical no matter which subdirectory
    # we're launched from. Outside a repo, fall back to the normalized dir.
    # realpath -ms keeps the fallback lexical (no symlink resolution) so it
    # matches fish's logical $PWD.
    set -l root (git -C $dir rev-parse --show-toplevel 2>/dev/null)
    test -n "$root"; or set root (realpath -ms -- $dir)

    # deterministic debug port in [10000, 14999] derived from the root path
    set -l sum (echo $root | cksum | string split ' ')[1]
    set -l port (math $sum % 5000 + 10000)

    echo $root/.claude-chrome
    echo $port
end
