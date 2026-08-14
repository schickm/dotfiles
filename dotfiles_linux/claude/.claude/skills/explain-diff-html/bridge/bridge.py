#!/usr/bin/env python3
"""Comment bridge for explain-diff-html explainers.

A tiny resident HTTP server (127.0.0.1 only) that receives reader comments
from generated explainer pages and answers them by forking the Claude Code
session that generated the report:

    first message in a thread:   claude -p --resume <generating-session> --fork-session
    follow-ups in the thread:    claude -p --resume <that thread's forked session>

so every comment pin is a real multi-turn conversation whose context includes
everything the generating session read and wrote.

Storage: one JSON file per report, next to the report itself:
    /tmp/2026-08-14-foo.html  ->  /tmp/2026-08-14-foo.html.comments.json

Endpoints (all JSON, permissive CORS because pages are served from file://):
    GET  /health
    GET  /threads?report=<abs path of the .html file>
    POST /comments   {report, repo, sessionId, anchor?, threadId?, question}

Run: python3 bridge.py   (idempotent-ish: refuses to start if port is taken)
"""

import glob
import json
import os
import re
import subprocess
import threading
import time
import urllib.parse
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = 8790
CLAUDE_TIMEOUT_S = 300
# Forking the generating session HANGS (until killed) while that session is
# still open/active — the CLI holds a session lock. Probe the fork briefly,
# then fall back to a fresh session that reads the report HTML for context.
FORK_PROBE_TIMEOUT_S = 60
MAX_CONCURRENT_CLAUDE = 2
ALLOWED_TOOLS = "Read,Grep,Glob"

_store_lock = threading.Lock()          # guards all comment-file reads/writes
_thread_locks: dict = {}                # per-thread serialization for resume chaining
_thread_locks_guard = threading.Lock()
_claude_slots = threading.Semaphore(MAX_CONCURRENT_CLAUDE)
_inflight = set()                       # pending msg ids a spawned worker owns
_known_reports = set()                  # reports seen this process; babysitter scans these

# A generating session can register itself as the LIVE responder for a report by
# writing `<report>.responder.json` = {"sessionId": "..."}. While that session is
# alive, the bridge leaves new questions pending for it to answer (via POST
# /answers) instead of spawning claude -p — warm cache, no spawn, much faster.
# The babysitter rescues questions the live responder abandons.
RESCUE_AFTER_S = 300


def _lease_sid(report: str):
    try:
        with open(report + ".responder.json") as f:
            return json.load(f).get("sessionId")
    except (OSError, json.JSONDecodeError):
        return None


def _live_responder(report: str) -> bool:
    sid = _lease_sid(report)
    return bool(sid) and _session_info(sid).get("active", False)


def _session_info(sid: str) -> dict:
    """Whether the Claude Code session `sid` is currently open, plus its kind
    ("interactive"/"bg") and status ("idle"/"busy"). ~/.claude/sessions/<pid>.json
    registers open sessions, but stale entries linger after crashes — so confirm
    the pid is alive AND its /proc start-time matches the registered procStart
    (guards pid reuse). Observed empirically: forking an open bg/busy session
    HANGS on its lock, while an open idle interactive session forks fine."""
    for path in glob.glob(os.path.expanduser("~/.claude/sessions/*.json")):
        try:
            with open(path) as f:
                d = json.load(f)
        except (OSError, json.JSONDecodeError):
            continue
        if d.get("sessionId") != sid:
            continue
        pid = d.get("pid")
        if not isinstance(pid, int):
            continue
        try:
            with open(f"/proc/{pid}/stat") as f:
                starttime = f.read().rsplit(")", 1)[1].split()[19]
        except (OSError, IndexError):
            continue  # pid gone
        proc_start = str(d.get("procStart") or "")
        if proc_start and starttime != proc_start:
            continue  # pid reused by an unrelated process
        return {"active": True, "kind": d.get("kind"), "status": d.get("status")}
    return {"active": False}


def _comments_path(report: str) -> str:
    return report + ".comments.json"


def _valid_report(report: str) -> bool:
    # Only absolute paths to existing .html files; the page sends its own
    # location.pathname, so anything else is malformed or hostile.
    return bool(report) and os.path.isabs(report) and report.endswith(".html") and os.path.isfile(report)


def _load(report: str) -> dict:
    try:
        with open(_comments_path(report)) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {"threads": []}


def _save(report: str, data: dict) -> None:
    path = _comments_path(report)
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f, indent=1)
    os.replace(tmp, path)


def _thread_lock(thread_id: str) -> threading.Lock:
    with _thread_locks_guard:
        return _thread_locks.setdefault(thread_id, threading.Lock())


def _find_thread(data: dict, thread_id: str):
    return next((t for t in data["threads"] if t["id"] == thread_id), None)


