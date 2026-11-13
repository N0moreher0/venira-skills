---
name: venira-git-pr
description: Git and pull-request workflow using Venira tools - inspect status, branch, commit, push, open a PR, watch CI, comment, and merge. Use this skill whenever the user wants to commit, create a branch, stash, open or update a pull request, check PR status, merge, or says "commit", "tạo PR", "push code", "merge", even if they do not mention Venira.
---

# Git and PR workflow with Venira

Make each step explicit and reversible. Merging and pushing change shared state, so do them only when the user asked.

## 1. Inspect

Call `project_git_status` (branch, ahead/behind, changed files) and `project_git_diff` to see exactly what would be committed. Use `project_git_log` for recent commit style so new messages match the repo.

## 2. Branch

- New work goes on a branch: `project_git_branch` action `create` (optionally `from`), then `switch`.
- Need to pause? `project_git_stash` push (add `include_untracked=1` when needed), then `apply` over `pop` so a copy is kept until you are sure.

## 3. Commit

- Stage and commit with `project_git_commit`, passing explicit `paths` so unrelated files stay out.
- Write an imperative subject line, matching the repo's convention from the log. Put the why in the body.
- Amend only when the user asks. Never use it to rewrite commits that were already pushed.

## 4. Push and open the PR

`project_git_commit` does not push. Push with `project_shell_run` (`git push -u origin <branch>`). Under the current policy: plain push is allowed without approval everywhere except `strict` (needs approval there); force pushes (`--force`, `+ref`, `--force-with-lease`), delete pushes, `--mirror`, and pushes to URLs need approval in `balanced` and `strict`, and run freely in `permissive` and `off`. If one asks for approval, tell the user instead of trying to dodge it.

Then `project_pr_create` with a one-line imperative title and a body holding a summary and a test plan. Use `draft=1` if the work is unfinished.

## 5. Watch CI and respond

- `project_ci_wait` with the `pr` selector. On failure, switch to the venira-debug-ci skill.
- Reply to reviewers with `project_pr_comment` (use `path` and `line` for inline notes).
- `project_pr_close` / `project_pr_reopen` for abandoned or mistakenly closed PRs.

## 6. Merge only on request

Merge with `project_pr_merge` only when the user asked and `project_ci_status` is green. Ask or infer the method (`merge`, `squash`, `rebase`) and whether to delete the branch. Report the resulting sha.
