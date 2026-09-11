---
name: pattern-divergence-report
description: Analyzes code for places where new code diverges from existing code's patterns.
disable-model-invocation: true
---

For your current branch, make a report of places where the newly added code diverges from existing patterns in the codebase.

The end product is one HTML page. For each divergence show the new code, the existing
pattern it departs from, and where that pattern lives.

## Publish

Publish the page with the Artifact tool, in this session. Only the main session holds
the comment watch, so a page published by a subagent leaves readers' questions
unanswered. Load the `artifact-design` skill before writing the page; the Artifact
tool's own rules cover the file shape, theme, and embedded images.

In the final message give the artifact URL, and say that this session answers comments
sent to Claude while it runs.