def _first_prompt(report: str, repo: str, anchor: dict, question: str) -> str:
    section = anchor.get("sectionId") or "(top of page)"
    excerpt = anchor.get("excerpt") or ""
    return (
        f"A reader of the HTML explainer you generated ({report}) has anchored a comment "
        f'to a passage in the section "{section}":\n\n'
        f"> {excerpt}\n\n"
        f"Their question:\n{question}\n\n"
        f"Answer the question directly and concisely in plain prose (inline markdown like "
        f"`code` and **bold** is fine; no headings). You have read-only access to the "
        f"repository at {repo} — re-check the code there if it helps. Aim for under 250 "
        f"words unless the question genuinely needs more. Your entire output is shown to "
        f"the reader as the comment-thread reply, so do not narrate what you are doing."
    )


def _followup_prompt(question: str) -> str:
    return (
        f"The reader replied in the same comment thread:\n{question}\n\n"
        f"Answer directly and concisely, same rules as before: plain prose, no headings, "
        f"entire output is the thread reply."
    )


def _fresh_prefix(report: str) -> str:
    return (
        f"You are answering a reader comment on an HTML explainer report at {report}. "
        f"Read that file FIRST — it contains the full explanation (and code walkthrough) "
        f"the comment is about.\n\n"
    )


def _run_claude(prompt: str, resume_sid, fork: bool, repo: str, timeout: int, add_dir: str = ""):
    """Returns (answer_text, new_session_id) or raises. resume_sid None = fresh session."""
    # The positional prompt must come FIRST: --allowedTools and --add-dir are
    # variadic (<tools...>) and would silently swallow a trailing prompt.
    cmd = ["claude", "-p", prompt, "--output-format", "json", "--allowedTools", ALLOWED_TOOLS]
    if resume_sid:
        cmd += ["--resume", resume_sid]
    if fork:
        cmd += ["--fork-session"]
    if add_dir:
        cmd += ["--add-dir", add_dir]
    proc = subprocess.run(
        cmd,
        cwd=repo if os.path.isdir(repo) else None,
        capture_output=True, text=True, timeout=timeout,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"claude exited {proc.returncode}: {proc.stderr.strip()[:500]}")
    out = json.loads(proc.stdout)
    answer = out.get("result") or "(empty reply)"
    return answer, out.get("session_id") or resume_sid


def _answer_worker(report: str, repo: str, gen_sid: str, thread_id: str, msg_id: str, question: str):
    try:
        _answer_worker_inner(report, repo, gen_sid, thread_id, msg_id, question)
    finally:
        _inflight.discard(msg_id)


def _answer_worker_inner(report: str, repo: str, gen_sid: str, thread_id: str, msg_id: str, question: str):
    with _thread_lock(thread_id), _claude_slots:
        with _store_lock:
            data = _load(report)
            thread = _find_thread(data, thread_id)
            if not thread:
                return
            resume_sid = thread.get("resumeSid")
            anchor = thread.get("anchor") or {}
        note = ""
        try:
            if resume_sid:
                answer, new_sid = _run_claude(
                    _followup_prompt(question), resume_sid, False, repo, CLAUDE_TIMEOUT_S)
            else:
                first = _first_prompt(report, repo, anchor, question)
                try:
                    answer, new_sid = _run_claude(first, gen_sid, True, repo, FORK_PROBE_TIMEOUT_S)
                except subprocess.TimeoutExpired:
                    # Generating session is still open (its lock makes the fork
                    # hang). Fresh session instead; the report itself carries
                    # the context, so have it read the file before answering.
                    # Surfaced to the reader via `note` — never silent.
                    answer, new_sid = _run_claude(
                        _fresh_prefix(report) + first, None, False, repo,
                        CLAUDE_TIMEOUT_S, add_dir=os.path.dirname(report))
                    note = (
                        "The Claude session that generated this report is still open, so its "
                        "memory is locked — this was answered by a fresh Claude that read the "
                        "report and the code instead. Close the generating session to get "
                        "full-context answers from its fork."
                    )
            status, text = "done", answer
        except Exception as e:  # timeout, bad json, nonzero exit — all shown to the reader
            status, text, new_sid = "error", f"Bridge error: {e}", resume_sid
        with _store_lock:
            data = _load(report)
            thread = _find_thread(data, thread_id)
            if not thread:
                return
            if new_sid and status == "done":
                thread["resumeSid"] = new_sid
            for m in thread["messages"]:
                if m["id"] == msg_id:
                    m.update(text=text, status=status)
                    if note:
                        m["note"] = note
                    break
            _save(report, data)


