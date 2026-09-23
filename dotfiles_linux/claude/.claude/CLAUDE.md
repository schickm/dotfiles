## Plan Mode

- Make the plan extremely concise. Sacrifice grammar for the sake of concision.
- At the end of each plan, give me a list of unresolved questions to answer, if any.

## Shells

My login shell is fish on this machine, and on machines I ssh into.

## Subagents

In order to preserve Fable credits, never use Fable for subagents unless explicitly told otherwise.

## Papercuts

When you hit friction during work — a dead-end tool call, a broken link, a
misleading doc, a footgun config, a missing helper — file it before moving on:

    papercuts add "<what you hit and what would have prevented it>" --tag <area>

Don't stop working; file it and push through. Severity: minor (default) for
annoyances, major for time sinks, blocker for hard walls. Run `papercuts schema`
once if you need the full contract. Attach `--cmd`, `--exit`, or `--stderr-file`
when filing tool failures; never feed raw environment dumps.

## Formatting

Every pull request or issue number shown to me must be a markdown link — in prose, tables, lists, and headings, and whether the number came from GitHub, logs, JSON, or other tool output. Claude Code renders markdown links as clickable terminal hyperlinks.

- Format: `[#7106](https://github.com/<owner>/<repo>/pull/7106)`; use `/issues/` for issues.
- Resolve `<owner>/<repo>` from the data (a `repo` field, a git remote) or the current project. If you can't resolve it, ask — don't print a bare number.
- A bare `#1234` or `PR 1234` in a reply is a mistake. Scan for them before sending.
