---
name: venira-debug-ci
description: Diagnose and fix failing builds, tests, type errors, and CI runs using Venira tools (explain_error, ci_status, ci_logs, ci_wait, ci_control). Use this skill whenever the user reports a red build, failing test, CI failure, a stack trace or error message, "lỗi build", "CI fail", or asks why a pipeline or command broke, even if they only paste an error.
---

# Debug builds and CI with Venira

Find the root cause from evidence (logs, error text), fix it, and prove the fix. Retrying without reading the log wastes CI minutes and hides real problems.

## Which tools you have

`ci_status`, `ci_logs`, `ci_wait`, `ci_trigger`, `ci_control` and `explain_error` exist only when the server runs with `VENIRA_TOOL_MODE=expert` (they are not in `default` or `core`), and the CI tools also need a git-host credential (for GitHub, `github_connect` or `GITHUB_TOKEN`). If they are not in your tool list, do not improvise: debug locally from the command output (§1, §2, §3), ask the user to paste the failing job's log, and say that CI inspection needs expert mode.

## 1. Get the evidence

- Local failure: reproduce with `shell_run` (`background=false` for short commands, otherwise poll `shell_status`). Read `command_status` and `exit_code`, and capture the stderr tail.
- CI failure: `ci_status` with `pr`, `branch`, or `ref` to find the failing run (pass at most one of `run_id`/`ref`/`pr`/`branch`). Pass `run_id` to see its jobs, then `ci_logs` with the failing `job_id` (start with the default tail, widen `tail_lines` only if needed).

## 2. Classify the failure

In `expert` mode pass the error block to `explain_error` (`error_text` or `log_tail`). It matches known signatures (TypeScript, Python, git, npm, GitHub, Venira codes) offline and returns likely cause plus next actions. Without it, read the error yourself. Either way treat the diagnosis as a hypothesis and confirm it against the code:
- Locate the failing file and line with `search` and `read_file` (`ranges[]`).
- If the failure points at a changed symbol, check `symbol_references` for its usages (`default` and `expert` modes; in `core` use `search`).
- Separate three causes: a code bug, a flaky or environment problem (timeouts, network, cache), and a config or dependency drift. Each has a different fix.

## 3. Fix

Follow the venira-coding-workflow habits: snapshot if the fix is multi-file, edit surgically, then re-run the exact failing command locally. If `shell_run` answers `repeated_failure`, read `data.previous.stderr_tail` and change the approach instead of passing `retry_failed=true`.

## 4. Confirm on CI

- Push with `git action=push` (`set_upstream=true` the first time), then `ci_wait` on the branch or PR. One `ci_wait` call lasts at most `timeout_ms` (default 45s, max 110s); if `terminal=false`, call again with the same selector.
- Use `ci_control` (`action=retry_failed` or `cancel`, needs `run_id` and a `reason`) only for confirmed flaky jobs or when the user asked, and confirm the effect with `ci_status` since it is asynchronous. Bitbucket cannot retry.
- Use `ci_trigger` only when a workflow supports manual dispatch (GitHub `workflow_dispatch`) or no new commit is available.

## Report

State the root cause in one or two sentences, the fix, and the evidence that it works (local command result and CI overall status). If it was flaky or environmental, say so plainly rather than claiming a code fix. If CI could not be checked because the tools were missing, say that instead of implying it was green.