class Handler(BaseHTTPRequestHandler):
    def _send(self, code: int, body: dict):
        payload = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_OPTIONS(self):
        self._send(204, {})

    def do_GET(self):
        url = urllib.parse.urlparse(self.path)
        if url.path == "/health":
            return self._send(200, {"ok": True, "pid": os.getpid()})
        if url.path == "/session-status":
            q = urllib.parse.parse_qs(url.query)
            sid = q.get("sid", [""])[0]
            if not re.fullmatch(r"[0-9a-f-]{36}", sid):
                return self._send(400, {"error": "bad session id"})
            info = _session_info(sid)
            report = q.get("report", [""])[0]
            if report and _valid_report(report):
                info["live"] = _live_responder(report)
            return self._send(200, info)
        if url.path == "/threads":
            report = urllib.parse.parse_qs(url.query).get("report", [""])[0]
            if not _valid_report(report):
                return self._send(400, {"error": "bad report path"})
            _known_reports.add(report)
            with _store_lock:
                return self._send(200, _load(report))
        return self._send(404, {"error": "not found"})

    def do_POST(self):
        path = urllib.parse.urlparse(self.path).path
        try:
            body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))))
        except (ValueError, json.JSONDecodeError):
            return self._send(400, {"error": "bad json"})
        if path == "/answers":
            return self._post_answer(body)
        if path != "/comments":
            return self._send(404, {"error": "not found"})

        report = body.get("report", "")
        repo = body.get("repo", "")
        gen_sid = body.get("sessionId", "")
        question = (body.get("question") or "").strip()
        if not _valid_report(report):
            return self._send(400, {"error": "bad report path"})
        if not question:
            return self._send(400, {"error": "empty question"})
        if not re.fullmatch(r"[0-9a-f-]{36}", gen_sid or ""):
            return self._send(400, {"error": "bad session id"})

        now = time.time()
        user_msg = {"id": f"m-{uuid.uuid4().hex[:8]}", "role": "user", "text": question, "ts": now, "status": "done"}
        pending = {"id": f"m-{uuid.uuid4().hex[:8]}", "role": "assistant", "text": "", "ts": now, "status": "pending"}

        with _store_lock:
            data = _load(report)
            thread_id = body.get("threadId")
            thread = _find_thread(data, thread_id) if thread_id else None
            if not thread:
                thread = {
                    "id": f"t-{uuid.uuid4().hex[:8]}",
                    "anchor": body.get("anchor") or {},
                    "resumeSid": None,
                    "messages": [],
                }
                data["threads"].append(thread)
            # Persisted so the babysitter can respawn a worker without the
            # original request in hand.
            thread["repo"] = repo
            thread["genSid"] = gen_sid
            thread["messages"] += [user_msg, pending]
            _save(report, data)
            thread_id = thread["id"]
        _known_reports.add(report)

        if _live_responder(report):
            # A live session is watching this report — leave the question
            # pending for it. The babysitter rescues if it never answers.
            return self._send(200, {"threadId": thread_id, "pendingId": pending["id"], "live": True})

        _inflight.add(pending["id"])
        threading.Thread(
            target=_answer_worker,
            args=(report, repo, gen_sid, thread_id, pending["id"], question),
            daemon=True,
        ).start()
        return self._send(200, {"threadId": thread_id, "pendingId": pending["id"]})

    def _post_answer(self, body: dict):
        """Live responder writes an answer: {report, msgId, text, note?}.
        Goes through the store lock so it can't race the babysitter."""
        report = body.get("report", "")
        msg_id = body.get("msgId", "")
        text = (body.get("text") or "").strip()
        if not _valid_report(report) or not msg_id or not text:
            return self._send(400, {"error": "need report, msgId, text"})
        if msg_id in _inflight:
            return self._send(409, {"error": "a spawned worker already owns this message"})
        with _store_lock:
            data = _load(report)
            for thread in data["threads"]:
                for m in thread["messages"]:
                    if m["id"] == msg_id:
                        if m["status"] != "pending":
                            return self._send(409, {"error": f"message is {m['status']}, not pending"})
                        m.update(text=text, status="done")
                        if body.get("note"):
                            m["note"] = body["note"]
                        _save(report, data)
                        return self._send(200, {"ok": True})
        return self._send(404, {"error": "message not found"})

    def log_message(self, fmt, *args):  # quiet: health polls would spam the log
        pass


def _babysitter():
    """Rescue questions left pending too long (live responder died or stalled)
    by spawning the normal claude worker for them."""
    while True:
        time.sleep(60)
        for report in list(_known_reports):
            try:
                with _store_lock:
                    data = _load(report)
                stale = []
                for thread in data["threads"]:
                    msgs = thread["messages"]
                    for i, m in enumerate(msgs):
                        if (m["role"] == "assistant" and m["status"] == "pending"
                                and m["id"] not in _inflight
                                and time.time() - m["ts"] > RESCUE_AFTER_S):
                            question = msgs[i - 1]["text"] if i else ""
                            stale.append((thread, m, question))
                for thread, m, question in stale:
                    if not thread.get("repo") or not thread.get("genSid"):
                        continue
                    _inflight.add(m["id"])
                    threading.Thread(
                        target=_answer_worker,
                        args=(report, thread["repo"], thread["genSid"], thread["id"], m["id"], question),
                        daemon=True,
                    ).start()
            except Exception:
                pass  # never let the babysitter die


if __name__ == "__main__":
    threading.Thread(target=_babysitter, daemon=True).start()
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"explainer comment bridge listening on 127.0.0.1:{PORT}", flush=True)
    server.serve_forever()
