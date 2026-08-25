---
name: interactive-report
description: Turn a page-body HTML fragment into a published, self-contained interactive report in ~/reports/ with a Figma-style comment layer answered live by this session. Called by content-producing skills (explain-diff-html, validate-code-review); also usable directly on a fragment you already wrote.
disable-model-invocation: true
---

# Interactive Report

This skill owns the **medium**, not the content. A caller hands it a page body; it
produces one self-contained HTML file, starts the comment bridge, and makes this
session the live responder for reader questions.

## Inputs

| Input | Meaning |
|---|---|
| `content` | Absolute path to the page body: an HTML **fragment**, everything that goes inside `<div class="wrap">`. Not a full document. Not markdown. |
| `title` | Page title. Goes in `<title>`. The fragment supplies its own `<h1>`. |
| `slug` | Filename slug, kebab-case, no date. |
| `repo` | Absolute path of the repository the report is about. |

Output: `~/reports/YYYY-MM-DD-<slug>.html`.

## Run this inline

Do every step below in the main session. Do not delegate any step to a subagent.
Step 6 makes this session answer reader questions from its own warm context. A
subagent does not have that context, and a fresh `claude -p` re-reads about 100k
tokens for each question.

## What the fragment must contain

The caller writes the fragment. These rules are the contract. If the fragment breaks
one, fix the fragment before you publish.

1. Every section starts with `<h2 id="...">`. Subsections use `<h3 id="...">`. The
   table of contents and the comment anchors both read these ids.
2. Include one empty `<nav class="toc"></nav>` after the header block. `shell.js`
   fills it. A `nav.toc` that already has children is left alone.
3. Code goes in `<pre>`. Never put code in a styled `<div>`. If you do use a `div`,
   its CSS must set `white-space: pre` or `pre-wrap`, or the browser joins every line
   into one. Check each code block in the source before you publish.
4. Diagrams are HTML, never ASCII art. Use the component classes below.
5. Images must be `data:` URIs. The file has to work when it is copied anywhere.
6. The fragment may include `<script>` tags. `window.QUIZ` is the only one the shell
   reads.

### Component classes

Use these. They are styled by `assets/shell.css`, and the comment layer anchors to
`.callout`, `.fig`, `.q`, `.timeline` and `.browser-row`. A class you invent gets no
style and no comment pin.

- Page header: `<p class="subtitle">`, `<div class="meta">`.
- `<div class="callout">` with an optional `<span class="label">`. Colour variants:
  `.blue`, `.green`, `.red`.
- `<details class="skippable">` for background a reader may skip.
- `<div class="fig">` for any diagram, with an optional `<div class="caption">`.
  Inside a `fig`:
  - `<div class="flow">` holding `<div class="node">` (`.hi`, `.blue`, `.green`,
    `.bad`) separated by `<span class="arrow">→</span>`.
  - `<span class="pill">` for a value or a token (`.hi`, `.green`, `.red`).
  - `<div class="ui">` for a simplified picture of the app, with `<div class="bar">`,
    `<div class="content">`, `<span class="btn">`.
  - `<div class="side">` to place two figures next to each other.
- `<div class="timeline">` holding `<div class="step">` with `<span class="when">`.
- `<div class="browser-row">` holding `<div class="shot"><img><div class="caption">`
  for screenshot evidence.
- `<div class="tablewrap">` around any wide table.
- Quiz: put `<div class="quiz" id="quiz"></div>` where the quiz belongs, and set the
  questions in a script in the fragment:

  ```html
  <script>window.QUIZ = [
    { stem: "…", options: ["…", "…", "…", "…"], answer: 1, fb: ["…", "…", "…", "…"] }
  ]</script>
  ```

  `answer` is a zero-based index. `fb` holds one response per option. `stem`,
  `options` and `fb` accept inline HTML. Omit both the div and `window.QUIZ` when the
  report needs no quiz.

## Steps

### 1. Check the fragment

Read the content file. Confirm the rules above. Two failures are common and silent:
a code block with no `white-space` rule, and a heading with no `id`.

### 2. Assemble the page

Write `~/reports/YYYY-MM-DD-<slug>.html` in this exact order. `S` is this skill's
directory, `~/.claude/skills/interactive-report`.

1. `<title>` with the `title` input.
2. `<style>`, then the verbatim contents of `S/assets/shell.css`, then `</style>`.
3. `<div class="wrap">`, then the verbatim contents of the content file, then `</div>`.
4. `<script>`, then the verbatim contents of `S/assets/shell.js`, then `</script>`.
5. The meta script, filled in at step 3 below.
6. The verbatim contents of `S/assets/comment-layer.html`.

Use `cat` to concatenate the files. Do not retype the assets, and do not edit them per
report. A report-specific style goes in a small `<style>` block inside the fragment.

Never write the report to `/tmp`. The cleaner deletes it. Create `~/reports/` if it
does not exist. The date prefix keeps the files sorted and out of version control.

### 3. Find this session's id, then write the meta script

Do this in two separate Bash calls. The transcript line only lands after the first
call returns.

1. `echo "report-nonce-$RANDOM$RANDOM"`
2. `grep -l "<nonce>" ~/.claude/projects/*/*.jsonl`

The basename of the single matching file, without `.jsonl`, is the session id. If the
grep matches nothing, use `ls -t ~/.claude/projects/*/*.jsonl | head -1`.

Insert this line into the page, immediately before the comment layer:

```html
<script>window.__EXPLAINER_META = { sessionId: "<session id>", repo: "<repo>", bridge: "http://127.0.0.1:8790" }</script>
```

### 4. Start the comment bridge

```bash
curl -fsS --max-time 2 http://127.0.0.1:8790/health >/dev/null 2>&1 || \
  setsid nohup python3 ~/.claude/skills/interactive-report/bridge/bridge.py >> /tmp/report-bridge.log 2>&1 &
```

Run a second health check after a moment. If the bridge still does not start, say so
in your final message and continue. The page degrades to an offline badge.

### 5. Claim the responder lease

Write `<report>.responder.json` containing `{"sessionId": "<session id>"}`.

While this session's process is alive, the bridge leaves questions to you. It rescues
any question you leave pending for more than 5 minutes. When this session ends, the
bridge falls back to spawning `claude -p` on its own. No cleanup is needed.

### 6. Become the live responder

Start a persistent Monitor that polls `<report>.comments.json` every 2 seconds and
emits one JSON line `{threadId, msgId, question}` for each **new** pending assistant
message. Prime the seen-set with the pending messages that already exist.

Message schema, and the trap in it: one reader question adds **two** messages to a
thread. The reader's question is `role: "user"`, `status: "done"`. The empty slot for
the answer is `role: "assistant"`, `status: "pending"`. Filter on
`role == "assistant" && status == "pending"`. There is never a pending user message,
so a filter on pending user messages matches nothing and the monitor never fires.
`msgId` is the id of the pending assistant message. `question` is the text of the
nearest earlier user message in the same thread.

When an event arrives:

1. Answer it yourself. Re-read the code if you need to.
2. Write concise plain prose. Inline markdown is fine. No headings.
3. Submit it:

```bash
curl -X POST http://127.0.0.1:8790/answers -H 'Content-Type: application/json' \
  -d '{"report": "<report path>", "msgId": "<id>", "text": "<answer>", "note": "Answered live by the generating session."}'
```

### 7. Report the result

State these in the final message:

- The report path.
- The comment thread path, `<report>.comments.json`.
- Whether the bridge is up.
- That this session answers questions live now, and that the bridge spawns a fresh
  process once this session ends.

Do not open the report in a browser.
