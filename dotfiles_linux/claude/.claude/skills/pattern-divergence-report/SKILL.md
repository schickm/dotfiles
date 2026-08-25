---
name: pattern-divergence-report
description: Analyzes code for places where new code diverges from existing code's patterns.
disable-model-invocation: true
context: fork
---

For your current branch, make a report of places where the newly added code diverges from existing patterns in the codebase.

The end product should be an HTML page. Write the page body to a scratch file as an HTML fragment. Then read
`~/.claude/skills/interactive-report/SKILL.md` and follow it, with:

- `content` = the scratch file path
- `title` = a title for the page
- `slug` = `explanation-<short slug for the change>`
- `repo` = the absolute path of the repo the change is in
