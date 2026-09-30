---
name: papercuts-review
description: Triage the accumulated papercuts by category and work through them with the user.
disable-model-invocation: true
---

# Papercuts review

A session in two phases: a **triage** report that ends with a question, then a
**work loop** driven one category at a time. The user steers; every item ends
in `papercuts resolve` with a note that records the cause and the fix, so the
log stays the source of truth.

## 1. Triage

### Gather

`PAPERCUTS_FILE` is exported machine-wide, so every command reads and writes
the one global log.

```sh
papercuts list --status open --limit 500 --format md
```

The `md` format groups by severity with IDs inline. The `json` format's
`items` are flat records (no `cut` wrapper); use it only to pull one record by
`id`.

### Categorize

Group by *where the fix lives*, not by tag: the harness (Claude Code tools and
skills it ships), local skills and docs, a dev environment, each project with
several items, remote hosts and sudo, the workstation, and a final bucket of
third-party behaviour that is a usage note rather than a defect. Six to nine
categories. Within a category list every item as ID, severity if not minor, and
one line. Mark pairs that describe the same problem: one of each pair gets
resolved as a duplicate later.

### Scan issue trackers

For every item that touches an open-source project, check whether it is
already filed. First confirm which local repos are public:

Dispatch one subagent per tracker (or per small group of trackers), all in one
message, read-only, with the problems spelled out and a fixed report shape:
up to three matches per problem as number, title, state, URL, one line on fit;
otherwise "no match found" plus the queries tried. Gotchas to pass along:

- `gh search issues` rejects `--state all`; use `gh issue list --repo X
  --search "..." --state all` or search without a state flag.
- GitHub search rate-limits after a dozen queries; keep queries few and ask
  the agent to say which results may be incomplete.
- Bug trackers behind Anubis (gitlab.archlinux.org) block fetches; web search
  is the fallback.

While agents run, check cheap local facts that change the verdict: the
installed version of the tool (`mise --version`, `gh --version`), whether a
package that would fix it exists and is installed (`pacman -Si`, `pacman -Q`).

### Report

One message: the categories in the order to work them, upstream matches as
links with their state, the side facts, the total. End with a question naming
the first category. No fixes yet.

## 2. Work loop

The user picks a category, then directs item by item. Three verbs recur:

Generally, there are 3 actions that the user will be taking

**Close out / resolve.** Resolve without further work. The note carries what a
future reader needs: the upstream issue that already covers it, or the
workaround, or just that the user wanted to close it.

**More detail.** Investigate before proposing anything. Pull the full record
for its `cwd` and `repo`. Reproduce the failure in a disposable copy (a scratch
worktree, a temp dir) and remove it afterwards. When an upstream fix exists,
check that it applies to *this* setup: the installed version, and layout
assumptions. Report the
cause, why the upstream fix does or does not apply, and the options best-first
with the exact command for the recommended one. Stop there; the user decides.

**Apply.** Apply, then verify
with a real trial, then resolve with a note that names the cause and the fix.
When the edit landed in a git checkout, say so and where; commit only when
asked.

After each batch: the open count, and the next categories to choose from.
