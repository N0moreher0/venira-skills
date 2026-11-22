---
name: venira-git-pr
description: Git and pull-request workflow using Venira tools - inspect status, branch, commit, push, open a PR, watch CI, comment, and merge. Use this skill whenever the user wants to commit, create a branch, stash, open or update a pull request, check PR status, merge, or says "commit", "tạo PR", "push code", "merge", even if they do not mention Venira.
---

# Git and PR workflow with Venira

Make each step explicit and reversible. Merging and pushing change shared state, so do them only when the user asked.

## Which tools you have

`git` (status, diff, log, branch, commit, stash, push) is available in every tool mode, `core` included. The PR and CI tools (`pr_create`, `pr_list`, `pr_comment`, `pr_merge`, `pr_close`, `pr_reopen`, `ci_status`, `ci_wait`) exist only with `VENIRA_TOOL_MODE=expert`, and they need a git-host credential (for GitHub, `github_connect` or `GITHUB_TOKEN`). If they are not in your tool list, do steps 1-4 with `git`, then tell the user the PR must be opened with expert mode or by hand, and hand over a one-line title and a body (summary and test plan) they can paste. Do not shell out to another CLI to get around it.

## 1. Inspect

Call `git action=status` (branch, ahead/behind, changed files) and `git action=diff` to see exactly what would be committed. Use `git action=log` for recent commit style so new messages match the repo.

## 2. Branch

- New work goes on a branch: `git action=branch sub=create` (optionally `from`), then `sub=switch`.
- Need to pause? `git action=stash sub=push` (add `include_untracked=true` when needed), then `sub=apply` over `sub=pop` so a copy is kept until you are sure.

## 3. Commit

- Stage and commit with `git action=commit`, passing explicit `paths` so unrelated files stay out. With no `paths` it commits what is already staged.
- Write an imperative subject line, matching the repo's convention from the log (conventional commits where the repo uses them). Put the why in the body.
- Amend only when the user asks. Never use it to rewrite commits that were already pushed.

## 4. Push and open the PR

`git action=commit` does not push. Push with `git action=push`: one local branch (`ref`, default the current one) to a configured remote name (`remote`, default its own remote or `origin`), `set_upstream=true` the first time, `dry_run=true` to preview. It never forces, deletes or takes a URL, and it is refused under the `strict` profile. A rejected push (`conflict`) means the remote moved: integrate first, never force. Missing credentials come back as `invalid_request`.

Anything else goes through `shell_run` (`git push ...`) under the shell policy: plain push is allowed without approval everywhere except `strict` (needs approval there); force pushes (`--force`, `+ref`, `--force-with-lease`), delete pushes, `--mirror`, and pushes to URLs need approval in `balanced` and `strict`, and run freely in `permissive` and `off`. If one asks for approval, tell the user instead of trying to dodge it.

Then `pr_create` (expert mode) with a one-line imperative title and a body holding a summary and a test plan. `head` defaults to the current branch and `base` to the repo default. Use `draft=true` if the work is unfinished. If a PR already exists for the branch, use `pr_comment` instead.

## 5. Watch CI and respond

- `ci_wait` with the `pr` selector. If `terminal=false`, call again with the same selector. On failure, switch to the venira-debug-ci skill.
- Reply to reviewers with `pr_comment` (use `path` and `line` for inline notes).
- `pr_list` finds a PR number. `pr_close` / `pr_reopen` for abandoned or mistakenly closed PRs (Bitbucket cannot reopen).

## 6. Merge only on request

Merge with `pr_merge` only when the user asked and `ci_status` is green. Ask or infer the method (`merge`, `squash`, `rebase`) and whether to delete the head branch. It refuses closed or conflicting PRs. Report the resulting sha.
