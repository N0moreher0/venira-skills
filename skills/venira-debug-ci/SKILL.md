---
name: venira-debug-ci
description: Diagnose and fix failing builds, tests, type errors, and CI runs using Venira tools (explain_error, ci_status, ci_logs, ci_wait, ci_control). Use this skill whenever the user reports a red build, failing test, CI failure, a stack trace or error message, "lỗi build", "CI fail", or asks why a pipeline or command broke, even if they only paste an error.
---

# Debug builds and CI with Venira

Find the root cause from evidence (logs, error text), fix it, and prove the fix. Retrying without reading the log wastes CI minutes and hides real problems.

## 1. Get the evidence

- Local failure: reproduce with `shell_run` (`background=0` for short commands). Capture the stderr tail.
- CI failure: `ci_status` with `pr`, `branch`, or `ref` to find the failing run. Pass `run_id` to see its jobs, then `ci_logs` with the failing `job_id` (start with the default tail, widen `tail_lines` only if needed).

## 2. Classify the failure

Pass the error block to `explain_error`. It matches known signatures (TypeScript, Python, git, npm, GitHub) offline and returns likely cause plus next actions. Treat that as a hypothesis and confirm it against the code:
- Locate the failing file and line with `search` and `read_file` (ranges).
- If the failure points at a changed symbol, check `change_impact`.
- Separate three causes: a code bug, a flaky or environment problem (timeouts, network, cache), and a config or dependency drift. Each has a different fix.

## 3. Fix

Follow the venira-coding-workflow habits: snapshot if the fix is multi-file, edit surgically, then re-run the exact failing command locally. If `shell_run` answers `repeated_failure`, read `data.previous.stderr_tail` and change the approach instead of passing `retry_failed=1`.

## 4. Confirm on CI

- Push (via `shell_run`, e.g. `git push`), then `ci_wait` on the branch or PR. If `terminal=false`, call again with the same selector.
- Use `ci_control` with `retry_failed` only for confirmed flaky jobs, and always give a `reason`.
- Use `ci_trigger` only when a workflow supports manual dispatch or no new commit is available.

## Report

State the root cause in one or two sentences, the fix, and the evidence that it works (local command result and CI overall status). If it was flaky or environmental, say so plainly rather than claiming a code fix.
