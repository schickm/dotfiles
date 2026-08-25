---
name: explain-diff-html
description: Use when the user asks for a rich explanation of a code change, diff, branch, or PR. Produces HTML output.
disable-model-invocation: true
---

# Explain Diff

Please make me a rich, interactive explanation of the specified code change.

This skill decides **what the explanation says**. The `interactive-report` skill turns
it into the published HTML page. Write the content as a fragment, then follow that
skill.

## Sections

- **Background**: Explain the existing system relevant to this change. Explore the
  surrounding code broadly first. We don't know how much the reader already knows, so
  give a deep background for beginners in a `<details class="skippable">`, and then a
  narrow background directly relevant to the change.
- **Intuition**: Explain the core intuition for the code change. The focus here is the
  essence, not the full details. Use concrete examples with toy data. Use figures and
  diagrams liberally.
- **Code**: Do a high-level walkthrough of the changes to the code. Group and order
  the changes in an understandable way.
- **Quiz**: Write five questions that test the reader's knowledge of this PR. Medium
  difficulty: hard enough that you must understand the substance of the PR to answer
  them, but not gotchas. The goal is to help the reader confirm that they understood.

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

Write the page body to a scratch file as an HTML fragment. Then read
`~/.claude/skills/interactive-report/SKILL.md` and follow it, with:

- `content` = the scratch file path
- `title` = a title for the page
- `slug` = `explanation-<short slug for the change>`
- `repo` = the absolute path of the repo the change is in

That skill lists the component classes to use for callouts, figures, diagrams,
timelines and the quiz. Follow its steps in this session. Do not send them to a
subagent — the same session has to answer the reader's comments.
