---
name: venira-coding-workflow
description: Standard workflow for any code change made through the Venira MCP project tools - orient, checkpoint, edit surgically, verify, roll back, report. Use this skill whenever the user asks to write, modify, refactor, fix, review, move or delete code or files in a workspace, or mentions Venira, snapshot, rollback, diff, "sửa code", "viết code", "thêm tính năng" or "fix bug", even if no tool is named.
---

# Venira coding workflow

Venira tools make edits auditable and reversible. Follow this loop so every change is small, checkpointed and verified, and a mistake costs one restore instead of an hour of cleanup.

Clients may prefix tool names (for example `mcp__venira__read_file`). The tool name (without the server prefix) is the stable name.

## Ground rules

- Stay inside the workspace. Paths are workspace-relative; forward slashes work on Windows too.
- Read before you write. Never edit from memory of a file. Re-read when anything else may have touched it.
- Make the smallest change that solves the task. No drive-by reformatting or unrelated cleanups.
- Never put secrets in files, commands or chat. Store tokens with `secret` (prefer `value_env`) and inject them with `secret_env` on `shell_run`.
- Delete, overwrite, move-over and destructive git operations only when the user asked, and only after a snapshot.
- If intent is ambiguous and the change is hard to undo, ask one short question. Otherwise proceed and state your assumptions in the report.

## 1. Orient

- `memory` `action=read` (after `recent_files`): if a handoff note exists for this workspace, read it first — it is the previous AI's goal, decisions, files touched and next steps. `exists=false` is normal on a first run; start the task normally and leave a note before you finish.
- `recent_files` (depth 2-3, limit 20-30) shows what moved lately and which files are in play.
- In an unfamiliar area, `plan_read_batch` with a one-line task description, then run the `read_batch` it proposes (max 8 files per call).
- For big files use `outline_symbol` first, then `read_file` with `start_line`/`end_line` or `ranges`.
- Never guess paths. Use `search` (`file_name`, `literal_content`, `definition`) or `list_files`.
- Read project instructions if they exist (AGENTS.md, CONTRIBUTING.md, README) before the first edit.

## 2. Checkpoint

Create a snapshot (`snapshot`, `action=create`, narrow `paths`, label like `before <what>`) before edits that span several files, deletes, moves or overwrites of anything git does not hold, and large refactors. Skip it for a tiny single-file edit already covered by git. Check `truncated` and `skipped` in the result, and keep the snapshot id for the report and for any rollback (see §5).

## 3. Edit

| Need | Tool |
|---|---|
| One targeted change | `edit_file` with exact `old_text`, plus `expected_sha256`; use `edits[]` for several replacements in one file |
| Several files that must land together | `edit_batch` (all-or-nothing, automatic rollback) |
| Change that arrives as a diff | `apply_patch`, `dry_run=1` first |
| New file | `write_file` `mode=create`, `create_dirs=1` |
| Replace a whole file | `write_file` `mode=overwrite` with `expected_sha256`, after a snapshot |
| Rename or move | `move_path` (not undoable, snapshot first) |
| Duplicate | `copy_path` |
| Delete | `delete_path` (`recursive=1` for folders), only on request, snapshot first |

Before changing a shared symbol, signature or file name, run `change_impact` (pass `symbols` or `files`) to list dependents and the tests affected. Pass a short `reason` on mutating calls so the audit trail explains why.

## 4. Verify

- Review the change with `git_diff` (`include_patch=1`) or `diff_files`.
- Run the narrowest check first (type-check or one test), then the full suite once before finishing. Use `shell_run` with `background=0` for short commands. For long ones use `background=1`, then `shell_status` with `wait_seconds` until `running=false`.
- Pick the shell explicitly when syntax matters. Windows PowerShell 5.1 has no `&&`: chain with `;`, or use `pwsh` or `bash`.
- On failure, pass the stderr to `explain_error`, confirm the cause in the code, then fix. Do not retry blindly.
- Fix and re-verify until clean. If you cannot run a check, say so instead of implying it passed.

## 5. Roll back

`snapshot` `action=restore` with the id: first `dry_run=1` to preview, then `verify=1`. Use `paths` to restore only some files. Use `delete_extra=1` only when you really want files created after the snapshot removed. Restore beats hand-reverting because it is exact.

## Error recovery

| Signal | Meaning | Do this |
|---|---|---|
| `not_found` | Wrong path | `search` for the name. Do not guess. |
| `old_text_not_found` | File changed, or whitespace or line endings differ | Read `data.mismatch` and `data.context`, re-read that range, retry with exact text |
| `old_text_ambiguous` | Text matches several places | Widen `old_text` with surrounding lines. `replace_all=1` only if every match should change |
| `expected_sha256` refused | File changed since you read it | Re-read, re-apply the change. Never force it |
| `conflict` | Target already exists | Choose another path, or snapshot then `overwrite` if intended |
| `batch_failed` | Everything was rolled back (`rollback_succeeded`) | Fix the item named in `data.executed` and `data.skipped`, rerun the batch |
| `approval_required` | A human must approve | Tell the user, give `data.approval.approve_command` or use `approval_wait_ms`, retry once with `approval_id`. Do not work around it |
| `repeated_failure` | The identical command already failed | Read `data.previous.stderr_tail` and change the command. `retry_failed=1` only for flaky or environmental failures |
| `truncated: true` | Output was cut | Continue with `start_line=next_start_line`, or narrow `relative_path`, `limit` or `depth` |
| Odd or stale results | Cache out of sync after external changes | `cache_clear`, then `health` (sections `warnings`, `posture`) |

A `trimmed` flag or "Output mode compact" hint only means the payload was shortened. It is not an error.

## Final report

Before the report, `memory` `action=write` the handoff note: goal, decisions made, files touched, next steps (plain markdown, max 6000 bytes, replaces the previous note). Skip it only for a trivial one-shot task with nothing worth handing off. No secrets in the note.

Keep it short and factual: files changed, snapshot id (if any), checks run and their result, and anything left undone or assumed.
