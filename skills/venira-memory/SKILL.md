---
name: venira-memory
description: Use the `memory` tool well - read the workspace handoff note at the start of a task, write it before you finish or run out of context. Use this skill whenever a task spans more than one chat turn, the user mentions handoff, memory, note, context, "hết context", resuming previous work, or asks the agent to remember where things stand, even if the `memory` tool is never named.
---

# Venira memory handoff

`memory` is one markdown file per workspace that outlives the chat window. The AI that is about to run out of context overwrites it; the next AI reads it first and picks up where the previous one stopped. It is plain text on disk at `<workspace>/.venira/memory.md` — a human can open or edit it too. One note per workspace, always replaced wholesale, never appended. (Notes written before v4.4.0 live in the data dir and are still read as a fallback; the next write moves them into `<workspace>/.venira/memory.md`.) Add `.venira/` to `.gitignore` if you do not want the note committed.

Clients may prefix tool names (for example `mcp__venira__memory`). The tool name (without the server prefix) is the stable name.

## When to use

- **Start of a task, or a resumed one:** `memory` `action=read` after `recent_files`. Treat the note as the previous owner's briefing — verify it against reality before trusting it (files may have changed since).
- **Before you finish, or when context is running low:** `memory` `action=write`. Cheaper than a perfect summary nobody reads at the start: the next session reads it first.
- **Skip it only for:** a trivial one-shot task with nothing worth handing off, or when the user says not to.

## Rules

- **`action=read` first, always.** `exists=false` is normal on a first run (you get a hint), start the task normally.
- **Write = full overwrite.** `content` replaces the whole note; nothing is appended. Empty or missing `content` is refused and the old note is kept.
- **Cap is 6000 bytes** (UTF-8). Over the cap → `invalid_request`, old note kept. Write tight; cut stale lines rather than cramming.
- **No secrets, ever.** No API keys, tokens, passwords, connection strings, personal data. The note is unencrypted plain text on disk.
- **Not for lasting docs or history.** Use `write_file` for docs that belong in the repo, `git_log`/`read_audit` for "what happened". The note is a *handoff scratchpad*, not a file with a future.
- **No appendix bloat.** A stale block still costs every future session 6000-token-adjacent overhead; rewrite honestly each time.

## What goes in the note

Plain markdown, in this order, cut whatever does not fit:

1. **Goal** — one sentence: what the user wants done and by when/why.
2. **State** — what is done, what is verified vs unverified, what exactly was tried and failed.
3. **Decisions** — choices made and the reason (so the next session does not re-litigate them), including rejected alternatives when it matters.
4. **Files** — paths touched or to touch, and for each what changed/will change (one line each).
5. **Next steps** — the exact next action, in order. Not "continue work" — name the file, the failing test, the command to rerun.
6. **Gotchas** — workarounds, quirks, constraints (e.g. "build takes 750s", "test X is pre-existing red").

## Workflow

1. Read: `memory` `action=read` → if `exists=true`, skim, then cross-check with `recent_files` / `git_status` before acting on it.
2. Work normally; update nothing mid-task.
3. Before the final report (or when you notice context filling): `memory` `action=write` with the six sections. If there is nothing to hand off, skip the write.
4. The final chat report stays short and factual — the note carries the detail, the chat does not need to repeat it.

## Examples

Good note (compact, actionable):

```markdown
# Goal
Fix `database is locked` in Venira desktop app (user: "cứu phát bro").

# State
- Fixed test tolerance on Rust guardian marker (windows.rs:816) — pass.
- Python `_LockedConnection` now retries locked errors w/ backoff+jitter.
- `save_chat_session` uses BEGIN IMMEDIATE. Tests: locked regression 4/4 pass.
- Root cause NOT fully proven: suspect double app instance (UAC elevations).

# Decisions
- Retry, not longer timeout: 30s busy_timeout already insufficient.
- Did NOT touch node MCP audit-store beyond busy_timeout — separate DB file.

# Files
- venira/db.py — retry + BEGIN IMMEDIATE (snap-20261114-202452-7e238e)
- venira_rust/src/bin/windows.rs:816 — assert with epsilon

# Next steps
1. Have user rerun start.ps1; watch venira.log for `database is locked`.
2. If it recurs: `handle64.exe G:\Venira\data\venira.db` during failure.

# Gotchas
- 3 failing tests in test_agent_in_chat_bridge/test_chat_attachments are pre-existing; not related.
```

Bad note: "worked on the bug, DB fixed, some tests fail, continue later" — useless. Every section must let the next session act without rereading the whole chat.

## Troubleshooting

| Signal | Meaning | Do this |
|---|---|---|
| `exists=false` | No note yet | Normal. Start the task, write one at the end |
| `invalid_request` + "over the 6000 byte cap" | Note too long | Cut stale/verbose sections, rewrite shorter |
| `invalid_request` + "empty content" | Missing or blank `content` | Write the full note, not an empty placeholder |
| `invalid_request` + "action must be" | Unknown action | Use `read` or `write` |
| Note stale vs reality | Files changed since write | Trust the code, not the note; update the note next write |
