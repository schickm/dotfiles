---
name: explain-diff-html
description: Use when the user asks for a rich explanation of a code change, diff, branch, or PR. Produces HTML output.
disable-model-invocation: true
---

# Explain Diff

Please make me a rich, interactive explanation of the specified code change.

It should have these sections:

- Background: Explain the existing system relevant to this change. (You should broadly explore surrounding code for this.) We don't know how much the reader already knows, so include a deep background for beginners (note that it can be skipped if the reader is already familiar), and then a more narrow background directly relevant to the change.
- Intuition: Explain the core intuition for the code change. The focus here is to explain the essence, not the full details. Use concrete examples with toy data. Use figures and diagrams liberally.
- Code: Do a high-level walkthrough of the changes to the code. Group/order the changes in an understandable way.
- Quiz: Come up with five questions that test the reader's knowledge of this PR. This should be medium difficulty, difficult enough that you actually need to understand the substance of the PR to answer them, but not gotchas. The goal is to help the reader make sure that they've actually understood. These should be presented as interactive multiple-choice questions, and when the user clicks, it tells them whether they were correct and gives feedback.

Format:

- Output a single self-contained HTML file which includes CSS and JavaScript. Make the whole thing one long page with section headers and a table of contents. Don't use tabs for the top-level structure. Basic responsive styling so you can view it on a phone is nice too. Put the file in `~/reports/` (create the directory if needed — never /tmp, it gets cleaned), and make sure the filename always starts with today's date in `YYYY-MM-DD-` format, because it helps keep the files time-sorted and out of version control. For example: ~/reports/2026-01-12-explanation-<slug>.html
- Please write with the clarity and flow of Martin Kleppmann, making it engaging and written in classic style. Transitions between sections should be smooth.
- Some tips on diagrams. Ideally, you should pick a small number of diagram families that can be reused throughout the explanation to explain various cases. Some useful kinds of diagrams:
  - A very simplified version of the UI that the user sees in the app, to explain UI changes.
  - A system diagram showing data flow or communication between components. Make sure to include example data here!
- Don't use ASCII diagrams. Always use simple HTML designs for your diagrams, HTML lists for lists of things, etc.
  - For code blocks, always use `<pre>` tags. If you use a custom styled div instead, it **must** have
    `white-space: pre-wrap` in its CSS, or the browser will collapse all newlines into a single line.
    Before saving the file, scan each code block in the HTML source and confirm its CSS includes
    `white-space: pre` or `pre-wrap`.
- Use callouts for key concepts or definitions, important edge cases, etc.
- Wrap the page's main content in a single container element with class `wrap` (the comment layer below anchors to it).

Comment layer (interactive Q&A):

Every explainer gets a Figma-style comment layer so I can anchor questions to any passage and have them answered by a fork of the session that generated the report. After writing the HTML file:

1. Discover this session's id. In one Bash call, `echo` a unique nonce (e.g. `explainer-nonce-$RANDOM$RANDOM`). Then in a SECOND, separate Bash call (the transcript line only lands after the first call's result returns), run `grep -l "<nonce>" ~/.claude/projects/*/*.jsonl`. The single matching file's basename (minus `.jsonl`) is the session id. Fallback if the grep matches nothing: `ls -t ~/.claude/projects/*/*.jsonl | head -1`.
2. Immediately before `</body>`, insert a meta script and then the entire contents of `comment-layer.html` (in this skill's directory) verbatim:

   ```html
   <script>window.__EXPLAINER_META = { sessionId: "<session id>", repo: "<absolute path of the repo the report is about>", bridge: "http://127.0.0.1:8790" }</script>
   <!-- contents of comment-layer.html pasted here -->
   ```

3. Ensure the comment bridge is running (it answers comments by spawning `claude -p --resume`):

   ```bash
   curl -fsS --max-time 2 http://127.0.0.1:8790/health >/dev/null 2>&1 || \
     setsid nohup python3 ~/.claude/skills/explain-diff-html/bridge/bridge.py >> /tmp/explainer-bridge.log 2>&1 &
   ```

   Verify with a second health curl after a moment. If it still won't start, say so in your final message (the page degrades gracefully to an "offline" badge) — don't block on it.
4. Comment threads are stored next to the report at `<report>.comments.json`; mention that path in your final message.
5. Become the LIVE responder for the report (fastest answers — your context is warm; a spawned `claude -p` re-processes ~100k tokens per question). Write `<report>.responder.json` containing `{"sessionId": "<your session id>"}`, then start a persistent Monitor that polls `<report>.comments.json` every 2s and emits one JSON line `{threadId, msgId, question}` per NEW pending assistant message (prime the seen-set with existing pendings first). Message schema gotcha — when a reader posts a question, the thread gains TWO messages: the user's question (`role: "user"`, `status: "done"`) and an empty assistant placeholder (`role: "assistant"`, `status: "pending"`) awaiting the answer. The monitor MUST filter on `role == "assistant" && status == "pending"` — there are never pending user messages, so filtering on pending *user* messages silently matches nothing and the monitor never fires. `msgId` is the pending assistant message's id (it's what `/answers` fills in); `question` is the text of the nearest preceding user message in the same thread. When an event arrives: answer the question yourself (concise plain prose, inline markdown ok, no headings — re-check code if needed), then submit it via `curl -X POST http://127.0.0.1:8790/answers -H 'Content-Type: application/json' -d '{"report": ..., "msgId": ..., "text": ..., "note": "Answered live by the generating session."}'`. While your lease is valid the bridge leaves questions to you (rescuing any you leave pending >5 min); when your session ends, it automatically falls back to spawning `claude -p` forks — no cleanup needed, but mention the live/fallback distinction in your final message.
