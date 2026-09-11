---
name: explain-diff-html
description: Use when the user asks for a rich explanation of a code change, diff, branch, or PR. Produces HTML output.
disable-model-invocation: true
---

# Explain Diff

Please make me a rich, interactive explanation of the specified code change.

This skill decides **what the explanation says**. The page is published as an
artifact; see Publish.

## Sections

- **Background**: Explain the existing system relevant to this change. Explore the
  surrounding code broadly first. We don't know how much the reader already knows, so
  give a deep background for beginners in a collapsed `<details>`, and then a
  narrow background directly relevant to the change.
- **Intuition**: Explain the core intuition for the code change. The focus here is the
  essence, not the full details. Use concrete examples with toy data. Use figures and
  diagrams liberally.
- **Code**: Do a high-level walkthrough of the changes to the code. Group and order
  the changes in an understandable way.

## Writing

- Write with the clarity and flow of Martin Kleppmann. Make it engaging, in classic
  style. Transitions between sections should be smooth.
- One long page with section headers and a table of contents. No tabs for the
  top-level structure.
- Diagrams: pick a small number of diagram families and reuse them through the whole
  explanation. Two that work well:
  - A very simplified version of the app UI, to explain UI changes.
  - A system diagram that shows data flow between components. Put example data in it.

## Publish

Publish the page with the Artifact tool, in this session. Only the main session holds
the comment watch, so a page published by a subagent leaves readers' questions
unanswered. Load the `artifact-design` skill before writing the page; the Artifact
tool's own rules cover the file shape, theme, and embedded images.

In the final message give the artifact URL, and say that this session answers comments
sent to Claude while it runs.
