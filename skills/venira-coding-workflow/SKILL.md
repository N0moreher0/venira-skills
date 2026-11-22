---
name: venira-coding-workflow
description: Standard workflow for any code change made through the Venira MCP project tools - orient, checkpoint, edit surgically, verify, roll back, report. Use this skill whenever the user asks to write, modify, refactor, fix, review, move or delete code or files in a workspace, or mentions Venira, snapshot, rollback, diff, "sửa code", "viết code", "thêm tính năng" or "fix bug", even if no tool is named.
---

# Venira coding workflow

Venira tools make edits auditable and reversible. Follow this loop so every change is small, checkpointed and verified, and a mistake costs one restore instead of an hour of cleanup.

Clients may prefix tool names (for example `mcp__venira__read_file`). The tool name (without the server prefix) is the stable name.

## Which tools you actually have

`tools/list` depends on `VENIRA_TOOL_MODE`: `core` (18 tools, for small models), `default` (31 tools, the full coding toolset) or `expert` (44 tools, adds PR/CI and the diagnostics kit). `VENIRA_JS_EXEC_MODE=off` hides `execute_js` in every mode. If a tool named below is not in your list, your mode leaves it out: do not call it, do not guess its arguments, use the fallback.

| Not in your list | Where it exists | Fallback |
|---|---|---|
| `explain_error`, `plan_read_batch` | `expert` only | Read the error text yourself; use `recent_files` and `search` to find files |
| `pr_*`, `ci_*` | `expert` only | Tell the user which mode they need (see venira-git-pr, venira-debug-ci) |
| `symbol_references`, `dependency_graph` | `default`, `expert` | `search` for the symbol name |
| `apply_patch`, `copy_path`, `diff_files`, `get_file_info` | `default`, `expert` | `edit_file` (`edits[]`), `read_file` plus `write_file`, `git action=diff`, `list_files` |
| `health`, `cache_clear`, `read_audit` | `default`, `expert` | Ask the user to run them, or skip |

## Ground rules

- Stay inside the workspace. Paths are workspace-relative; forward slashes work on Windows too. If the project lives in another folder, call `switch_workspace` with its absolute path (available in every mode). Under `trusted` or `off` it reaches any existing directory; under `strict` or `balanced` only the roots listed in `VENIRA_WORKSPACE`, and it is refused when that is unset.
- Read before you write. Never edit from memory of a file. Re-read when anything else may have touched it.
- Make the smallest change that solves the task. No drive-by reformatting or unrelated cleanups.
- Never put secrets in files, commands, chat or the memory note. Store tokens with `secret` (prefer `value_env`) and inject them with `secret_env` on `shell_run`.
- Delete, overwrite, move-over and destructive git operations only when the user asked, and only after a snapshot.
- Pass a short `reason` (max 400 characters) on mutating calls; it lands in the audit trail.
- If intent is ambiguous and the change is hard to undo, ask one short question. Otherwise proceed and state your assumptions in the report.

## 1. Orient

- `recent_files` (depth 2-3, limit 20-30) shows what moved lately and which files are in play.
- `memory` `action=read` right after it: if a handoff note exists, it is the previous AI's goal, decisions, files touched and next steps (see venira-memory). Keep its `version` for the final write. `exists=false` is normal on a first run.
- In an unfamiliar area, `plan_read_batch` (expert only) with a one-line task description returns a ready `read_file` call. Without it, `search` and `recent_files` do the same job by hand.
- Read several files in one `read_file` call with `requests[]` (max 8 per call). For big files use `outline_symbol` first, then `read_file` with `start_line`/`end_line` or `ranges[]`. Follow `next_start_line` when `truncated`.
- Never guess paths. Use `search` (`file_name`, `directory_name`, `literal_content`, `definition`) or `list_files`.
- Read project instructions if they exist (AGENTS.md, CONTRIBUTING.md, README) before the first edit.

## 2. Checkpoint

Create a snapshot (`snapshot`, `action=create`, narrow `paths`, label like `before <what>`) before edits that span several files, deletes, moves or overwrites of anything git does not hold, and large refactors. Skip it for a tiny single-file edit already covered by git. Check `truncated` and `skipped` in the result, and keep the snapshot id for the report and for any rollback (see §5).

