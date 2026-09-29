---
name: workvc-repo-setup
description: Set up (or repair) a repo container in ~/workvc so the worktree launchers pick it up.
disable-model-invocation: true
---

# workvc repo setup

A **container** is `~/workvc/<repo>/`: a bare git dir plus machine-local
support files at the top level, git worktrees as subdirectories. The worktree
launchers (Start New Worktree, Start New Ticket, Resume Worktree,
`takeover-pr`) and the waybar/notification plumbing all find containers
through `repo_containers` in `~/bin/worktree-lib.sh`. Its header comment is
the source of truth for the `.worktreerc` hook contract; read it before
writing hooks.

```
~/workvc/<repo>/
  .bare/        bare git dir
  .git          file: "gitdir: .bare"
  .worktreerc   sourced bash — marks the dir as a container
  .wt-addrc     optional /bin/sh, runs in each new worktree ($1 = worktree dir)
  <default>/    worktree of the default branch
```

Input: the GitHub `<owner>/<repo>`. If `~/workvc/<repo>` already exists, this
is a **repair**: inspect what is there and do only the missing steps.

## 1. Git wiring

```sh
mkdir ~/workvc/<repo> && cd ~/workvc/<repo>
git clone --bare git@github.com:<owner>/<repo>.git .bare
echo "gitdir: .bare" > .git
git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git fetch origin
git remote set-head origin --auto
git worktree add <default> <default>
git -C <default> branch --set-upstream-to=origin/<default>
```

Gotchas, each a silent failure:

- `git clone --bare` sets no fetch refspec, so `refs/remotes/origin/*` never
  exists and the base-branch picker shows only stale local branches.
- Without `origin/HEAD`, `pick_base_branch` cannot pin the default branch to
  the top of the menu.

Done when `git -C ~/workvc/<repo> symbolic-ref refs/remotes/origin/HEAD`
prints `refs/remotes/origin/<default>` and `git worktree list` shows the
`<default>` worktree.

## 2. `.worktreerc`

Always write one: without `.worktreerc` or `.wt-addrc`, `repo_containers`
skips the dir and the repo is missing from every picker. Start from this
header and a color:

```bash
# Worktree config for <repo> — sourced by resume-worktree/start-new-ticket
# (see worktree-lib.sh in dotfiles for the hooks' contract).

REPO_COLOR="#rrggbb"  # <color name> — waybar workspace background
```

- `REPO_COLOR`: dark enough for white text, and distinct from the colors
  already taken (`grep REPO_COLOR ~/workvc/*/.worktreerc`).
- Add hooks only where the repo needs them: `worktree_urls` when there is a
  dev server to open, `worktree_launch` when the default windows are wrong,
  `worktree_claude_guidance` for standing Claude guidance. A defined
  `worktree_claude_guidance` replaces the default Chrome MCP line, so restate
  that line if the repo wants it.
- Model on `~/workvc/cyborg/.worktreerc` (minimal) and
  `~/workvc/rwgps-ui/.worktreerc` (dev server, URLs, guidance).

## 3. `.wt-addrc` (when the repo needs per-worktree setup)

Read the repo for what a fresh checkout needs: dependency install, gitignored
local config generated from an example file, a dev-server port. Write a
`/bin/sh` script with `set -e` that `cd`s to `$1` and does exactly that. For
ports, derive one from the branch name and walk past listening ports, so
worktrees don't collide — `~/workvc/cassette/.wt-addrc` is the model. If a
fresh checkout needs nothing, skip this file.

Run it once against the `<default>` worktree: `sh .wt-addrc <default>`.

## 4. Verify

All three hold:

- `bash -c 'source ~/bin/worktree-lib.sh; repo_containers'` lists the
  container.
- The `symbolic-ref` check from step 1 passes.
- If `.wt-addrc` exists, its run in step 3 exited 0.

Then tell the user to open Start New Worktree and confirm the repo appears
with the default branch on top of the base-branch menu.