## 3. Edit

| Need | Tool |
|---|---|
| One targeted change | `edit_file` with exact `old_text`, plus `expected_sha256`; use `edits[]` for several replacements in one file |
| Several files that must land together | `edit_file` with `edits[]` where each item carries its own `relative_path` (all-or-nothing, automatic rollback) |
| Change that arrives as a diff | `apply_patch`, `dry_run=true` first |
| New file | `write_file` `mode=create` (makes parent folders) |
| Replace a whole file | `write_file` `mode=overwrite` with `expected_sha256`, after a snapshot |
| New empty folder | `create` |
| Rename or move | `move_path` (not undoable, snapshot first) |
| Duplicate | `copy_path` |
| Delete | `delete_path` (`recursive=true` for folders), only on request, snapshot first |

Before changing a shared symbol, signature or file name, check `symbol_references` for its usages; `dependency_graph` shows the structure around it.

## 4. Verify

- Review the change with `git action=diff` (`include_patch=true`) or `diff_files`.
- Run the narrowest check first (type-check or one test), then the full suite once before finishing. `shell_run` runs in the background by default and returns a `run_id`: poll `shell_status` with `wait_seconds` until `running=false`. Use `background=false` for short commands whose output you need now. `ok=true` only means the call ran; read `command_status` and `exit_code`.
- Pick the shell explicitly when syntax matters. Windows PowerShell 5.1 has no `&&`: chain with `;`, or use `pwsh` or `bash`.
- On failure, read the stderr tail; in `expert` mode `explain_error` matches known signatures. Confirm the cause in the code, then fix. Do not retry blindly.
- Fix and re-verify until clean. If you cannot run a check, say so instead of implying it passed.

## 5. Roll back

`snapshot` `action=restore` with the id: first `dry_run=true` to preview, then `verify=true`. Use `paths` to restore only some files. Use `delete_extra=true` only when you really want files created after the snapshot removed. Restore beats hand-reverting because it is exact.

## Error recovery

| Signal | Meaning | Do this |
|---|---|---|
| `not_found` | Wrong path | `search` for the name. Do not guess. |
| `old_text_not_found` | File changed, or whitespace or line endings differ | Read `data.mismatch` and `data.context`, re-read that range, retry with exact text |
| `old_text_ambiguous` | Text matches several places | Widen `old_text` with surrounding lines. `replace_all=true` only if every match should change |
| `expected_sha256` refused | File changed since you read it | Re-read, re-apply the change. Never force it |
| `conflict` | Target already exists, or a `memory` write used a stale `if_version` | Choose another path, or snapshot then `overwrite` if intended; for `memory` re-read and merge |
| `batch_failed` | A multi-file `edit_file` or `apply_patch` rolled everything back (`rollback_succeeded`) | Fix the item or hunk named in the result, rerun the whole call |
| `approval_required` | A human must approve | Tell the user, give `data.approval.approve_command` or use `approval_wait_s`, retry once with `approval_id`. Do not work around it |
| `repeated_failure` | The identical command already failed | Read `data.previous.stderr_tail` and change the command. `retry_failed=true` only for flaky or environmental failures |
| `truncated: true` | Output was cut | Continue with `start_line=next_start_line`, or narrow `relative_path`, `limit` or `depth` |
| Odd or stale results | Cache out of sync after external changes | `cache_clear`, then `health` (sections `warnings`, `posture`) |

`ok:false` with `retryable:false` is final: follow the envelope's `hint` and `next_actions`. A `trimmed` flag or "Output mode compact" hint only means the payload was shortened. It is not an error.

## Final report

Before the report, write the handoff note: `memory` `action=write` with goal, decisions made, files touched, next steps (plain markdown, max 10000 bytes, replaces the previous note; pass `if_version` from your read). Skip it only for a trivial one-shot task with nothing worth handing off. No secrets in the note.

Keep the report short and factual: files changed, snapshot id (if any), checks run and their result, and anything left undone or assumed.
